# BACKLOG-006 rotation smoke gate

- Timestamp: 2026-05-27T02:25Z
- Selected item: BACKLOG-006 P0 credential hygiene.
- Status: advanced_not_closed.
- A2A2H per-tick upstream-port check: no upstream-eligible CTO commits since `bfe5ad51f99dd15019ebb3dbd510b73d0ea49072`; no port needed before selecting this item.
- Work completed: added `scripts/security/rotation-smoke.sh`, a non-destructive pre/post-rotation smoke check for the eventual coordinated credential rotation window.
- What it checks: `/opt/cto/.env` mode remains `600`, dependent user services are active, and local health endpoints for OpenClaw Gateway, Hermes Gateway, Hermes A2A sidecar, and PWA backend respond.
- Safety: the script prints service names, coarse health status, and response byte counts only; it never prints env values, response bodies, request headers, bearer tokens, cookies, or provider credentials, and it does not mutate runtime state.
- Gate integration: `scripts/security/run-safe-security-gates.sh` now runs the rotation smoke check after the names-only preflight.
- Verification: `scripts/security/run-safe-security-gates.sh` passed end-to-end: secret artifact guard, operational redaction check across logs plus chat.db, install guard, preflight syntax/runtime, rotation smoke health, 8 redaction tests, 28 PWA auth/routing tests, and 1 PWA voice UI test.
- Remaining blocker: full BACKLOG-006 closure still requires a coordinated live credential replacement/revocation window and approved broader history/log cleanup.

## Local smoke result captured

- openclaw-gateway.service: active; `http://127.0.0.1:18789/health` ok
- hermes-gateway.service: active; `http://127.0.0.1:8642/health` ok
- cto-hermes-a2a-sidecar.service: active; `http://127.0.0.1:8643/health` ok
- cto-pwa-backend.service: active; `http://127.0.0.1:8088/api/health` ok
- cto-a2a-registry.service: active
