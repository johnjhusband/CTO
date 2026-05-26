# PWA chat auth repair — 2026-05-25

## What changed
- Replaced JavaScript/localStorage Bearer-token auth with a Secure/HttpOnly same-origin session cookie.
- Kept the private `?token=REDACTED URL only as a one-time bootstrap on `/` or `/index.html`; the backend exchanges it for a cookie and redirects to a clean URL.
- API endpoints no longer accept URL query tokens, including `/api/messages` and `/api/stream`.

## Root cause
The original PWA treated the private URL token as an API credential: the frontend stored it in localStorage, sent it as a Bearer header, and EventSource passed it back as `/api/stream?token=REDACTED That meant URL knowledge or token leakage was enough to access chat history.

## Verification
- `python3 -m py_compile /opt/cto/services/pwa/backend/server.py`
- `curl -sk -i https://cto.husband.llc/api/messages | head -1` returns `HTTP/2 401` without a session cookie.
- `curl -sk -i "https://cto.husband.llc/api/messages?token=REDACTED" | head -1` returns `HTTP/2 401`, proving API query-token auth is closed.
- `curl -sk -i "https://cto.husband.llc/?token=REDACTED"` returns `303` with `Set-Cookie: cto_pwa_session=...; HttpOnly; Secure; SameSite=Strict`.

## Rollback
Revert the commit `pwa: replace URL token auth with session cookie gate` and restart `cto-pwa-backend.service` if browser login breaks unexpectedly.
