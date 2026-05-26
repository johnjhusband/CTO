# PWA shell access-control hotfix — 2026-05-26 18:56 UTC pump

## Selected item
BACKLOG-013 / BACKLOG-006 overlap: P0 PWA access control and token-log hygiene.

## Finding
The earlier PWA repair protected chat APIs, but live verification showed `/` and `/index.html` were still listed as public GET routes. That meant an unauthenticated browser could still receive the chat shell HTML, even though API calls were rejected.

During restart verification, legacy clients still attempted `/api/stream?token=REDACTED the backend access logger was capable of writing query tokens into systemd journal output. No secret values are recorded in this artifact.

## Repair
- Removed `/` and `/index.html` from public GET routes.
- Kept root/index token bootstrap only through `_maybe_bootstrap_session()`, which exchanges a valid bootstrap token for a session cookie and redirects to a clean URL.
- Added access-log redaction for URL parameters named `token`, `access_token`, `auth`, or `key` before writing to stderr/systemd journal.
- Added regression tests for protected shell routes and query-token log redaction.
- Restarted `cto-pwa-backend.service` after the patch.

## Verification
- `python3 -m py_compile services/pwa/backend/server.py services/pwa/backend/job_runner.py`
- `python3 -m unittest tests/test_pwa_routing.py` → 15 tests OK
- Live local checks after restart:
  - `GET /` → 401 login page
  - `GET /index.html` → 401 login page
  - `GET /api/messages` → 401 JSON unauthorized
  - `GET /api/messages?token=<dummy>` → 401 JSON unauthorized
  - `GET /manifest.json` → 200 public static asset
  - `GET /api/health` → 200 health
- `systemctl --user is-active cto-pwa-backend.service` → active
- `journalctl --user -u cto-pwa-backend.service` contains `[REDACTED]` for query-token log entries after the hotfix.

## Remaining follow-up
- BACKLOG-013 remains `implemented_pending_token_rotation`: rotate the live PWA bootstrap token after John confirms device access.
- BACKLOG-006 remains open: historical logs and operational artifacts still need broader credential rotation/scrubbing review.
