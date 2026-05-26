# BACKLOG-009 Query-Token Auth Reconciliation — 2026-05-26T20:00Z

## Selected item
BACKLOG-009 (P0 security): replace URL query-token PWA auth with cookie/session auth and reduce token logging risk.

## Safe step completed
Reconciled BACKLOG-009 against the already-implemented PWA access-control work and reran the relevant non-destructive gates. This does not rotate the live PWA token or invalidate active devices.

## Evidence
- PWA APIs reject URL query-token auth.
- PWA shell `/` and `/index.html` are not public when auth is configured.
- Auth now uses signed session cookies; JavaScript does not store the bearer token.
- Legacy access logs redact query-token values.
- Operational redaction gate covers legacy URL query-token values in logs/chat artifacts.

## Verification
```text
$ python3 -m unittest -v tests/test_redact_operational_secrets.py tests/test_pwa_routing.py
Ran 22 tests in 0.112s
OK

$ scripts/security/run-safe-security-gates.sh
Secret artifact guard passed: scanned 223 source-visible files.
Operational secret redaction check passed: scanned 93 file(s) plus chat.db; no unredacted markers found.
Redaction unit tests: 4/4 passed.
PWA auth/routing regression tests: 18/18 passed.
Safe security gates passed.
```

## Status recommendation
BACKLOG-009 should move from `open` to `implemented_pending_token_rotation`. The remaining unsafe part is live token rotation/session invalidation, which overlaps BACKLOG-013 and BACKLOG-006 and should be coordinated to avoid locking John out or breaking the PWA.
