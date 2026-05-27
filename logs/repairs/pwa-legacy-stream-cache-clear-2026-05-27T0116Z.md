# PWA legacy stream retry mitigation — 2026-05-27T01:16Z

## Selected item
P0 access-control / human-interface reliability follow-up: recent service logs showed a stale mobile/PWA client repeatedly requesting the retired `/api/stream?token=...` URL. The endpoint already returned 204 and did not authenticate query tokens, but the retry storm persisted.

## Action taken
- Added `Clear-Site-Data: "cache"` to the 204 response for legacy `/api/stream?token=...` requests.
- Kept the behavior non-destructive: clears only browser cache, not cookies, storage, server-side state, or subscriptions.
- Added regression coverage asserting the cache-clear header is present on the legacy 204 response.
- Ported the same one-line runtime behavior to A2A2H and updated `wiki/A2A2H_LAST_SYNC.md`.

## Verification
- `scripts/security/run-safe-security-gates.sh` passed: secret artifact guard, operational redaction check, install guard, rotation preflight syntax, 8 redaction tests, 27 PWA auth/routing tests, and 1 PWA voice UI test.
- Restarted `cto-pwa-backend.service`; service is active.
- Runtime probe of `http://127.0.0.1:8088/api/stream?token=legacy-client` returned `204 No Content`, `Cache-Control: no-store`, `Clear-Site-Data: "cache"`, and an empty body.
- A2A2H port commit: `a72c2cdc7ea5b4c8a193c828b113ec4273497a33`.
- CTO source commit: `bebcd3953f2db3b876cf90ea5b4484630999db73`.

## Status
Advanced one safe item. No credential values were printed, no live credential rotation/revocation was attempted, and no destructive history rewrite was performed.
