# BACKLOG-006 safe substep — auth-header/session-cookie redaction coverage

Timestamp: 2026-05-26T20:20Z

## Selected item
BACKLOG-006 P0 security/access-control: rotate live service credentials and remove secret values from operational logs/history.

## Safe advancement
The full fix still requires a coordinated credential-rotation/history-cleanup window. This tick advanced the safe local substep: expand the operational redaction gate so future logs/chat rows redact HTTP bearer authorization header values and PWA session cookie values without printing the values.

## Changes
- Updated `scripts/security/redact-operational-secrets.py` to preserve header/cookie names while redacting values.
- Added regression coverage in `tests/test_redact_operational_secrets.py`.
- Applied the redactor to existing operational artifacts and chat storage; it redacted 3 marker instances by path/row metadata only:
  - `logs/repairs/pwa-chat-auth-2026-05-25.md` — `pwa_session_cookie:1`
  - `logs/decisions/CTO-DECISION-015.json` — `authorization_bearer:1`
  - `chat.db` row 852 — `pwa_session_cookie:1`

## Verification
- `python3 -m unittest -v tests/test_redact_operational_secrets.py` — 6 tests passed.
- `scripts/security/redact-operational-secrets.py --check` — passed after apply; scanned 98 files plus chat.db with no unredacted markers found.
- `scripts/security/run-safe-security-gates.sh` — passed: secret artifact guard scanned 229 source-visible files; operational redaction check passed; redaction tests passed; PWA auth/routing tests passed.

## Remaining blocked work
Live credential rotation, public-history scrub/rewrites, and any revocation that could break production access remain coordinated security-window work and were not performed in this unattended pump tick.
