# BACKLOG-014 repair: PWA shell network-first update

- Timestamp: 2026-05-27T03:10Z
- Selected item: BACKLOG-014 / PWA improvements visibility and background delivery
- Status: advanced; remains open pending John/device confirmation of phone background notification behavior

## Why

John reported from the PWA that none of his feature requests were visible. Recent UI work had shipped visible controls, but the service worker was still cache-first for the app shell. An installed phone PWA could therefore keep serving old cached HTML/JS and hide new UI until a manual cache purge or repeated reloads.

## Repair

- Changed `services/pwa/frontend/service-worker.js` from cache-first to network-first for navigations and shell assets.
- Kept `/api/*` and `/chat-log/*` network-only so private data/history never come from stale cache.
- Bumped `SHELL_CACHE` from `cto-shell-v11` to `cto-shell-v12`.
- Updated regression assertions in `tests/test_pwa_routing.py` and `tests/test_pwa_voice_ui.py`.
- Ported the same generic repair to `/opt/a2a2h/services/pwa/frontend/service-worker.js` with `a2a2h-shell-v12`.

## Verification

- `python3 -m unittest tests.test_pwa_routing tests.test_pwa_voice_ui tests.test_redact_operational_secrets` → 38 tests passed.
- Live local static check: `curl -fsS http://127.0.0.1:8088/service-worker.js` shows `cto-shell-v12`, `/chat-log/` network-only, and network-first shell handling.
- A2A2H syntax check: `python3 -c "import ast; ast.parse(open('services/pwa/backend/server.py').read())"` passed.
- A2A2H CTO-specific grep over `services/ scripts/` remains clean for `/opt/cto` and `husband.llc`; the only `cto` hits are historical naming references already present outside this patch.

## Notes

This does not claim device-level push display is confirmed. It removes a concrete cache trap that could make completed PWA improvements invisible on John's installed PWA.
