#!/usr/bin/env python3
"""Build a human-readable OpenClaw clone-test-replace promotion packet.

This script is intentionally read-only. It does not install packages, restart services,
call cloud APIs, or mutate production. It converts the existing isolated candidate and
clone-gate JSON summaries into a concise markdown artifact suitable for John/operator
review before any production OpenClaw promotion.
"""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUT_DIR = ROOT / "logs/security"


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover - exercised through CLI behavior
        raise SystemExit(f"FAIL: could not read JSON from {path}: {type(exc).__name__}: {exc}") from exc
    if not isinstance(data, dict):
        raise SystemExit(f"FAIL: expected JSON object in {path}")
    return data


def find_latest(patterns: list[str]) -> Path | None:
    matches: list[Path] = []
    for pattern in patterns:
        matches.extend(ROOT.glob(pattern))
    files = [p for p in matches if p.is_file()]
    if not files:
        return None
    return max(files, key=lambda p: p.stat().st_mtime)


def safe_text(value: Any) -> str:
    if value is None:
        return "unknown"
    text = str(value)
    # Keep packets concise and avoid accidentally embedding huge logs.
    return text.replace("\n", " ")[:300]


def build_packet(candidate: dict[str, Any], gate: dict[str, Any], candidate_path: Path, gate_path: Path, timestamp: str) -> str:
    gate_status = safe_text(gate.get("status"))
    clone_verify = gate.get("clone_verify") if isinstance(gate.get("clone_verify"), dict) else {}
    failures = gate.get("failures") if isinstance(gate.get("failures"), list) else []
    promote_ready = gate_status == "clone_gate_verified" and not failures
    current_version = safe_text(candidate.get("current_version") or clone_verify.get("current_version"))
    target_version = safe_text(candidate.get("target_version") or clone_verify.get("target_version"))
    installed_version = safe_text(clone_verify.get("installed_version") or clone_verify.get("openclaw_version"))
    help_ok = bool(candidate.get("help_smoke_passed"))
    no_spend = gate.get("spend_or_infrastructure_change") is False
    no_mutation = gate.get("production_mutated_by_this_check") is False
    no_secrets = gate.get("secret_values_printed") is False
    a2a_drift = gate.get("a2a2h_drift_lines") if isinstance(gate.get("a2a2h_drift_lines"), list) else []

    lines = [
        "# BACKLOG-012 — OpenClaw upgrade promotion packet",
        "",
        f"- Timestamp: {timestamp}",
        f"- Candidate summary: `{candidate_path}`",
        f"- Clone gate summary: `{gate_path}`",
        f"- Current production version observed by candidate smoke: `{current_version}`",
        f"- Target OpenClaw version: `{target_version}`",
        f"- Installed version in gate environment: `{installed_version}`",
        f"- Candidate help smoke passed: `{str(help_ok).lower()}`",
        f"- Clone gate status: `{gate_status}`",
        f"- A2A2H drift lines: `{len(a2a_drift)}`",
        f"- No production mutation by packet/gate: `{str(no_mutation).lower()}`",
        f"- No spend or infrastructure change by packet/gate: `{str(no_spend).lower()}`",
        f"- Secret values printed: `{str(not no_secrets).lower()}`",
        "",
        "## Decision",
        "",
    ]
    if promote_ready:
        lines.extend([
            "✅ Promotion-ready on the checked clone host.",
            "",
            "Next step: perform the documented clone-test-replace cutover only after operator review; do not upgrade production in place.",
        ])
    else:
        lines.extend([
            "⛔ Not promotion-ready.",
            "",
            "The safe next step is to run the clone gate on an actual clone-test-replace candidate whose installed OpenClaw version matches the isolated candidate target. Production must remain on the current version until that passes.",
        ])
    if failures:
        lines.extend(["", "## Blocking failures", ""])
        for failure in failures:
            lines.append(f"- {safe_text(failure)}")
    lines.extend([
        "",
        "## Safety statement",
        "",
        "This packet is a read-only synthesis of existing JSON evidence. It did not install packages, restart services, create cloud resources, change DNS/firewalls, mutate production OpenClaw, or print secret values.",
        "",
    ])
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate-summary", type=Path, help="Path to openclaw-upgrade-candidate summary.json")
    parser.add_argument("--clone-gate-summary", type=Path, help="Path to openclaw-upgrade-clone-gate JSON summary")
    parser.add_argument("--output", type=Path, help="Markdown output path")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    candidate_path = args.candidate_summary or find_latest([".cache/openclaw-upgrade-candidate/**/summary.json"])
    gate_path = args.clone_gate_summary or find_latest(["logs/security/*clone-gate*.json", "logs/security/openclaw-upgrade-clone-gate-*.json"])
    if candidate_path is None:
        raise SystemExit("FAIL: no OpenClaw candidate summary found")
    if gate_path is None:
        raise SystemExit("FAIL: no OpenClaw clone-gate summary found")
    timestamp = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    out = args.output or (DEFAULT_OUT_DIR / f"BACKLOG-012-openclaw-promotion-packet-{timestamp.replace(':', '').replace('-', '')}.md")
    out.parent.mkdir(parents=True, exist_ok=True)
    packet = build_packet(load_json(candidate_path), load_json(gate_path), candidate_path, gate_path, timestamp)
    out.write_text(packet, encoding="utf-8")
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
