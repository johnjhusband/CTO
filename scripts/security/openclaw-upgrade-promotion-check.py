#!/usr/bin/env python3
"""No-spend promotion gate for an isolated OpenClaw upgrade candidate.

This script does not upgrade production, restart services, provision cloud
resources, or print secrets. It validates the JSON summary produced by
scripts/security/openclaw-upgrade-candidate.sh and emits a concise readiness
record for the later clone-test-replace promotion window.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CANDIDATE_ROOT = ROOT / ".cache" / "openclaw-upgrade-candidate"


def current_openclaw_version() -> str | None:
    try:
        completed = subprocess.run(
            ["openclaw", "--version"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=10,
            check=False,
        )
    except Exception:
        return None
    if completed.returncode != 0:
        return None
    match = re.search(r"\b\d{4}\.\d+\.\d+\b", completed.stdout)
    if match:
        return match.group(0)
    parts = completed.stdout.strip().split()
    if not parts:
        return None
    return parts[-1]


def latest_summary(candidate_root: Path = DEFAULT_CANDIDATE_ROOT) -> Path | None:
    summaries = [p for p in candidate_root.glob("openclaw-*/summary.json") if p.is_file()]
    if not summaries:
        return None
    return max(summaries, key=lambda p: p.stat().st_mtime)


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError("candidate summary is not a JSON object")
    return data


def evaluate(summary: dict[str, Any], *, production_version: str | None, summary_path: Path) -> tuple[str, list[str], dict[str, Any]]:
    failures: list[str] = []
    warnings: list[str] = []

    if summary.get("package") != "openclaw":
        failures.append("summary package is not openclaw")
    target = str(summary.get("target_version") or "").strip()
    if not target:
        failures.append("target_version missing")
    if not summary.get("help_smoke_passed"):
        failures.append("candidate help smoke did not pass")
    if summary.get("production_mutation") is not False:
        failures.append("candidate summary does not explicitly prove production_mutation=false")
    if summary.get("global_npm_mutation") is not False:
        failures.append("candidate summary does not explicitly prove global_npm_mutation=false")
    if summary.get("lifecycle_scripts_disabled") is not True:
        failures.append("candidate npm lifecycle scripts were not disabled")

    summary_current = summary.get("current_version")
    if production_version and summary_current and str(summary_current) != production_version:
        warnings.append(
            f"candidate was generated against production {summary_current}, current production reports {production_version}"
        )
    if production_version and target and production_version == target:
        warnings.append("production already reports the candidate target version")

    status = "blocked" if failures else "ready_for_clone_test_replace"
    record = {
        "status": status,
        "package": "openclaw",
        "production_version": production_version,
        "target_version": target or None,
        "candidate_summary": str(summary_path),
        "checks": {
            "candidate_help_smoke_passed": bool(summary.get("help_smoke_passed")),
            "production_mutation": bool(summary.get("production_mutation")),
            "global_npm_mutation": bool(summary.get("global_npm_mutation")),
            "lifecycle_scripts_disabled": bool(summary.get("lifecycle_scripts_disabled")),
        },
        "failures": failures,
        "warnings": warnings,
        "next_required_step": (
            "Run clone-test-replace on a candidate host and promote only after install parity, service health, A2A2H drift, "
            "safe security gates, and PWA chat-first visible layout gates pass. Do not upgrade production in place."
        ),
        "production_mutated_by_this_check": False,
        "spend_or_infrastructure_change": False,
        "secret_values_printed": False,
    }
    return status, failures, record


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate isolated OpenClaw candidate readiness for clone-test-replace.")
    parser.add_argument("--summary", type=Path, help="Path to candidate summary.json. Defaults to newest cached summary.")
    parser.add_argument("--candidate-root", type=Path, default=DEFAULT_CANDIDATE_ROOT)
    parser.add_argument("--current-version", help="Override production OpenClaw version for tests.")
    args = parser.parse_args(argv)

    summary_path = args.summary or latest_summary(args.candidate_root)
    if summary_path is None:
        print(json.dumps({
            "status": "blocked",
            "failures": ["no OpenClaw candidate summary found; run scripts/security/openclaw-upgrade-candidate.sh first"],
            "production_mutated_by_this_check": False,
            "spend_or_infrastructure_change": False,
            "secret_values_printed": False,
        }, indent=2, sort_keys=True))
        return 1

    try:
        summary = load_json(summary_path)
    except Exception as exc:
        print(json.dumps({
            "status": "blocked",
            "failures": [f"could not read candidate summary: {type(exc).__name__}: {exc}"],
            "candidate_summary": str(summary_path),
            "production_mutated_by_this_check": False,
            "spend_or_infrastructure_change": False,
            "secret_values_printed": False,
        }, indent=2, sort_keys=True))
        return 1

    production_version = args.current_version if args.current_version is not None else current_openclaw_version()
    status, _failures, record = evaluate(summary, production_version=production_version, summary_path=summary_path)
    print(json.dumps(record, indent=2, sort_keys=True))
    return 0 if status == "ready_for_clone_test_replace" else 1


if __name__ == "__main__":
    raise SystemExit(main())
