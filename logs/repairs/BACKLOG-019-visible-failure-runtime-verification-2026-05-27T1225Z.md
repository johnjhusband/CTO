# BACKLOG-019 visible failure runtime verification — 2026-05-27T12:25Z

## Selection
OpenClaw continuous work pump selected BACKLOG-019 after the mandatory A2A2H per-tick upstream-port check returned no upstream-eligible CTO drift since `97a48575c029778b483433ef7f2ea594fad2bd31`. Higher P0 credential/history-scrub items remain blocked on a coordinated rotation/history-scrub window. Hermes provider circuit is open in `.cache/hermes-work-pump-provider-failure.json`, so no semantic work was delegated to Hermes this tick.

## Current state checked
- Recent PWA chat included John's 12:04Z outage report and durable-fix requirements.
- `BACKLOG.md`, `HEARTBEAT.md`, `wiki/continuous-work-policy.md`, `wiki/A2A2H_MAINTENANCE.md`, and `wiki/A2A2H_LAST_SYNC.md` were inspected.
- Git status was clean before this verification update, with no unpushed commits.
- Loopback health endpoints responded for PWA backend, Hermes A2A sidecar, Hermes gateway, and OpenClaw gateway despite system service-name probes needing user-unit names.
- Recent repair logs show the PWA outage fix and A2A2H port are already pushed.

## Evidence on disk
BACKLOG-019 is not fully closed, but the first visible-failure-reporting repair is present and verified:
- `services/pwa/backend/server.py` derives daily-bounded PWA OpenClaw session IDs.
- The in-process PWA chat worker has an outer exception handler that appends a visible `pwa_chat_worker_crashed` `system_event` to chat.db.
- Route-level failures append visible `hermes_send_timeout`, `hermes_send_failed`, `openclaw_send_timeout`, `openclaw_send_failed`, and `coordinated_both_failed` system events.
- Hermes A2A unauthorized/token mismatch paths are actionable and visible via `hermes_a2a_unauthorized` / token-mismatch reporting.
- Regression tests include `test_worker_crash_event_is_visible_in_chat_db_contract` and `test_send_to_hermes_reports_a2a_token_mismatch_actionably`.

## Verification
- `python3 -m py_compile services/pwa/backend/server.py services/hermes_a2a_sidecar/server.py services/pwa/backend/job_runner.py` — passed.
- `python3 -m unittest -v tests.test_pwa_routing tests.test_pwa_layout tests.test_pwa_voice_ui` — 41/41 passed.
- `scripts/security/run-safe-security-gates.sh` — passed, including redaction, PWA auth/routing, local service smoke, and credential-rotation names-only preflight.

## Result
BACKLOG-019 moved from `open` to `in-progress` with runtime/source/test verification recorded. Remaining work before final closure: add or explicitly defer a stale pending-job watchdog and tune broader false-positive/noise behavior for stuck delivery detection.
