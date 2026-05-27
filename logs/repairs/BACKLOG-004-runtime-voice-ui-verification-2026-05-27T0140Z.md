# BACKLOG-004 runtime voice UI verification — 2026-05-27T01:40Z

## Selection
OpenClaw continuous work pump selected BACKLOG-004 because the per-tick A2A2H upstream-port check was clean and the higher security P0 items (BACKLOG-005/BACKLOG-006) still require coordinated credential/history-scrub approval windows. BACKLOG-004 was the highest-priority safe P0 item that could be advanced without spend, destructive changes, or external risk.

## Required context checked
- Policy: `/opt/cto/wiki/continuous-work-policy.md`.
- A2A2H maintenance: `/opt/cto/wiki/A2A2H_MAINTENANCE.md` and `/opt/cto/wiki/A2A2H_LAST_SYNC.md`.
- Heartbeat: `/opt/cto/HEARTBEAT.md`.
- Backlog: `/opt/cto/BACKLOG.md` and `logs/backlog/BACKLOG-004.json`.
- Recent PWA chat: `/opt/cto/logs/pwa-chat/2026-05-27.md`.
- Failure protocol: `/opt/cto/FAILURE.md`.
- Recent repair/security logs under `/opt/cto/logs/`.

## A2A2H per-tick check
Command scope: `git log bebcd3953f2db3b876cf90ea5b4484630999db73..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py`.

Result: no upstream-eligible CTO commits after the last synced SHA. No A2A2H port required this tick.

## Service health snapshot
- `systemctl --user --failed`: 0 failed units.
- `systemctl --failed`: 0 failed units.
- Loopback gateways listening: Hermes `127.0.0.1:8642`, OpenClaw `127.0.0.1:18789`.
- Public HTTP/HTTPS listeners present on ports 80/443.
- `/opt/cto/services/watchers/health.py` exited without output.

## Runtime verification
Performed against the live local PWA backend at `127.0.0.1:8088` using a temporary cookie jar. The PWA auth token was read from `/opt/cto/.env` but was not printed or recorded.

Results:
- `POST /api/login`: `303` and session cookie issued.
- Authenticated `GET /`: `200`.
- PWA shell contains `id="voice-toggle"`.
- PWA shell contains `id="voice-input"`.
- PWA shell still contains `id="enable-push"`.
- Authenticated `GET /static/service-worker.js` reports `SHELL_CACHE = "cto-shell-v8"`, so the cache-bumped shell containing voice UI is live.

This verifies that the live backend serves the visible browser-native voice controls shipped for BACKLOG-004. It does not verify microphone capture or speech playback on John's phone; browser/device permission behavior still requires John's device path.

## Regression gates
- `python3 -m unittest -v tests/test_pwa_routing.py tests/test_pwa_voice_ui.py` — 28/28 passed.
- `scripts/security/run-safe-security-gates.sh` — passed:
  - secret artifact guard scanned 295 source-visible files;
  - operational redaction check scanned 158 file(s) plus `chat.db`;
  - install secret-handling guard passed;
  - redaction unit tests passed;
  - PWA auth/routing tests passed;
  - PWA voice UI regression passed.

## Result
BACKLOG-004 advanced from code-only/static test coverage to live runtime shell verification. The item remains open for John/device confirmation of actual speech synthesis and microphone dictation behavior, plus any later server-side STT/TTS adapter if browser-native APIs are insufficient.
