# BACKLOG-006 safe gates after PWA shell update — 2026-05-27T03:15Z

## Selected item
P0 security/access-control follow-up. Recent work changed the PWA shell/service-worker update path, so I re-ran the full safe credential and access-control gate suite before moving to lower-priority items.

## State checked
- Git/A2A2H drift: no upstream-eligible CTO drift after tracker SHA `2a929758804d6f0c005e0182662ff3539e265b67`; A2A2H was already synced.
- Open/pending backlog scan: BACKLOG-005 and BACKLOG-006 still require coordinated destructive/credential-rotation windows; no P0 item had enough on-disk evidence for closure without John/device confirmation or unsafe action.
- Services: OpenClaw gateway, PWA backend, Hermes gateway, and Hermes A2A sidecar were active; user failed units count was zero.
- Recent degraded signal: Hermes provider-side `agent_incomplete` continues, captured separately in repair artifacts.

## Verification
Ran `scripts/security/run-safe-security-gates.sh` successfully. Passed gates:

- Secret artifact guard: scanned 318 source-visible files.
- Operational secret redaction: scanned 178 files plus `chat.db`; no unredacted markers found.
- Install secret-handling guard.
- Credential rotation preflight syntax and rotation smoke syntax.
- Credential rotation preflight runtime check: required credential names present/nonempty; `/opt/cto/.env` owner `cto:cto`, mode `600`; dependent services active; result `ready_for_coordinated_rotation_window`.
- Credential rotation smoke check: local health endpoints OK for OpenClaw Gateway, Hermes Gateway, Hermes A2A sidecar, and PWA backend.
- Redaction tests: 8/8.
- PWA auth/routing tests: 29/29.
- PWA voice UI test: 1/1.

## Status
BACKLOG-006 remains open. Safe non-destructive gates are green after the PWA shell update, but closure still requires a coordinated live credential rotation/revocation window and any approved broader history/log cleanup. No secret values, request headers, or raw tool traces were recorded.
