# BACKLOG-006 safe gate repair: SQLite init lock tolerance — 2026-05-27T04:35Z

## Selected item
P0 security/access-control gate reliability. BACKLOG-006 live credential rotation remains blocked on a coordinated window, but the safe gate must remain deterministic after recent PWA/background-delivery work.

## Context inspected
- Recent PWA chat showed one `push_device_status` event and continuing sanitized Hermes `agent_incomplete` degradation events.
- `git status` was clean and synced at tick start.
- `systemctl --user --failed` reported 0 failed units.
- OpenClaw gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers were active.
- A2A2H per-tick check showed no drift before this repair.
- No open/pending backlog item was safe to close: BACKLOG-004/014/016 still need John/device confirmation; BACKLOG-005/006 require coordinated destructive/history or live credential windows.

## Problem
The first full safe-gate run passed the secret artifact guard, operational redaction check, install guard, credential preflight/smoke checks, and redaction tests, then exposed a transient SQLite `database is locked` error while the PWA routing tests initialized a temporary chat database. A targeted rerun of the affected test suite passed, confirming a gate-stability issue rather than a persistent product failure.

## Repair
Updated `services/chat/db.py` so `_init()` tolerates a transient `database is locked` only while toggling `PRAGMA journal_mode=WAL`. WAL is an optimization for concurrent readers; schema creation remains idempotent and the connection can continue with SQLite's current journal mode. Non-lock SQLite errors still raise.

Ported the same repair to `/opt/a2a2h/services/chat/db.py`.

## Verification
- `python3 -m unittest -v tests/test_pwa_routing.py tests/test_pwa_voice_ui.py tests/test_redact_operational_secrets.py` — 39/39 passed.
- `scripts/security/run-safe-security-gates.sh` — passed end-to-end after the repair:
  - secret artifact guard scanned 332 source-visible files;
  - operational redaction scanned 192 files plus `chat.db`;
  - install secret-handling guard passed;
  - credential preflight/smoke syntax passed;
  - names-only credential preflight reported `ready_for_coordinated_rotation_window`;
  - local service smoke reported `local_services_healthy`;
  - redaction tests 8/8 passed;
  - PWA auth/routing tests 30/30 passed;
  - PWA voice UI test 1/1 passed.

## Result
The recurring safe credential/security gate is green again and less likely to fail on harmless SQLite WAL initialization contention. No secret values, raw request headers, bearer tokens, or raw provider traces were recorded.
