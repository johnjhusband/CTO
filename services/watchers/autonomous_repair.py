#!/usr/bin/env python3
"""
Autonomous repair runner — invoked by the health watcher when a check has
failed N consecutive times.

Per the system-prompt extensions:
  1. Inspect last 200 lines of relevant journalctl / log.
  2. Match against a known-pattern table.
  3. Apply the matched remediation.
  4. Restart + verify.
  5. After 3 failed repair attempts for the same check, escalate via chat.

The known-pattern table is small at v1.1 — populated as patterns are observed
in the wild. Adding a pattern is a one-line append below; obvious targets for
future expansion get a `# TODO` marker.

This runner does not loop. The health watcher invokes it once per failing
check; if the repair fails, the next health-watcher tick may invoke it again.
A counter (in chat DB / state file) limits how many times we try the same fix.

Invocation:
  autonomous_repair.py --check <check_name> --detail "<failure_detail>"
"""
from __future__ import annotations
import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from chat.db import append  # noqa: E402

REPAIR_STATE = Path(os.environ.get("REPAIR_STATE", "/tmp/cto-repair-state.json"))
MAX_REPAIRS_PER_CHECK = int(os.environ.get("MAX_REPAIRS_PER_CHECK", "3"))


def _load_state() -> dict:
    if REPAIR_STATE.exists():
        try:
            return json.loads(REPAIR_STATE.read_text())
        except Exception:
            return {}
    return {}


def _save_state(state: dict) -> None:
    REPAIR_STATE.write_text(json.dumps(state))


def _journal_tail(service: str, lines: int = 200) -> str:
    try:
        r = subprocess.run(
            ["journalctl", "--user", "-u", service, "-n", str(lines), "--no-pager"],
            capture_output=True, text=True, timeout=15,
        )
        return r.stdout
    except Exception as e:
        return f"(journalctl error: {e})"


def _restart(service: str) -> tuple[bool, str]:
    try:
        r = subprocess.run(
            ["systemctl", "--user", "restart", service],
            capture_output=True, text=True, timeout=30,
        )
        return (r.returncode == 0, r.stderr or r.stdout)
    except Exception as e:
        return False, repr(e)


def _check_to_service(check_name: str) -> str | None:
    return {
        "openclaw_health": "openclaw-gateway",
        "hermes_health": "hermes-gateway",
        "a2a_registry_health": "cto-a2a-registry",
        "hermes_a2a_sidecar_health": "cto-hermes-a2a-sidecar",
    }.get(check_name)


# Pattern table — (compiled regex, remediation function name, human label).
# Remediation functions take the service name and return (success, action_taken).

def _remedy_restart(service: str) -> tuple[bool, str]:
    ok, _ = _restart(service)
    return ok, f"restarted {service}"


def _remedy_trim_logs(_service: str) -> tuple[bool, str]:
    """Disk-pressure remediation: delete oldest install logs, rotate journal."""
    try:
        # Trim our own install/digest/anomaly logs older than 7 days
        for root in ("/opt/cto/logs/install", "/opt/cto/logs/digest"):
            p = Path(root)
            if not p.exists():
                continue
            cutoff = time.time() - (7 * 86400)
            for f in p.glob("*"):
                if f.is_file() and f.stat().st_mtime < cutoff:
                    f.unlink(missing_ok=True)
        # Vacuum journal
        subprocess.run(
            ["sudo", "journalctl", "--vacuum-time=2d"],
            capture_output=True, timeout=30,
        )
        return True, "trimmed install/digest logs older than 7d; vacuumed journal to 2d"
    except Exception as e:
        return False, f"trim error: {e}"


KNOWN_PATTERNS = [
    # (regex on journal tail, remediation callable, label)
    (re.compile(r"Out of memory|Killed process|oom-killer"), _remedy_restart, "OOM kill"),
    (re.compile(r"Address already in use|EADDRINUSE"), _remedy_restart, "port conflict"),
    (re.compile(r"existing config is missing gateway\.mode"), _remedy_restart, "OpenClaw stale-config"),
    (re.compile(r"Connection refused|ECONNREFUSED"), _remedy_restart, "connection refused"),
]


def repair(check_name: str, detail: str) -> tuple[bool, str]:
    """Return (success, action_description). Logs to chat regardless."""
    state = _load_state()
    cnt = state.get(check_name, {}).get("count", 0)

    if cnt >= MAX_REPAIRS_PER_CHECK:
        return False, f"max repairs reached ({cnt}); escalating"

    service = _check_to_service(check_name)
    if check_name == "disk_free":
        ok, action = _remedy_trim_logs("")
    elif service is None:
        return False, f"no service mapping for check {check_name!r}"
    else:
        journal = _journal_tail(service)
        matched = None
        for pat, fn, label in KNOWN_PATTERNS:
            if pat.search(journal):
                matched = (fn, label)
                break
        if matched is None:
            # Default: just restart and see if it sticks
            ok, action = _remedy_restart(service)
            action = f"default-restart applied (no known pattern matched); {action}"
        else:
            fn, label = matched
            ok, action = fn(service)
            action = f"matched pattern '{label}'; {action}"

    state.setdefault(check_name, {})["count"] = cnt + 1
    state[check_name]["last_action"] = action
    state[check_name]["last_attempt_ts"] = time.time()
    _save_state(state)
    return ok, action


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", required=True)
    parser.add_argument("--detail", default="")
    args = parser.parse_args()

    append(sender="hermes", recipient="john", kind="system_event",
           content=json.dumps({"event": "autonomous_repair_start",
                               "check": args.check, "detail": args.detail}))
    ok, action = repair(args.check, args.detail)
    append(sender="hermes", recipient="john", kind="system_event",
           content=json.dumps({"event": "autonomous_repair_result",
                               "check": args.check, "success": ok, "action": action}))


if __name__ == "__main__":
    main()
