# BACKLOG-004 phone voice evidence tick — 2026-05-27T13:20Z

## Scope
Advanced BACKLOG-004 (A2A2H/PWA voice mode) using only existing PWA device evidence and non-destructive verification. No paid/cloud STT/TTS, credential changes, infrastructure changes, or Hermes semantic delegation were attempted.

## Required pre-checks
- A2A2H per-tick upstream-port check: clean. Tracker SHA `ff51e4440f2150c4596f50d71d802dbee4fce7e6`; no upstream-eligible CTO commits under the maintained chat-bridge paths.
- Hermes provider circuit: open (`agent_incomplete_provider_NoneType`), so no semantic Hermes delegation was attempted.
- Higher-priority P0 security status: BACKLOG-005 remains blocked on a coordinated public-history rewrite/risk-acceptance window; BACKLOG-006 remains blocked on a coordinated live credential-rotation/revocation window. I therefore advanced the next safe P0 human-interface item directly.
- Completed-backlog scan: did not close BACKLOG-014/016/017 because their JSON records explicitly require John-visible phone confirmation; BACKLOG.md table already lists 016/017 as resolved but the authoritative JSON currently keeps them pending phone-visible verification.

## New evidence from John's PWA
Latest voice device status row from `chat.db`:
- message id: `1443`
- time: `2026-05-27T11:46:25Z`
- speech synthesis supported: `True`
- speech recognition supported: `True`
- voice enabled: `True`
- standalone: `False`
- status text: `Ready: read-aloud and dictation are supported.`
- bounded user-agent family: `Mozilla/5.0`

This is stronger than static UI evidence: John's browser/device context reported both browser-native read-aloud and dictation support, with voice enabled. I am not closing the item yet because it still lacks explicit John confirmation that audio played and microphone dictation worked as expected on the phone.

## Verification run
- `python3 -m unittest -v tests/test_pwa_voice_ui.py tests/test_pwa_routing.py` — 39/39 passed.
- `node --check services/pwa/frontend/app.js` — passed.
- Backend AST parse for `services/pwa/backend/server.py` — passed.
- `curl -fsS http://127.0.0.1:8088/api/health` — `{"status":"ok","service":"pwa-backend"}`.

## Result
BACKLOG-004 is advanced with fresh phone/browser-side capability evidence and remains open pending John's confirmation of actual speech playback and microphone dictation behavior.
