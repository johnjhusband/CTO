#!/usr/bin/env python3
"""Verify an OpenClaw upgrade on a clone-test host without mutating production.

This is the clone-side companion to openclaw-upgrade-candidate.sh and
openclaw-upgrade-promotion-check.py. It is safe to run on production too: it
only reads the installed OpenClaw version, runs `openclaw help`, and emits a
sanitized JSON verdict. It does not install packages, restart services, touch
cloud resources, or print secrets.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CANDIDATE_ROOT = ROOT / ".cache" / "openclaw-upgrade-candidate"


def latest_summary(candidate_root: Path = DEFAULT_CANDIDATE_ROOT) -> Path | None:
    summaries = [p for p in candidate_root.glob("openclaw-*/summary.json") if p.is_file()]
    if not summaries:
        return None
    return max(summaries, key=lambda p: p.stat().st_mtime)


def load_target(summary_path: Path | None, explicit_target: str | None) -> tuple[str | None, str | None, list[str]]:
    warnings: list[str] = []
    if explicit_target:
        return explicit_target, str(summary_path) if summary_path else None, warnings
    if summary_path is None:
        warnings.append("no candidate summary found; pass --target-version or run openclaw-upgrade-candidate.sh first")
        return None, None, warnings
    try:
        data = json.loads(summary_path.read_text(encoding="utf-8"))
    except Exception as exc:
        warnings.append(f"could not read candidate summary: {type(exc).__name__}: {exc}")
        return None, str(summary_path), warnings
    if not isinstance(data, dict):
        warnings.append("candidate summary is not a JSON object")
        return None, str(summary_path), warnings
    target = str(data.get("target_version") or "").strip() or None
    if not target:
        warnings.append("candidate summary target_version is missing")
    return target, str(summary_path), warnings


def run_command(argv: list[str], timeout: int = 10) -> tuple[int | None, str, str]:
    try:
        completed = subprocess.run(
            argv,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout,
            check=False,
        )
    except FileNotFoundError as exc:
        return None, "", str(exc)
    except subprocess.TimeoutExpired as exc:
        return None, exc.stdout or "", f"timeout after {timeout}s"
    except Exception as exc:
        return None, "", f"{type(exc).__name__}: {exc}"
    return completed.returncode, completed.stdout, completed.stderr


def parse_version(text: str) -> str | None:
    match = re.search(r"\b\d{4}\.\d+\.\d+\b", text)
    if match:
        return match.group(0)
    return None


def evaluate(*, target_version: str | None, summary_path: str | None, version_stdout: str, version_rc: int | None,
             version_stderr: str, help_rc: int | None, help_stdout: str, help_stderr: str,
             warnings: list[str]) -> tuple[str, dict[str, Any]]:
    installed = parse_version(version_stdout)
    failures: list[str] = []

    if target_version is None:
        failures.append("target OpenClaw version is unknown")
    if version_rc != 0:
        failures.append("openclaw --version failed")
    if installed is None:
        failures.append("could not parse installed OpenClaw version")
    if target_version and installed and installed != target_version:
        failures.append(f"installed OpenClaw version {installed} does not match target {target_version}")
    if help_rc != 0 or not help_stdout.strip():
        failures.append("openclaw help smoke failed")

    status = "clone_upgrade_verified" if not failures else "blocked"
    record: dict[str, Any] = {
        "status": status,
        "package": "openclaw",
        "target_version": target_version,
        "installed_version": installed,
        "candidate_summary": summary_path,
        "checks": {
            "version_command_rc": version_rc,
            "help_smoke_passed": help_rc == 0 and bool(help_stdout.strip()),
            "installed_matches_target": bool(target_version and installed == target_version),
        },
        "failures": failures,
        "warnings": warnings,
        "next_required_step": (
            "If this ran on a clone host and status is clone_upgrade_verified, run the standard install parity, "
            "service health, A2A2H drift, safe security gates, and PWA chat-first layout gates before promotion. "
            "If this ran on production and status is blocked because production still has the old version, that is expected."
        ),
        "production_mutated_by_this_check": False,
        "spend_or_infrastructure_change": False,
        "secret_values_printed": False,
    }
    if version_stderr.strip():
        record["version_stderr_present"] = True
    if help_stderr.strip():
        record["help_stderr_present"] = True
    return status, record


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Verify OpenClaw upgrade state on a clone-test host.")
    parser.add_argument("--summary", type=Path, help="Path to candidate summary.json. Defaults to newest cached summary.")
    parser.add_argument("--candidate-root", type=Path, default=DEFAULT_CANDIDATE_ROOT)
    parser.add_argument("--target-version", help="Expected OpenClaw version. Overrides summary target_version.")
    args = parser.parse_args(argv)

    summary_path = args.summary or latest_summary(args.candidate_root)
    target, summary_label, warnings = load_target(summary_path, args.target_version)
    version_rc, version_stdout, version_stderr = run_command(["openclaw", "--version"])
    help_rc, help_stdout, help_stderr = run_command(["openclaw", "help"])
    status, record = evaluate(
        target_version=target,
        summary_path=summary_label,
        version_stdout=version_stdout,
        version_rc=version_rc,
        version_stderr=version_stderr,
        help_rc=help_rc,
        help_stdout=help_stdout,
        help_stderr=help_stderr,
        warnings=warnings,
    )
    print(json.dumps(record, indent=2, sort_keys=True))
    return 0 if status == "clone_upgrade_verified" else 1


if __name__ == "__main__":
    raise SystemExit(main())
