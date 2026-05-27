# OpenClaw work pump: Hermes work-pump degraded reporting repair

- Timestamp: 2026-05-27T03:55Z
- Selected item: hemisphere health / Hermes continuous work pump reliability, after required A2A2H per-tick check.
- A2A2H drift check: `git log 12539b7c4dcd2f21f06d4e2bd7e9d84db627aceb..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py` returned no upstream-eligible CTO commits, so no A2A2H port was needed. A2A2H HEAD remains `14112aee943a7372b6d072f9d2e5745574a5da8f`.
- Recent failure reviewed: `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T035011Z.md` recorded repeat Hermes HTTP 502 `agent_incomplete` after retry/restart.
- Repair: `scripts/hermes-work-pump.sh` now emits a sanitized `hermes_work_pump_blocked` PWA/chat `system_event` whenever it writes an `agent_incomplete` blocked artifact, so John can see semantic Hermes work-pump degradation even when HTTP health endpoints are green.
- Safety: no credentials, raw request headers, bearer tokens, or provider traces are logged; the new notification path is best-effort and cannot make the scheduled pump fail harder.

## Verification

- `bash -n scripts/hermes-work-pump.sh` passed.
- Embedded Python in `scripts/hermes-work-pump.sh` parsed with `ast.parse`.
- `scripts/security/run-safe-security-gates.sh` passed: secret artifact guard, operational redaction across logs plus chat.db, install guard, credential preflight/smoke syntax, names-only credential preflight, local service smoke checks, 8 redaction tests, 29 PWA auth/routing tests, and 1 PWA voice UI test.
