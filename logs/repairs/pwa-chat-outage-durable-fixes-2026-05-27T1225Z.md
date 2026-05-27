# PWA chat outage durable fixes — 2026-05-27T12:25Z

## What changed
- Added UTC-day bounded PWA OpenClaw session IDs in `services/pwa/backend/server.py`.
  - Legacy `OPENCLAW_SESSION_ID` values such as `pwa-john-20260527-1203` are treated as base hints and normalized to `pwa-john-YYYYMMDD`.
  - Detached background jobs derive from the current daily session and append the job id.
- Wrapped the in-process PWA chat worker in an outer `try/except` so crashes from OpenClaw, Hermes, or coordinated @both delivery append a visible `pwa_chat_worker_crashed` system_event to chat.db.
- Made Hermes A2A auth failures actionable and visible:
  - PWA now reports 401/403 as a `HERMES_A2A_TOKEN` mismatch/restart problem.
  - Hermes sidecar appends `hermes_a2a_unauthorized` system_event on unauthorized A2A calls.
- Opened BACKLOG-019 for the broader visible-failure-reporting requirement and A2A2H upstream-port tracking.

## Verification
- `python3 -m py_compile services/pwa/backend/server.py services/hermes_a2a_sidecar/server.py services/pwa/backend/job_runner.py`
- `python3 -m unittest tests.test_pwa_routing tests.test_pwa_voice_ui tests.test_pwa_layout` — 41 tests passed.
- Restarted `cto-hermes-a2a-sidecar` and `cto-pwa-backend`; both active.
- Verified live env propagation without printing secret values:
  - `cto-pwa-backend` `HERMES_A2A_TOKEN` matches `/opt/cto/.env`.
  - `cto-hermes-a2a-sidecar` `HERMES_A2A_TOKEN` matches `/opt/cto/.env`.
  - `cto-pwa-backend` and sidecar `HERMES_API_SERVER_KEY` match `/opt/cto/.env`.
  - `hermes-gateway` `API_SERVER_KEY` matches `/opt/cto/.env` `HERMES_API_SERVER_KEY`.
- Local health checks passed for `http://127.0.0.1:8088/api/health` and `http://127.0.0.1:8643/health`.

## Rollback
- Revert the commit containing these changes and restart `cto-pwa-backend` + `cto-hermes-a2a-sidecar`.
