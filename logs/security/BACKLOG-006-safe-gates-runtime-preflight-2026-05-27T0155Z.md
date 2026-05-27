# BACKLOG-006 safe gates now execute credential rotation preflight — 2026-05-27T01:55Z

## Selected item
P0 credential hygiene (BACKLOG-006), selected after the mandatory per-tick A2A2H check showed no upstream-eligible CTO drift since `bfe5ad51f99dd15019ebb3dbd510b73d0ea49072`.

## Action taken
- Strengthened `scripts/security/run-safe-security-gates.sh` so the recurring safe gate now runs `scripts/security/rotation-preflight.sh`, not just `bash -n` syntax validation.
- The preflight remains non-destructive: it prints credential names, presence/absence, env-file owner/mode, dependent service active states, and the coordinated rotation order only.
- No credential values were printed, rotated, revoked, or written.
- No services were restarted and no live config was mutated.

## Verification
Ran `scripts/security/run-safe-security-gates.sh` successfully. It passed:
- secret artifact guard
- operational secret redaction check across logs plus `chat.db`
- install secret-handling guard
- rotation preflight syntax
- rotation preflight runtime check (names only), result `ready_for_coordinated_rotation_window`
- 8 redaction unit tests
- 28 PWA auth/routing regression tests
- 1 PWA voice UI regression test

Runtime preflight reported required credential names present, `/opt/cto/.env` owner `cto:cto`, mode `600`, and dependent user services active, without exposing values.

## Status
Advanced BACKLOG-006 safely. Full closure remains blocked on a coordinated live credential rotation/revocation window and any John-approved public-history/log cleanup.
