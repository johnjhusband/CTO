# BACKLOG-003 PWA denied JSON no-store hardening — 2026-05-27T07:35Z

## Scope
Public security/access-control audit hardening for the live PWA. This tick did not delegate to Hermes because the provider circuit was open, did not mutate credentials, did not rewrite history, did not create infrastructure, and did not spend money.

## Preconditions checked
- A2A2H drift check ran before selection: no upstream-eligible drift since `2208320fa5761e5e8318133860fc64e840d79d89`.
- Git state: `/opt/cto` and `/opt/a2a2h` were clean and synced before work.
- Services: no failed user units; OpenClaw Gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers were active.
- Hermes provider circuit: open after 7 consecutive provider-side `agent_incomplete` failures, so no semantic Hermes delegation was attempted.
- Backlog scan: P0 credential/history actions remain coordinated-window blocked; P0 PWA feature items remain pending John/device evidence; no item was safely closable from disk evidence.

## Finding
The live PWA correctly denied a public scanner-style WordPress plugin probe at `/wp-json/gravitysmtp/v1/tests/mock-data?page=gravitysmtp-settings` with HTTP 401. Follow-up unauthenticated checks against `/.env`, `/api/messages`, and `/chat-log/` also returned 401. However, denied JSON responses did not include `Cache-Control: no-store`, unlike the HTML login shell.

## Repair
Updated `services/pwa/backend/server.py` so `_json()` adds `Cache-Control: no-store` to all 4xx/5xx JSON responses. This prevents unauthorized/error payloads from being cached by browsers or intermediaries. Added regression coverage in `tests/test_pwa_routing.py`.

## Verification
- Initial targeted test run exposed a test harness import miss for `BytesIO`; fixed it before commit.
- `python3 -m unittest -v tests.test_pwa_routing tests.test_pwa_voice_ui tests.test_redact_operational_secrets` passed: 42/42.
- `scripts/security/run-safe-security-gates.sh` passed end-to-end: secret artifact guard, operational redaction, install guard, credential preflight/smoke, redaction tests, PWA routing tests, and voice UI test.
- A2A2H backend syntax check passed, and required CTO-specific string grep over A2A2H services/scripts/frontend was clean.
- Restarted `cto-pwa-backend.service` and verified live unauthenticated scanner-style probe now returns HTTP 401 with `Cache-Control: no-store`.

## A2A2H sync
Ported CTO `27abb1203d2a13253e8c1b7e9658518d77794236` to A2A2H as `abe5e3a6023b582e6666592612909d5c07d0ffd5`; tracker updated.

## Result
The live PWA remains fail-closed for public probes and now marks denied JSON responses as non-cacheable. No secrets, raw headers, bearer tokens, environment values, or raw provider traces were recorded.
