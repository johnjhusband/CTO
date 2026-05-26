# BACKLOG-017 runtime chat-log verification — 2026-05-26T20:40Z

## Selection
Continuous work pump selected BACKLOG-017 because the open P0 security rotations (BACKLOG-005/BACKLOG-006 and token/password rotation work) touch live credentials, push identity, subscriptions, or destructive public-history cleanup and should not be silently performed in an unattended tick. BACKLOG-017 was the highest-priority safe item with an implemented feature still pending runtime verification.

## Context checked
- Policy: `/opt/cto/wiki/continuous-work-policy.md` queue order and stop conditions.
- Heartbeat: `/opt/cto/HEARTBEAT.md` OpenClaw work-pump requirements.
- Backlog: `/opt/cto/BACKLOG.md` and `logs/backlog/BACKLOG-017.json`.
- Recent PWA chat: `/opt/cto/logs/pwa-chat/2026-05-26.md` showed John's PWA context-loss request and later scheduler/work-pump work.
- Git: clean at start, `HEAD` matched `origin/master`.
- Services: `cto-a2a-registry`, `cto-hermes-a2a-sidecar`, `cto-pwa-backend`, `hermes-gateway`, and `openclaw-gateway` active; ports 8642 and 18789 loopback-only, HTTP/HTTPS public.
- Recent failed verification: only historical clone install-failure logs were present; no new `*failed*` verification artifacts under `logs/`.

## Runtime endpoint verification
Performed against live local PWA backend on `127.0.0.1:8088`, using a temporary cookie jar. The access token was sourced from `/opt/cto/.env` but was not printed or written to this artifact.

Results:
- `GET /chat-log/` without session cookie: `401`.
- `GET /api/chat/export?from=2026-05-26&to=2026-05-26` without session cookie: `401`.
- `POST /api/login` with configured token: `303` and session cookie issued.
- `GET /chat-log/` with session cookie: `200`, page includes `2026-05-26`.
- `GET /chat-log/2026-05-26.md` with session cookie: `200`, markdown header present.
- `GET /api/chat/export?from=2026-05-26&to=2026-05-26` with session cookie: `200`, `Content-Type: text/markdown; charset=utf-8`, export header present.
- `GET /chat-log/../../.env` with session cookie: `404`; traversal did not expose files.

## Regression gate
- `python3 -m unittest -v tests/test_pwa_routing.py` — 18 tests OK.
- `python3 -m py_compile services/chat/db.py services/pwa/backend/server.py` — OK.
- `scripts/security/check-secret-artifacts.sh` — passed, scanned 232 source-visible files.
- `scripts/security/redact-operational-secrets.py --check` — passed, scanned 101 file(s) plus `chat.db`; no unredacted markers found.

## Result
The durable chat-log/export routes are runtime-verified on the live backend for authenticated access, unauthenticated denial, markdown content, and traversal rejection. BACKLOG-017 remains not fully closed only for the device-specific mobile foreground/background behavior that requires John's iOS/standalone PWA path to exercise OS backgrounding.
