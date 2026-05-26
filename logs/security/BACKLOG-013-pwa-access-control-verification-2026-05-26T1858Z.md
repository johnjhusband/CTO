# BACKLOG-013 PWA Access-Control Verification — 2026-05-26T18:58Z

## Scope
Verified the implemented P0 PWA chat access-control regression coverage for BACKLOG-013.

## Result
PASS for local regression suite using the available Python unittest runner.

## Evidence
- `python3 -m pytest -q tests/test_pwa_routing.py` could not run because `pytest` is not installed in this environment.
- Fallback gate run: `python3 -m unittest -v tests/test_pwa_routing.py`
- Outcome: 15 tests ran, all passed.

## Security checks covered by this gate
- PWA shell `/` and `/index.html` are not public when `PWA_AUTH_TOKEN` is configured.
- API query-token authentication is rejected.
- Session cookie authentication succeeds.
- Session cookie does not store the bearer token.
- Legacy URL query tokens are redacted from access logs.

## Remaining blocker
Live token/credential rotation remains outside this verification and is still tracked separately by the P0 credential-rotation backlog items.
