# BACKLOG-006 chat.db redaction repair — 2026-05-27T14:13Z

## Required pre-checks
- A2A2H upstream-port check: clean; `git log 353253a7366345676d06c775bdcd5c7f9d61daf7..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no commits.
- Hermes provider state: degraded (`agent_incomplete_provider_NoneType`); no semantic Hermes delegation attempted this tick.
- Backlog completion scan: P0 BACKLOG-004/014/016/017 remain pending John phone-visible confirmation; BACKLOG-005 remains blocked on coordinated public-history rewrite/risk acceptance; BACKLOG-006 remains open pending coordinated live credential rotation/revocation.

## Repair
- Ran `scripts/security/redact-operational-secrets.py --apply` after the recurring safe gate found two unredacted `PWA_AUTH_TOKEN` assignment-shaped values in chat.db A2A request rows 1535 and 1538.
- Redaction output reported row IDs and marker names only; no secret values were printed or stored.
- No runtime credentials, services, frontend files, infrastructure, or git history were changed.

## Verification
- `scripts/security/run-safe-security-gates.sh` passed after the repair:
  - secret artifact guard passed
  - operational redaction check passed across logs plus chat.db
  - install secret-handling guard passed
  - credential preflight and smoke checks reported names/status only and local services healthy
  - redaction unit tests passed 8/8
  - PWA auth/routing regression tests passed 38/38
  - PWA voice UI regression test passed 1/1

## Conclusion
The immediate P0 safe-gate failure is repaired. BACKLOG-006 remains open for the coordinated live credential rotation/revocation window and approved broader cleanup.
