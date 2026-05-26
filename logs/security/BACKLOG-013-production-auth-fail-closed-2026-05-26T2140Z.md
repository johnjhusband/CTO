# BACKLOG-013 production auth fail-closed repair — 2026-05-26T21:40Z

## Selected item
P0 PWA access-control hardening after the 21:32Z emergency restore showed a failed token-rotation path could leave `PWA_AUTH_TOKEN` blank and put the live backend in dev/no-auth mode.

## Why this was selected
BACKLOG-009/BACKLOG-013 remain P0 and live token rotation is blocked on a safe delivery path. The highest-priority safe substep was to prevent recurrence of the observed no-auth production startup state without rotating or exposing any secret value.

## Repair
- `services/pwa/backend/server.py` now fails closed at startup when `CTO_INSTANCE_ID` is production/prod and `PWA_AUTH_TOKEN` is blank.
- `_auth_ok()` no longer treats a blank token as authenticated in production; no-token dev mode is limited to non-production instances or explicit `PWA_ALLOW_DEV_NO_AUTH=1`.
- Added regression coverage in `tests/test_pwa_routing.py` for production fail-closed behavior and non-production dev-mode behavior.

## Verification
```text
$ python3 -m unittest -v tests/test_pwa_routing.py
Ran 22 tests in 0.130s
OK

$ python3 - <<'PY'
# production import with blank PWA_AUTH_TOKEN, then inspect startup guard
print(server._pwa_auth_startup_error())
PY
PWA_AUTH_TOKEN is required for production PWA backend startup

$ scripts/security/run-safe-security-gates.sh
Secret artifact guard passed.
Operational secret redaction check passed.
Redaction unit tests: 6/6 passed.
PWA auth/routing regression tests: 22/22 passed.
Safe security gates passed.

$ systemctl --user --no-pager is-active cto-pwa-backend.service cto-openclaw-work-pump.timer cto-hermes-work-pump.timer
active
active
active
```

## Result
The live backend remains active with its restored non-empty token, and future production restarts cannot silently enter no-auth/dev mode if token rotation or env editing blanks `PWA_AUTH_TOKEN`. No token, cookie, bootstrap URL, or secret value was printed or stored.

## Remaining
Live token rotation still requires a safe delivery path and John/device confirmation. This repair only closes the blank-token/no-auth regression path.
