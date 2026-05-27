# BACKLOG-006 safe gates after Hermes visible-alert repair — 2026-05-27T04:00Z

## Selected item
P0 security/access-control: BACKLOG-006 credential hygiene remains the highest safe item because live credential rotation/revocation is still blocked on a coordinated window, but non-destructive gates can continue to verify that recent PWA/Hermes-visible-alert changes did not regress secret handling.

## Context inspected
- Recent PWA chat showed John’s latest manual test was answered by OpenClaw, while Hermes A2A/work-pump calls still return sanitized `agent_incomplete` / `NoneType` errors.
- `git status` was clean and synced before this tick.
- `systemctl --user --failed` reported 0 failed units.
- OpenClaw gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers were active.
- A2A2H upstream-port check showed no drift since CTO commit `12539b7c4dcd2f21f06d4e2bd7e9d84db627aceb`; A2A2H was clean and synced.
- Open/pending backlog scan found no item safe to close: BACKLOG-004/014/016 still require John/device confirmation; BACKLOG-005 requires a coordinated destructive public-history rewrite or risk acceptance; BACKLOG-006 requires coordinated live rotation/revocation.

## Verification performed
Ran `scripts/security/run-safe-security-gates.sh` after the Hermes visible-alert repair. The suite passed end-to-end:

- Secret artifact guard: scanned 326 source-visible files.
- Operational secret redaction: scanned 186 files plus `chat.db`; no unredacted markers found.
- Install secret-handling guard.
- Credential rotation preflight syntax.
- Credential rotation smoke syntax.
- Names-only credential preflight: required credential names present/non-empty; `/opt/cto/.env` owner/mode OK; dependent services active; result `ready_for_coordinated_rotation_window`.
- Rotation smoke check: local health endpoints OK for OpenClaw Gateway, Hermes Gateway, Hermes A2A sidecar, and PWA backend; result `local_services_healthy`.
- Redaction unit tests: 8/8 passed.
- PWA auth/routing regression tests: 29/29 passed.
- PWA voice UI regression test: 1/1 passed.

## Result
Safe non-destructive credential-hygiene gates remain green after the Hermes visible-alert change. BACKLOG-006 remains open because final remediation requires a coordinated live credential rotation/revocation window and any approved broader log/history cleanup. No secret values, raw request headers, bearer tokens, or raw provider traces were recorded.
