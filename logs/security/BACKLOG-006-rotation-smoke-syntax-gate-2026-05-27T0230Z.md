# BACKLOG-006 rotation smoke syntax gate — 2026-05-27T02:30Z

## Selected item
P0 credential hygiene / access-control. The previous tick added the non-destructive rotation smoke gate; this tick hardened the recurring gate so syntax errors in that new script fail before runtime execution.

## Action taken
- Added `bash -n scripts/security/rotation-smoke.sh` to `scripts/security/run-safe-security-gates.sh`.
- No credentials were printed, rotated, revoked, or written.
- No services were restarted and no live config was mutated.

## Verification
Ran `scripts/security/run-safe-security-gates.sh` after the change. It passed:
- secret artifact guard;
- operational redaction check across logs plus `chat.db`;
- install secret-handling guard;
- credential rotation preflight syntax;
- credential rotation smoke syntax;
- credential rotation preflight runtime names/status-only check;
- credential rotation smoke local-service health check;
- 8 redaction tests;
- 28 PWA auth/routing tests;
- 1 PWA voice UI test.

## Status
BACKLOG-006 advanced safely. Full closure remains blocked on the coordinated live credential replacement/revocation window and approved broader history/log cleanup.
