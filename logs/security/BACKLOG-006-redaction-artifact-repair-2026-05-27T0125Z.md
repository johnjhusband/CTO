# BACKLOG-006 redaction artifact repair — 2026-05-27T01:25Z

## Selected item
P0 security / credential hygiene: continue safe non-destructive work on BACKLOG-006 before any lower-priority item.

## Pre-checks
- A2A2H per-tick drift check: no upstream-eligible CTO commits after `bebcd3953f2db3b876cf90ea5b4484630999db73`.
- User services: A2A registry, Hermes A2A sidecar, PWA backend, Hermes gateway, OpenClaw gateway, and work-pump timers were active.
- Recent failed verification: Hermes work-pump `agent_incomplete` is recorded separately under `logs/repairs/` and recovery restart cooldown was active.

## Action taken
- Ran credential rotation preflight. It printed credential names and service states only, confirmed `/opt/cto/.env` mode `600`, and reported `ready_for_coordinated_rotation_window`.
- Ran safe security gates. The operational redaction check failed on three URL-query-secret markers in `logs/repairs/pwa-legacy-stream-cache-clear-2026-05-27T0116Z.md`.
- Repaired that durable artifact by replacing legacy query-token URL examples with `<redacted-query-secret>` placeholders.
- Re-ran the full safe security gate suite successfully.
- Closed BACKLOG-018 as observably resolved because the A2A2H maintenance process/backfill/per-tick check are now durable and the current drift check is clean.

## Verification
- `scripts/security/rotation-preflight.sh`: passed, no secret values printed.
- `scripts/security/run-safe-security-gates.sh`: passed after repair.
  - Secret artifact guard scanned 293 source-visible files.
  - Operational redaction check scanned 156 files plus chat.db and found no unredacted markers.
  - Install secret-handling guard passed.
  - Credential rotation preflight syntax passed.
  - Redaction unit tests: 8/8 passed.
  - PWA auth/routing regression tests: 27/27 passed.
  - PWA voice UI regression tests: 1/1 passed.

## Remaining blocked work
BACKLOG-006 remains open for coordinated live credential rotation/revocation and any John-approved public history/log cleanup. Those steps can interrupt live services or rewrite public history, so this pump did not attempt them.
