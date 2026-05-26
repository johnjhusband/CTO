# BACKLOG-009/BACKLOG-013 safe token rotation grace — 2026-05-26T21:55Z

## Selected item
P0 PWA access-control/token-rotation safety. Live token rotation is still blocked on a secure delivery/device-confirmation path, but the previous failed rotation showed that all-or-nothing token replacement can either lock John out or force an unsafe rollback.

## Change made
- Added `PWA_AUTH_TOKEN_PREVIOUS` as an optional comma-separated grace list for the PWA backend.
- New sessions are still signed only with `PWA_AUTH_TOKEN`.
- Existing sessions signed by a previous token remain valid during a controlled rotation window.
- The `/login` bootstrap token check can accept the current token or a previous grace token, but API query-token access remains rejected by `_auth_ok()`.
- Production startup still fails closed if the current `PWA_AUTH_TOKEN` is blank; a previous-token grace value alone is not sufficient to start production.

## Why this is safe
This does not rotate or expose any secret. It only makes the next approved/confirmed rotation less brittle: deploy `PWA_AUTH_TOKEN=<new>` with `PWA_AUTH_TOKEN_PREVIOUS=<old>`, verify John can log in and background push still works, then remove the previous token after the confirmation window.

## Verification
```text
$ python3 -m unittest -v tests/test_pwa_routing.py
Ran 25 tests in 0.159s
OK

$ scripts/security/run-safe-security-gates.sh
Secret artifact guard passed.
Operational secret redaction check passed.
Redaction unit tests: 6/6 passed.
PWA auth/routing regression tests: 25/25 passed.
Safe security gates passed.

$ systemctl --user --no-pager is-active cto-pwa-backend.service cto-openclaw-work-pump.timer cto-hermes-work-pump.timer
active
active
active

$ systemctl --no-pager --failed
0 loaded units listed.
```

## Remaining
Actual live token rotation remains pending a secure delivery path and John/device confirmation. After successful confirmation, remove `PWA_AUTH_TOKEN_PREVIOUS` from the runtime environment so the grace window closes.
