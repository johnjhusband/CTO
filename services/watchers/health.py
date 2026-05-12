#!/usr/bin/env python3
"""
Health watcher (Approach C from feedback_request_vs_directive / 3h-B decision).

Outcome-driven, not metric-driven. Runs every 60s via systemd timer. Checks:

  1. Both daemons respond to their health endpoints.
  2. Disk free > 5% on /opt (so logs/data don't fill).
  3. The most recent scheduled task (heartbeat) ran within the last 5 min.
  4. The PWA backend (when deployed) responds.

A failure of any check posts a `system_event` to the chat DB tagged
'health_alert'. The PWA renders these for John's visibility. If a check fails
N=3 consecutive times, the autonomous-repair runner is invoked.

Per 3h-B: metric-based monitoring is informational only — see anomaly.py — and
never triggers action alone. THIS file is the action-trigger.
"""
from __future__ import annotations
import json
import os
import shutil
import socket
import subprocess
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from chat.db import append  # noqa: E402

STATE_FILE = Path(os.environ.get("HEALTH_STATE", "/tmp/cto-health-state.json"))
CONSECUTIVE_FAILS_THRESHOLD = int(os.environ.get("HEALTH_FAILS_THRESHOLD", "3"))
DISK_FREE_PCT_THRESHOLD = int(os.environ.get("DISK_FREE_PCT_THRESHOLD", "5"))
DISK_PATH = os.environ.get("DISK_WATCH_PATH", "/opt")
HEARTBEAT_COUNTER = Path(os.environ.get("HEARTBEAT_COUNTER", "/tmp/cto-heartbeat-counter.json"))

CHECKS = [
    ("openclaw_health", "http://127.0.0.1:18789/healthz"),
    ("hermes_health", "http://127.0.0.1:8642/health"),
    ("a2a_registry_health", "http://127.0.0.1:9000/health"),
    ("hermes_a2a_sidecar_health", "http://127.0.0.1:8643/health"),
]


def _http_ok(url: str, timeout: int = 5) -> tuple[bool, str]:
    try:
        with urllib.request.urlopen(url, timeout=timeout) as resp:
            if 200 <= resp.status < 400:
                return True, "ok"
            return False, f"http {resp.status}"
    except urllib.error.HTTPError as e:
        return False, f"http {e.code}"
    except (urllib.error.URLError, socket.timeout) as e:
        return False, f"unreachable: {e}"
    except Exception as e:
        return False, repr(e)


def _disk_free_ok() -> tuple[bool, str]:
    try:
        usage = shutil.disk_usage(DISK_PATH)
        pct_free = (usage.free / usage.total) * 100
        if pct_free < DISK_FREE_PCT_THRESHOLD:
            return False, f"disk {DISK_PATH} only {pct_free:.1f}% free"
        return True, f"{pct_free:.1f}% free"
    except Exception as e:
        return False, repr(e)


def _heartbeat_recent() -> tuple[bool, str]:
    """Did the heartbeat watcher run recently? Stale counter = scheduler dead."""
    if not HEARTBEAT_COUNTER.exists():
        # First run — heartbeat may not have written yet. Don't false-alarm.
        return True, "counter not yet created"
    age = time.time() - HEARTBEAT_COUNTER.stat().st_mtime
    if age > 180:  # 3 minutes — heartbeat fires every 30s
        return False, f"heartbeat last update {age:.0f}s ago"
    return True, f"heartbeat fresh ({age:.0f}s)"


def _load_state() -> dict:
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except Exception:
            return {}
    return {}


def _save_state(state: dict) -> None:
    STATE_FILE.write_text(json.dumps(state))


def _invoke_autonomous_repair(check_name: str, detail: str) -> None:
    """Run the repair script asynchronously so we don't block this watcher."""
    script = Path(__file__).resolve().parent / "autonomous_repair.py"
    try:
        subprocess.Popen(
            [sys.executable, str(script), "--check", check_name, "--detail", detail],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
    except Exception as e:
        append(sender="hermes", recipient="john", kind="system_event",
               content=json.dumps({"event": "repair_invoke_failed", "error": repr(e)}))


def main() -> None:
    state = _load_state()
    failed_now = []
    for name, url in CHECKS:
        ok, detail = _http_ok(url)
        prev = state.get(name, {"consecutive_fails": 0, "last_fail_detail": ""})
        if ok:
            if prev["consecutive_fails"] > 0:
                # Recovered — log
                append(sender="hermes", recipient="john", kind="system_event",
                       content=json.dumps({"event": "health_recovered", "check": name,
                                           "prev_consecutive_fails": prev["consecutive_fails"]}))
            state[name] = {"consecutive_fails": 0, "last_fail_detail": ""}
        else:
            cf = prev["consecutive_fails"] + 1
            state[name] = {"consecutive_fails": cf, "last_fail_detail": detail}
            failed_now.append((name, cf, detail))

    # Non-HTTP checks
    for name, fn in [("disk_free", _disk_free_ok), ("heartbeat_freshness", _heartbeat_recent)]:
        ok, detail = fn()
        prev = state.get(name, {"consecutive_fails": 0})
        if ok:
            state[name] = {"consecutive_fails": 0, "last_fail_detail": ""}
        else:
            cf = prev["consecutive_fails"] + 1
            state[name] = {"consecutive_fails": cf, "last_fail_detail": detail}
            failed_now.append((name, cf, detail))

    _save_state(state)

    # Alert and possibly trigger repair
    for name, cf, detail in failed_now:
        append(sender="hermes", recipient="john", kind="system_event",
               content=json.dumps({"event": "health_alert", "check": name,
                                   "consecutive_fails": cf, "detail": detail}))
        if cf >= CONSECUTIVE_FAILS_THRESHOLD:
            _invoke_autonomous_repair(name, detail)


if __name__ == "__main__":
    main()
