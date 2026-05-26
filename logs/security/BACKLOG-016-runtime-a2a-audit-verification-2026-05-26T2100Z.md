# BACKLOG-016 runtime A2A coordination audit verification — 2026-05-26T21:00Z

## Selection
Continuous work pump selected BACKLOG-016 after the P0 credential/VAPID rotation items because those live-secret rotations, subscription invalidation, and public-history cleanup remain coordinated approval-window work. BACKLOG-016 was already implemented and safe to verify against the local live PWA backend.

## Context checked
- `/opt/cto/wiki/continuous-work-policy.md`
- `/opt/cto/HEARTBEAT.md`
- `/opt/cto/BACKLOG.md` and `logs/backlog/BACKLOG-016.json`
- Recent PWA chat context in `logs/pwa-chat/2026-05-26.md`
- Git status: clean against `origin/master` before this artifact/update
- Services: `cto-pwa-backend`, `cto-hermes-a2a-sidecar`, `openclaw-gateway`, and `hermes-gateway` active
- Recent failed verification: clone install failures remain historical; no fresh failed verification artifact blocked this item

## Runtime verification
Performed through the live local PWA backend on `127.0.0.1:8088` after the backend restart at 20:54Z. The PWA auth token was read from `/opt/cto/.env` but not printed or stored in this artifact.

Results:
- `POST /api/login` with the configured PWA token returned `303` and issued a session cookie.
- Authenticated `POST /api/messages` with `@hermes audit-ping` returned `202` and target `hermes`.
- `chat.db` recorded sanitized `a2a_request` rows for correlation `94a55968-2fb2-4c5b-8981-8deb33fe713d`.
- Hermes completed and `chat.db` recorded `a2a_response` rows for the same correlation.
- Authenticated `GET /api/messages?since_id=1145` returned those A2A rows to the PWA API, proving the existing A2A/JSON transcript toggles can render them.
- The inspected A2A row content did not contain raw `Authorization` or `Bearer` header text.

Observed implementation note: each request/response is currently represented twice, once from the PWA wrapper and once from the A2A sidecar/session path. This is acceptable for audit visibility but should be deduplicated or labelled if John wants a cleaner UX panel.

## Regression gate
- `python3 -m unittest -v tests/test_pwa_routing.py` — 20 tests OK.
- `scripts/security/run-safe-security-gates.sh` — passed (secret artifact guard, operational redaction check, redaction tests, PWA auth/routing tests).

## Result
BACKLOG-016 is runtime-verified and can leave the active P0 queue. Remaining work, if desired, is UX polish/deduplication rather than the capability gap itself.
