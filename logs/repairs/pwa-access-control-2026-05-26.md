# PWA access-control repair — 2026-05-26

## Problem
John reported that knowing the PWA chat URL was enough to reach the CTO control room. BACKLOG-013 tracks this as P0.

## Change
The PWA backend now requires a signed, time-limited, HttpOnly, Secure, SameSite=Strict session cookie for the chat shell and chat APIs. The cookie value is an HMAC-signed session envelope, not the bearer token itself. `/api/messages`, `/api/stream`, and push subscription APIs no longer accept `?token=` query authentication. Unauthenticated browser access to `/` or `/index.html` receives a login form instead of the chat shell.

For migration, the existing `?token=` bootstrap is restricted to `/` and `/index.html`; it immediately exchanges the token for a session cookie and redirects to a clean URL. API endpoints do not accept URL tokens.

## Verification
- `python3 -m py_compile services/pwa/backend/server.py services/pwa/backend/job_runner.py`
- `python3 -m unittest tests/test_pwa_routing.py`

## Remaining follow-up
Rotate the live PWA token after John confirms access from his device, so old shared URLs become useless even if someone copied the token before this repair.
