# BACKLOG-004 voice device readiness/reporting — 2026-05-27T05:25Z

## Selection
OpenClaw continuous work pump selected BACKLOG-004 because P0 credential/history-scrub items remain blocked on coordinated rotation/destructive history windows, and John explicitly asked to prioritize visible PWA improvements. BACKLOG-004 was the highest-priority safe PWA item that could be advanced without spend or external risk.

## Required context checked
- `wiki/continuous-work-policy.md`, `HEARTBEAT.md`, `BACKLOG.md`.
- A2A2H maintenance docs and tracker. Per-tick drift check before this work showed no upstream-eligible CTO commits after `53474d7e2e86cb684b5444377946dd8c72f5a4de`.
- Recent PWA chat and recent verification/repair logs.
- Service health: PWA backend `127.0.0.1:8088`, Hermes sidecar `127.0.0.1:8643`, Hermes gateway `127.0.0.1:8642`, and OpenClaw gateway `127.0.0.1:18789` were locally healthy.

## Repair / advancement
Added a visible voice readiness loop to the PWA:
- Voice card now includes `voice-status`, `voice-help`, and a `Report voice` button.
- Frontend reports bounded browser capabilities: speech synthesis support, speech recognition support, standalone mode, language/platform, voice-enabled state, and status text.
- Backend accepts `POST /api/voice/device_status` and writes a sanitized `voice_device_status` system event to chat history.
- Toggling Voice reports post-toggle capability, giving future work pumps retrievable evidence instead of relying only on verbal confirmation.
- Bumped CTO shell cache to `cto-shell-v16`.

## A2A2H port
Ported the genericized change to `/opt/a2a2h/` and pushed origin/master.
- CTO commit: `a5a13d56a48146594082aee641e28637e7a6ad2c`
- A2A2H commit: `cdc09825fb2d7ee7c3b9744411bbb2177ce1eadf`
- A2A2H tracker updated in `wiki/A2A2H_LAST_SYNC.md`.

## Verification
- `python3 -c "import ast; ast.parse(open('services/pwa/backend/server.py').read())"` — passed.
- `node --check services/pwa/frontend/app.js` — passed.
- `python3 -m unittest -v tests/test_pwa_voice_ui.py tests/test_pwa_routing.py tests/test_redact_operational_secrets.py` — 41/41 passed.
- `scripts/security/run-safe-security-gates.sh` — passed end-to-end.
- A2A2H: `python3 -m py_compile services/pwa/backend/server.py` — passed.
- A2A2H: `node --check services/pwa/frontend/app.js` — passed.
- A2A2H required grep `cto|/opt/cto|husband.llc` under services/scripts/frontend — clean.
- Restarted `cto-pwa-backend.service`; `GET /api/health` returned OK.
- Live authenticated checks: `/` contains `voice-status`, `/static/app.js` contains `/api/voice/device_status`, `/service-worker.js` serves `cto-shell-v16`, and `POST /api/voice/device_status` returned OK and wrote a sanitized status row.

## Result
BACKLOG-004 now has the same phone/device evidence loop as background push: John can see whether his phone supports read-aloud and dictation and can write that status into the durable chat log. The item remains open pending actual John/device confirmation of speech playback and microphone dictation behavior.
