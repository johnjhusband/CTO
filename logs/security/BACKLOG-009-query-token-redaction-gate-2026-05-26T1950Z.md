# BACKLOG-009 Query-Token Redaction Gate — 2026-05-26T19:50Z

## Selected item
P0 security/access-control: BACKLOG-009 tracks replacing URL query-token PWA auth and reducing token logging risk. Cookie/session auth and API query-token rejection already existed; this tick advanced the safe redaction/verification layer for legacy query-token artifacts.

## Safe step completed
Expanded `scripts/security/redact-operational-secrets.py` so operational logs and chat rows redact legacy PWA URL query token values while preserving only the parameter marker and replacing the value with `REDACTED`.

## Code changes
- `scripts/security/redact-operational-secrets.py` now records `url_query_token` markers and preserves only the parameter name plus `REDACTED`.
- `tests/test_redact_operational_secrets.py` now covers plain and URL-encoded legacy query-token redaction and asserts original token values do not remain in output.

## Verification
```text
$ python3 -m unittest -v tests/test_redact_operational_secrets.py
Ran 4 tests in 0.000s
OK

$ scripts/security/redact-operational-secrets.py --check
Operational secret redaction check passed: scanned 85 file(s) plus chat.db; no unredacted markers found.

$ scripts/security/run-safe-security-gates.sh
Secret artifact guard passed: scanned 221 source-visible files.
Operational secret redaction check passed: scanned 85 file(s) plus chat.db; no unredacted markers found.
Redaction unit tests: 4/4 passed.
PWA auth/routing regression tests: 18/18 passed.
Safe security gates passed.
```

## Remaining BACKLOG-009 work
Full retirement of URL-token bootstrap, token rotation, and any public history/log scrub remain coordinated security-window work. This tick did not rotate secrets, rewrite history, or alter live PWA auth configuration.
