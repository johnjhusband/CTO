# BACKLOG-013/BACKLOG-009 PWA token-rotation grace repair — 2026-05-26T21:56Z

## Selected item
P0 security/access-control: make the live PWA token rotation path safer after the previous attempt was rolled back to avoid locking John out.

## Why this was selected
Recent PWA chat showed John requested rotation. Full live token rotation was unsafe because the configured SMTP delivery path failed, and delivering a new login token through chat/logged channels would create credential exposure. The safe substep was to reduce lockout risk before the next rotation attempt.

## Repair
- `services/pwa/backend/server.py` now supports optional `previous-token grace env var` as a comma-separated grace list.
- `current-token env var` remains the current signer for newly issued sessions.
- Existing session cookies and previous login token values can remain valid during a controlled rotation window when the previous token is configured in the grace list.
- Startup still fails closed in production if no current or previous PWA auth token is configured.

## Verification
```text
python3 -m unittest -v tests/test_pwa_routing.py
Ran 23 tests in 0.124s — OK

scripts/security/run-safe-security-gates.sh
Secret artifact guard passed.
Operational secret redaction check passed.
Redaction unit tests: 6/6 passed.
PWA auth/routing regression tests: 23/23 passed.
Safe security gates passed.

systemctl --user restart cto-pwa-backend.service
systemctl --user is-active cto-pwa-backend.service => active
GET / => 401
GET /api/messages => 401
GET /api/messages with legacy query-token shape => 401
```

## Result
The deployed PWA backend now has a safer rotation mechanism that can keep John's existing session/auth path valid while a new token is introduced and confirmed. No token, bootstrap URL, cookie value, or credential value was changed, printed, or stored.

## Remaining
Actual live token rotation still requires a secure delivery/confirmation path for John and a later cleanup step to remove `previous-token grace env var` after the grace window.
