# PWA chat log export repair — 2026-05-26

## Selected item
BACKLOG-017 P0: durable, human-readable PWA chat history and foreground resync.

## Why this item
John reported losing PWA context when the app is backgrounded. chat.db persists the messages, but the browser UI can miss SSE deliveries after iOS/Android backgrounding and there was no plain-text review surface outside the live PWA.

## Repair
- Added best-effort daily markdown mirroring in `services/chat/db.py`.
  - Writes `/opt/cto/logs/pwa-chat/YYYY-MM-DD.md`.
  - Includes UTC timestamp, sender/recipient, kind, row id, and human-readable content.
  - Omits structured `a2a_*` JSON rows by default.
  - Never blocks chat delivery if log writing fails.
- Added authenticated backend review/export routes in `services/pwa/backend/server.py`.
  - `/chat-log/` lists available daily logs.
  - `/chat-log/YYYY-MM-DD.md` serves one UTC day.
  - `/api/chat/export?from=YYYY-MM-DD&to=YYYY-MM-DD` downloads a bounded markdown range (max 31 days).
  - Routes are gated by the same PWA session-cookie auth as `/api/messages`.
- Added frontend foreground recovery in `services/pwa/frontend/app.js`.
  - On `visibilitychange` back to visible and on `focus`, the UI reloads full history from `/api/messages?since_id=0` and replaces the DOM so missed background messages appear.
- Added `logs/pwa-chat/` to `.gitignore` so durable local chat logs are not committed.
- Expanded/used the operational redaction gate to redact legacy URL query-token values from existing repair notes.
- Backfilled existing `chat.db` human-readable rows into `/opt/cto/logs/pwa-chat/` so the review surface is useful immediately.

## Verification
- `python3 -m unittest -v tests/test_pwa_routing.py` — 18 tests OK.
- `python3 -m py_compile services/chat/db.py services/pwa/backend/server.py` — OK.
- `scripts/security/check-secret-artifacts.sh` — passed, scanned 221 source-visible files.
- `scripts/security/redact-operational-secrets.py --check` — passed after redacting 7 pre-existing legacy query-token markers from repair notes.
- Backfill result: 569 human-readable rows written into 6 daily markdown logs under `/opt/cto/logs/pwa-chat/` (gitignored, local runtime artifact).

## Remaining blocker
Runtime mobile verification is still needed on John's iOS Safari/standalone PWA path after deployment/restart: background the app, send messages while backgrounded, foreground it, confirm history reloads, then open `/chat-log/YYYY-MM-DD.md` from the same authenticated browser session.
