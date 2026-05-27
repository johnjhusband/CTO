# BACKLOG-006 safe credential/security gates — 2026-05-27T14:27Z

## Selected item
BACKLOG-006 — rotate live service credentials and remove secret values from operational logs/history.

This was the highest-priority safe OpenClaw-owned item this tick. The destructive parts of BACKLOG-005/BACKLOG-006 still require a coordinated John-approved window, so this tick advanced the non-destructive credential/security verification path.

## Mandatory pre-checks
- A2A2H per-tick upstream-port check: no upstream-eligible CTO commits since `353253a7366345676d06c775bdcd5c7f9d61daf7`; no port required.
- Backlog completion scan: no open/pending item was safely closable from disk evidence alone. BACKLOG-004 and BACKLOG-014 still require John/device-visible confirmation; BACKLOG-005 remains pending coordinated history scrub/risk acceptance; BACKLOG-006 remains pending coordinated live credential rotation/revocation.
- Hermes provider circuit: `/opt/cto/.cache/hermes-work-pump-provider-failure.json` remains open for `agent_incomplete_provider_NoneType`, so no semantic Hermes delegation was attempted.

## Verification performed
Ran:

```bash
bash scripts/security/run-safe-security-gates.sh
```

Result: passed.

Passed checks:
- Secret artifact guard: scanned 449 source-visible files.
- Operational secret redaction check: scanned 301 files plus `chat.db`; no unredacted markers found.
- Install secret-handling guard.
- Credential rotation preflight syntax and runtime names/status-only check; result `ready_for_coordinated_rotation_window`.
- Credential rotation smoke syntax and local service health check; result `local_services_healthy`.
- Redaction unit tests: 9/9.
- PWA auth/routing regression tests: 38/38.
- PWA voice UI regression tests: 1/1.

## Service health observed
User services were active: `cto-a2a-registry`, `cto-hermes-a2a-sidecar`, `cto-pwa-backend`, `hermes-gateway`, and `openclaw-gateway`.

Hermes transport services are up, but Hermes semantic agent calls are still failing at the provider/adapter layer with sanitized `NoneType` / `agent_incomplete` evidence in recent logs.

## Status
BACKLOG-006 remains open. Full closure still requires a coordinated live credential rotation/revocation window and approved broader cleanup/history action. No credentials were read, printed, rotated, revoked, or changed in this tick.
