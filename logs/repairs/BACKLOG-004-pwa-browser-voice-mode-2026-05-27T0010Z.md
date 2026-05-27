# BACKLOG-004 PWA browser voice-mode advance — 2026-05-27T00:10Z

## Selected item
BACKLOG-004 (P0): Voice mode for A2A2H/PWA so CTO reports can be heard aloud and John can reply by speaking.

## Work completed
- Added a visible PWA `Voice off/on` toggle that speaks new OpenClaw/Hermes chat replies with browser `SpeechSynthesis` when enabled.
- Added a visible microphone button that uses browser Web Speech recognition (`SpeechRecognition` / `webkitSpeechRecognition`) to dictate text into the composer when supported.
- Kept unsupported browsers safe: voice/dictation controls disable with status text instead of failing closed chat use.
- Bumped the CTO PWA shell cache to `cto-shell-v8` so clients can pick up the new controls.
- Added regression coverage in `tests/test_pwa_voice_ui.py`.
- Ported the same genericized UI change to `/opt/a2a2h` with cache `a2a2h-shell-v8`.

## Verification
- `node --check services/pwa/frontend/app.js`
- `node --check services/pwa/frontend/service-worker.js`
- `python3 -m unittest -v tests/test_pwa_voice_ui.py`
- `scripts/security/run-safe-security-gates.sh`
- `node --check /opt/a2a2h/services/pwa/frontend/app.js`
- `node --check /opt/a2a2h/services/pwa/frontend/service-worker.js`
- `python3 -c "import ast; ast.parse(open('/opt/a2a2h/services/pwa/backend/server.py').read())"`
- A2A2H genericization grep for `cto|/opt/cto|husband.llc` across services/scripts/frontend: clean.

## Notes
- This is no-spend browser-native voice. Full server-side voice mode remains possible later, but this gives John a visible first-pass voice control immediately.
- BACKLOG-004 remains open pending runtime confirmation on John's phone/browser.
