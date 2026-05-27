# BACKLOG-006 redaction coverage hardening — 2026-05-27T00:25Z

## Selected item
BACKLOG-006 (P0 security): rotate live service credentials and remove secret values from operational logs/history.

## Work completed
- Advanced the safe, non-destructive credential-hygiene track; no live credential rotation, history rewrite, or external provider action was attempted.
- Expanded `scripts/security/redact-operational-secrets.py` so operational log/chat redaction now covers:
  - adjacent URL credential query names: URL credential parameter names for access tokens, auth tokens, API keys, and generic keys, in addition to the legacy token parameter;
  - sensitive HTTP headers such as `X-API-Key`, `X-Auth-Token`, `X-Hermes-Token`, `HCloud-Token`, and `GH-Token`;
  - generic session and sid cookie names in addition to the CTO PWA session cookie.
- Added regression tests proving the new patterns redact values while preserving diagnostic names and never asserting or printing secret values.

## Verification
- `python3 -m unittest -v tests/test_redact_operational_secrets.py` — passed (8/8)
- `scripts/security/redact-operational-secrets.py --check` — passed; scanned 144 log files plus chat.db with no unredacted markers found
- `scripts/security/run-safe-security-gates.sh` — passed, including source-visible secret artifact guard, install secret-handling guard, redaction tests, PWA auth/routing tests, and PWA voice UI test
- A2A2H per-tick drift check: `git log 5d3dbc0..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py` returned no upstream-eligible commits.

## Remaining blocker
Full BACKLOG-006 closure still requires a coordinated live credential rotation/revocation window and any broader history/log cleanup John approves. This tick intentionally stayed within safe local redaction hardening.
