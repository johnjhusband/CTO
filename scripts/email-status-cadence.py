#!/usr/bin/env python3
"""Guarded cadence runner for CTO status email.

This script intentionally does not send unless --send is supplied. It is safe for
cron/systemd dry-runs and for work-pump verification because it reports
credential *names/status* only and delegates actual delivery to
scripts/send-status-email.py.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_STATE_PATH = ROOT / ".cache" / "email-status-cadence.json"
DEFAULT_DIGEST_DIR = ROOT / "logs" / "digest"
SEND_STATUS_PATH = ROOT / "scripts" / "send-status-email.py"


class CadenceBlocked(RuntimeError):
    """Expected non-secret blocker such as missing digest or credentials."""


def load_send_status_module():
    spec = importlib.util.spec_from_file_location("send_status_email", SEND_STATUS_PATH)
    module = importlib.util.module_from_spec(spec)
    if spec.loader is None:
        raise RuntimeError("unable to load send-status-email.py")
    spec.loader.exec_module(module)
    return module


def load_env_file(path: Path) -> None:
    """Load simple KEY=VALUE env files without printing values."""
    if not path.exists():
        return
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if not key or key in os.environ:
            continue
        value = value.strip()
        if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
            value = value[1:-1]
        os.environ[key] = value


def latest_digest(digest_dir: Path) -> Path:
    files = sorted(digest_dir.glob("digest-*.md"))
    if not files:
        raise CadenceBlocked(f"missing_digest: no digest-*.md files under {digest_dir}")
    return files[-1]


def digest_date_from_path(path: Path) -> str:
    stem = path.stem
    if stem.startswith("digest-"):
        return stem.removeprefix("digest-")
    return datetime.now(timezone.utc).date().isoformat()


def read_state(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError:
        return {}
    return data if isinstance(data, dict) else {}


def write_state(path: Path, state: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n")
    path.chmod(0o600)


def ensure_credentials(send_status) -> str:
    provider = send_status.configured_provider()
    try:
        send_status.check_credentials()
    except Exception as exc:  # noqa: BLE001 - normalize to non-secret blocker
        message = str(exc)
        # send-status-email.py reports missing credential names only; keep only the
        # error class/prefix here to avoid accidentally propagating provider text.
        if "CTO_EMAIL_API_KEY" in message:
            raise CadenceBlocked("missing_credentials: CTO_EMAIL_API_KEY") from exc
        if "CTO_EMAIL_SMTP" in message or "missing email credentials" in message:
            raise CadenceBlocked("missing_credentials: CTO_EMAIL_SMTP_HOST/USER/PASSWORD or CTO_EMAIL_API_KEY") from exc
        raise CadenceBlocked(f"credential_check_failed: provider={provider}") from exc
    return provider


def run(args: argparse.Namespace) -> int:
    if args.env_file:
        load_env_file(Path(args.env_file))

    send_status = load_send_status_module()
    digest = latest_digest(Path(args.digest_dir))
    digest_date = digest_date_from_path(digest)
    state_path = Path(args.state_path)
    state = read_state(state_path)

    if state.get("last_sent_digest") == digest.name and not args.force:
        print(f"already_sent digest={digest.name} last_sent_utc={state.get('last_sent_utc', 'unknown')}")
        return 0

    if args.dry_run and not args.check_credentials:
        print(f"dry_run would_send digest={digest.name} to={os.environ.get('CTO_EMAIL_TO', send_status.DEFAULT_TO)}")
        return 0

    provider = ensure_credentials(send_status)
    if not args.send:
        print(f"ready provider={provider} digest={digest.name}; no message sent (pass --send to deliver)")
        return 0

    body = digest.read_text()
    if not body.strip():
        raise CadenceBlocked(f"empty_digest: {digest.name}")
    subject = args.subject or f"CTO daily status — {digest_date}"
    msg = send_status.build_message(subject, body)
    send_status.send_message(msg)
    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    write_state(
        state_path,
        {
            "last_sent_digest": digest.name,
            "last_sent_digest_date": digest_date,
            "last_sent_utc": now,
            "last_provider": provider,
        },
    )
    print(f"sent digest={digest.name} provider={provider} state={state_path}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Send latest CTO digest once per digest via guarded email cadence")
    parser.add_argument("--digest-dir", default=str(DEFAULT_DIGEST_DIR))
    parser.add_argument("--state-path", default=str(DEFAULT_STATE_PATH))
    parser.add_argument("--env-file", default=str(ROOT / ".env"), help="Optional env file to load; values are never printed")
    parser.add_argument("--subject", default=None)
    parser.add_argument("--dry-run", action="store_true", help="Do not check credentials or send; only report planned digest")
    parser.add_argument("--check-credentials", action="store_true", help="Check configured provider without sending")
    parser.add_argument("--send", action="store_true", help="Actually send the latest unsent digest")
    parser.add_argument("--force", action="store_true", help="Ignore duplicate-send state")
    args = parser.parse_args()
    try:
        return run(args)
    except CadenceBlocked as exc:
        print(f"blocked {exc}")
        return 75


if __name__ == "__main__":
    raise SystemExit(main())
