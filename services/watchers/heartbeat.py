#!/usr/bin/env python3
"""
Heartbeat watcher — Hermes-side service that keeps OpenClaw alive.

Per HERMES_ROLE.md: Hermes is the autonomic nervous system. If OpenClaw's
daemon crashes or hangs, this script restarts it. Three failed restart attempts
in a 5-minute window escalate to John via the chat DB (PWA will surface it).

Run as systemd user timer every 30 seconds. Stateless except for the
short-window restart counter, which is persisted to /tmp so restarts of the
watcher itself don't lose the count.

Checked: HTTP health endpoint reachability on 127.0.0.1:18789 (OpenClaw).
On failure: invoke `systemctl --user restart openclaw-gateway` (the cto user has
NOPASSWD sudo, but we don't need root for user services).
"""
from __future__ import annotations
import json
import os
import sys
import time
import socket
import subprocess
import urllib.request
import urllib.error
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from chat.db import append  # noqa: E402

OPENCLAW_HEALTH_URL = os.environ.get("OPENCLAW_HEALTH_URL", "http://127.0.0.1:18789/healthz")
SERVICE = os.environ.get("OPENCLAW_SERVICE", "openclaw-gateway")
COUNTER_FILE = Path(os.environ.get("HEARTBEAT_COUNTER", "/tmp/cto-heartbeat-counter.json"))
WINDOW_S = int(os.environ.get("HEARTBEAT_WINDOW_S", "300"))      # 5 min
MAX_RESTARTS = int(os.environ.get("HEARTBEAT_MAX_RESTARTS", "3"))
PROBE_TIMEOUT_S = int(os.environ.get("HEARTBEAT_PROBE_TIMEOUT_S", "5"))


def _is_healthy() -> bool:
    """Return True if OpenClaw responds to the health probe."""
    try:
        with urllib.request.urlopen(OPENCLAW_HEALTH_URL, timeout=PROBE_TIMEOUT_S) as resp:
            return 200 <= resp.status < 400
    except (urllib.error.URLError, socket.timeout):
        # Health endpoint might not exist on this OpenClaw build; fall back to
        # raw TCP connectivity check.
        try:
            with socket.create_connection(("127.0.0.1", 18789), timeout=PROBE_TIMEOUT_S):
                return True
        except OSError:
            return False
    except Exception:
        return False


def _load_counter() -> dict:
    if COUNTER_FILE.exists():
        try:
            return json.loads(COUNTER_FILE.read_text())
        except Exception:
            return {"events": []}
    return {"events": []}


def _save_counter(state: dict) -> None:
    COUNTER_FILE.write_text(json.dumps(state))


def _restart_attempts_in_window(state: dict) -> int:
    cutoff = time.time() - WINDOW_S
    state["events"] = [ts for ts in state.get("events", []) if ts > cutoff]
    return len(state["events"])


def _restart_service() -> tuple[bool, str]:
    """Return (success, stderr_or_stdout)."""
    try:
        result = subprocess.run(
            ["systemctl", "--user", "restart", SERVICE],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode == 0:
            return True, result.stdout
        return False, result.stderr or result.stdout
    except subprocess.TimeoutExpired:
        return False, "systemctl restart timed out"
    except Exception as e:
        return False, repr(e)


def main() -> None:
    if _is_healthy():
        # Healthy — clean up old counter events to prevent stale escalation
        state = _load_counter()
        _restart_attempts_in_window(state)
        _save_counter(state)
        return

    state = _load_counter()
    attempts = _restart_attempts_in_window(state)

    if attempts >= MAX_RESTARTS:
        # Escalate
        append(sender="hermes", recipient="john", kind="system_event",
               content=json.dumps({
                   "alert": "openclaw_unrecoverable",
                   "attempts_in_window": attempts,
                   "window_seconds": WINDOW_S,
                   "service": SERVICE,
                   "action_needed": "manual investigation — run scripts/install-cto.sh on a fresh VPS or "
                                    "investigate logs via 'journalctl --user -u openclaw-gateway -n 200'",
               }))
        # Don't loop endlessly trying — leave the counter alone so next tick re-escalates
        return

    # Attempt restart
    ok, output = _restart_service()
    state["events"].append(time.time())
    _save_counter(state)
    append(sender="hermes", recipient="john" if not ok else None,
           kind="system_event", content=json.dumps({
               "event": "openclaw_restart_attempt",
               "success": ok,
               "attempt_number": attempts + 1,
               "output_tail": output[-500:] if output else "",
           }))


if __name__ == "__main__":
    main()
