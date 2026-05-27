# BACKLOG-006 safe gates repeat after transient bus error — 2026-05-27T06:40Z

## Selection
OpenClaw continuous work pump selected BACKLOG-006 because P0 security/credential hygiene outranks lower-priority communication, clone-test, documentation, and heartbeat work. The destructive portions of BACKLOG-005/BACKLOG-006 remain blocked on a coordinated John-approved credential rotation / public history-scrub window, so this tick performed the highest-priority safe non-destructive verification step.

## Required context checked
- Read `/opt/cto/wiki/continuous-work-policy.md`, `/opt/cto/wiki/A2A2H_MAINTENANCE.md`, `/opt/cto/wiki/A2A2H_LAST_SYNC.md`, `/opt/cto/HEARTBEAT.md`, and `/opt/cto/BACKLOG.md`.
- Read recent PWA chat context from `logs/pwa-chat/2026-05-27.md`.
- Checked git status/recent commits and recent verification artifacts.
- Checked service health with `systemctl --user --failed`, user CTO/OpenClaw/Hermes units, and loopback listeners.

## A2A2H per-tick check
Tracker SHA: `91343b453ea64984a8f68b9bb9b43e5d86b6a3a1`.

Command scope:

```bash
git log 91343b453ea64984a8f68b9bb9b43e5d86b6a3a1..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py
```

Result: no upstream-eligible CTO commits after the tracked SHA. No A2A2H port was required this tick.

## Service health snapshot
- `systemctl --user --failed`: 0 failed units.
- Active user services: `cto-a2a-registry.service`, `cto-hermes-a2a-sidecar.service`, `cto-pwa-backend.service`, `hermes-gateway.service`, `openclaw-gateway.service`.
- Loopback listeners present: PWA backend `127.0.0.1:8088`, Hermes A2A sidecar `127.0.0.1:8643`, Hermes gateway `127.0.0.1:8642`, OpenClaw gateway `127.0.0.1:18789`.

## Verification result
First `scripts/security/run-safe-security-gates.sh` attempts reached the PWA routing regression section and the Python process exited with `Bus error (core dumped)` / exit `135`. The targeted PWA routing suite was then run directly and passed, indicating the tests themselves were not persistently failing.

A full repeat of `scripts/security/run-safe-security-gates.sh` then passed end-to-end:

- Secret artifact guard: passed, scanned 358 source-visible files.
- Operational secret redaction check: passed, scanned 218 files plus `chat.db` with no unredacted markers.
- Install secret-handling guard: passed.
- Credential rotation preflight: names/status only, required credentials present_nonempty, `.env` mode `600`, result `ready_for_coordinated_rotation_window`.
- Credential rotation smoke check: dependent user services active and local health endpoints healthy, result `local_services_healthy`.
- Redaction unit tests: 8/8 passed.
- PWA auth/routing regression tests: 32/32 passed.
- PWA voice UI regression tests: 1/1 passed.

## Result
BACKLOG-006 remains open because full remediation still requires the coordinated live credential rotation/revocation window and approved history/log cleanup. This tick preserved the safe gate evidence and captured the transient native Python bus-error symptom so a future pump can repair the test harness if it recurs.
