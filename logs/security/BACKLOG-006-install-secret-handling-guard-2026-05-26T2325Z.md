# BACKLOG-006 — install secret-handling guard

Timestamp: 2026-05-26T23:25Z

## Selected item
P0 credential hygiene / BACKLOG-006.

## Why selected
The work-pump priority order puts P0 security/access-control first. Full live credential rotation and public-history cleanup remain coordinated-window work, but the clone installer has been the active safe sub-surface for credential-hygiene hardening. Recent repairs removed several exposure paths; this tick made those expectations durable so they do not regress.

## Change
- Added `scripts/security/check-install-secret-handling.sh`.
- The guard checks `scripts/install.sh` metadata only and does not print secret values.
- It fails on token-bearing authorization headers in `curl` argv, secret variables embedded in URLs/query strings, temporary local `.env` writes, direct shell emission of secret variables outside the short-lived `GIT_ASKPASS` helper, missing restrictive remote `.env` streaming, or missing `GIT_ASKPASS` clone behavior.
- Added the guard to `scripts/security/run-safe-security-gates.sh`.

## Verification
- `bash -n scripts/security/check-install-secret-handling.sh scripts/security/run-safe-security-gates.sh` passed.
- `scripts/security/check-install-secret-handling.sh` passed.
- `scripts/security/run-safe-security-gates.sh` passed:
  - Secret artifact guard scanned 266 source-visible files.
  - Operational secret redaction check scanned 132 files plus chat.db.
  - Install secret-handling guard passed.
  - Redaction unit tests passed: 6 tests.
  - PWA auth/routing regression tests passed: 26 tests.

## Remaining
BACKLOG-006 remains open for staged live credential rotation and broader history/log cleanup. This tick only converted prior clone/install credential-handling assumptions into a reusable no-spend regression gate.

Secrets: none recorded.
