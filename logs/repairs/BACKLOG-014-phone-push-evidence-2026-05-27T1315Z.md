# BACKLOG-014 phone push evidence tick — 2026-05-27T13:15Z

## Scope
Advanced BACKLOG-014 (PWA background delivery / visible phone push readiness) without external risk or Hermes delegation.

## Required pre-checks
- A2A2H per-tick upstream-port check: clean. Tracker SHA `ff51e4440f2150c4596f50d71d802dbee4fce7e6`; no upstream-eligible CTO commits under `services/pwa`, `services/hermes_a2a_sidecar`, `services/a2a_delegate`, `scripts/cache-keepalive.sh`, or `services/chat/db.py`.
- Hermes provider circuit: open (`agent_incomplete_provider_NoneType`), so no semantic Hermes delegation was attempted.
- Completed-backlog scan: no P0/PWA phone-visible items were closed because BACKLOG-014/016/017 are explicitly pending John phone verification; BACKLOG-005/006 require coordinated rotation/history-scrub windows.

## New evidence from John's PWA
Recent chat.db device events show the phone/browser push path is wired through provider submission:
- `2026-05-27T13:08:16Z` `push_subscribed`: FCM endpoint host recorded, full endpoint omitted here.
- `2026-05-27T13:08:16Z` `push_self_test`: `attempted=3`, `failed=0`.
- `2026-05-27T13:08:16Z` `push_device_status`: Notification/ServiceWorker/Push supported, `permission=granted`, `subscribed=true`, `after_test=true`, `test_attempted=3`, `test_failed=0`, platform `Linux armv81`.
- `2026-05-27T13:08:43Z` later manual status from a context reported `permission=default`, `subscribed=false`, so device/browser context is mixed and this is not safe to close without John confirming the actual notification display.

## Verification run
- `python3 -m unittest -v tests/test_pwa_routing.py tests/test_pwa_voice_ui.py` — 39/39 passed.
- `node --check services/pwa/frontend/app.js` — passed.
- Backend AST parse for `services/pwa/backend/server.py` — passed.
- `curl -fsS http://127.0.0.1:8088/api/health` — `{"status":"ok","service":"pwa-backend"}`.

## Result
BACKLOG-014 is advanced with concrete phone-side evidence and remains open pending John's confirmation that the phone displayed the background notification.
