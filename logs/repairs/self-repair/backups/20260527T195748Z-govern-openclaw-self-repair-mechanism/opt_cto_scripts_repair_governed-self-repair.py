#!/usr/bin/env python3
"""Governed self-repair records for OpenClaw/CTO direct edits.

This does not grant new write power. It wraps the existing temporary repair-mode
exception with a required manifest, rollback snapshot, and closeout verification
record so direct edits are auditable and reversible.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

DEFAULT_ALLOWED_PREFIXES = [
    "/usr/lib/node_modules/openclaw",
    "/home/cto/.openclaw",
    "/opt/cto",
]
RECORD_DIR = "logs/repairs/self-repair"
SECRET_PATTERNS = [
    re.compile(r"(?i)(api[_-]?key|token|secret|password|private[_-]?key)\s*[:=]\s*[^\s]+"),
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
]


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-zA-Z0-9_.-]+", "-", value.strip().lower()).strip("-._")
    return slug[:80] or "self-repair"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def contains_secret_shape(text: str) -> bool:
    return any(pattern.search(text) for pattern in SECRET_PATTERNS)


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text())
    except Exception as exc:  # noqa: BLE001 - CLI error surface
        raise SystemExit(f"FAIL: cannot read JSON {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise SystemExit("FAIL: manifest must be a JSON object")
    return data


def as_nonempty_string(data: dict[str, Any], key: str) -> str:
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        raise SystemExit(f"FAIL: manifest.{key} must be a non-empty string")
    if contains_secret_shape(value):
        raise SystemExit(f"FAIL: manifest.{key} appears to contain a secret-shaped value")
    return value.strip()


def as_string_list(data: dict[str, Any], key: str) -> list[str]:
    value = data.get(key)
    if not isinstance(value, list) or not value or not all(isinstance(item, str) and item.strip() for item in value):
        raise SystemExit(f"FAIL: manifest.{key} must be a non-empty list of strings")
    items = [item.strip() for item in value]
    if any(contains_secret_shape(item) for item in items):
        raise SystemExit(f"FAIL: manifest.{key} appears to contain a secret-shaped value")
    return items


def canonical(path: str, root: Path) -> Path:
    p = Path(path).expanduser()
    if not p.is_absolute():
        p = root / p
    return p.resolve(strict=False)


def is_allowed(path: Path, prefixes: list[str]) -> bool:
    p = str(path)
    return any(p == prefix or p.startswith(prefix.rstrip("/") + "/") for prefix in prefixes)


def validate_manifest(data: dict[str, Any], root: Path, prefixes: list[str]) -> dict[str, Any]:
    title = as_nonempty_string(data, "title")
    reason = as_nonempty_string(data, "reason")
    rollback_plan = as_nonempty_string(data, "rollback_plan")
    paths_raw = as_string_list(data, "paths")
    verification = as_string_list(data, "verification")
    owner = str(data.get("owner", "openclaw")).strip() or "openclaw"
    if owner not in {"openclaw", "hermes", "john"}:
        raise SystemExit("FAIL: manifest.owner must be openclaw, hermes, or john")
    paths = [canonical(path, root) for path in paths_raw]
    denied = [str(path) for path in paths if not is_allowed(path, prefixes)]
    if denied:
        raise SystemExit("FAIL: manifest paths outside allowed repair scope: " + ", ".join(denied))
    return {
        "title": title,
        "reason": reason,
        "rollback_plan": rollback_plan,
        "paths": [str(path) for path in paths],
        "verification": verification,
        "owner": owner,
    }


def backup_paths(paths: list[str], root: Path, record_id: str) -> list[dict[str, Any]]:
    backup_root = root / RECORD_DIR / "backups" / record_id
    backups: list[dict[str, Any]] = []
    for raw in paths:
        path = Path(raw)
        item: dict[str, Any] = {"path": raw, "exists": path.exists()}
        if path.exists() and path.is_file() and not path.is_symlink():
            digest = sha256_file(path)
            item["sha256_before"] = digest
            rel_name = re.sub(r"[^a-zA-Z0-9_.-]+", "_", raw.strip("/"))
            dest = backup_root / rel_name
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, dest)
            item["backup"] = str(dest.relative_to(root)) if str(dest).startswith(str(root)) else str(dest)
        elif path.exists() and path.is_dir():
            item["directory"] = True
        backups.append(item)
    return backups


def git_status(root: Path) -> str:
    try:
        return subprocess.check_output(
            ["git", "status", "--short"], cwd=root, text=True, stderr=subprocess.STDOUT, timeout=20
        ).strip()
    except Exception as exc:  # noqa: BLE001
        return f"git status unavailable: {exc}"


def cmd_begin(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    prefixes = [str(canonical(p, root)) for p in (args.allow_prefix or DEFAULT_ALLOWED_PREFIXES)]
    manifest = validate_manifest(load_json(Path(args.manifest)), root, prefixes)
    record_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + slugify(manifest["title"])
    record = {
        "id": record_id,
        "state": "open",
        "opened_at": utc_now(),
        "scope": "openclaw-governed-self-repair",
        "allowed_prefixes": prefixes,
        "manifest": manifest,
        "backups": backup_paths(manifest["paths"], root, record_id),
        "git_status_before": git_status(root),
    }
    out = root / RECORD_DIR / f"{record_id}.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n")
    print(out)
    return 0


def cmd_close(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    record_path = Path(args.record)
    if not record_path.is_absolute():
        record_path = root / record_path
    record = load_json(record_path)
    if record.get("state") != "open":
        raise SystemExit("FAIL: only open records can be closed")
    verifications = args.verification or []
    if not verifications:
        raise SystemExit("FAIL: at least one --verification result is required to close")
    if any(contains_secret_shape(item) for item in verifications):
        raise SystemExit("FAIL: verification text appears to contain a secret-shaped value")
    record["state"] = "closed"
    record["closed_at"] = utc_now()
    record["verification_results"] = verifications
    record["git_status_after"] = git_status(root)
    record["close_notes"] = args.notes or ""
    record_path.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n")
    print(record_path)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default="/opt/cto")
    sub = parser.add_subparsers(dest="command", required=True)
    begin = sub.add_parser("begin", help="open a governed repair record and capture rollback backups")
    begin.add_argument("--manifest", required=True)
    begin.add_argument("--allow-prefix", action="append", help="additional/override allowed prefix; repeatable")
    begin.set_defaults(func=cmd_begin)
    close = sub.add_parser("close", help="close a governed repair record after verification")
    close.add_argument("--record", required=True)
    close.add_argument("--verification", action="append", required=True)
    close.add_argument("--notes", default="")
    close.set_defaults(func=cmd_close)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
