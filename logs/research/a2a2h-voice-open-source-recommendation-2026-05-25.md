# A2A2H Voice Open-Source Recommendation — 2026-05-25

## Scope
Research only. No implementation, no spending, no secrets, no framework fork.

John wants A2A2H chat to support audible reports and spoken replies, similar to ChatGPT/Claude mobile voice mode. The rule is to adapt maintained open-source code where possible instead of starting from scratch.

## Sources inspected

### Purple-Horizons/openclaw-voice
- Repo: https://github.com/Purple-Horizons/openclaw-voice
- License: MIT
- Shape: browser voice UI + FastAPI/WebSocket server + Whisper/faster-whisper STT + VAD + TTS + OpenClaw/OpenAI-compatible backend adapter.
- Activity signal from GitHub API: 116 stars, 25 forks, 16 open issues, Python, updated 2026-05-24, pushed 2026-02-01.
- Useful code to adapt: browser microphone/WebSocket flow, audio message protocol, simple mobile-compatible voice UI, FastAPI service shape, text cleanup before TTS, smoke tests.
- Main concerns: alpha status, small community, default `OPENCLAW_HOST=0.0.0.0`, optional auth disabled by default, TTS defaults lean on ElevenLabs/cloud or heavier local models, backend adapter assumes OpenAI-compatible chat rather than CTO's A2A2H/PWA chat event model.

### KoljaB/RealtimeSTT
- Repo: https://github.com/KoljaB/RealtimeSTT
- License: MIT
- Shape: maintained Python realtime STT library with VAD, wake words, external audio chunks, and FastAPI browser streaming server example.
- Activity signal from GitHub API: 9813 stars, 836 forks, 141 open issues, pushed 2026-05-22, updated 2026-05-24.
- Useful code to adapt: robust STT core, external audio chunk handling, browser streaming server example, multi-user/session-isolation patterns, health/metrics docs.
- Main concerns: STT only, dependency/model complexity, local model CPU/RAM load; would still need A2A2H adapter and TTS side.

### KoljaB/RealtimeTTS
- Repo: https://github.com/KoljaB/RealtimeTTS
- License: MIT
- Shape: maintained Python realtime TTS library with streaming text/generator input, WAV output, audio chunk callbacks, and many local/cloud engine options.
- Activity signal from GitHub API: 3928 stars, 394 forks, 124 open issues, pushed 2026-05-10, updated 2026-05-24.
- Useful code to adapt: low-latency TTS abstraction, fallback engines, generator/LLM-streaming pattern, WAV/chunk output, browser WebSocket example under `example_fast_api`.
- Main concerns: broad engine matrix means configuration complexity; cloud engines may spend money; local neural engines may be too heavy for the current VPS unless tested.

## Recommendation
Use OpenClaw Voice as the first reference implementation for UI/protocol shape, but do not vendor it wholesale or route it directly to OpenClaw gateway as-is.

Build the CTO voice feature as a thin A2A2H PWA adapter:
1. Browser PWA captures microphone audio and sends chunks over a voice WebSocket endpoint.
2. STT adapter turns audio into text.
3. The text is submitted to existing `/api/messages` routing, preserving A2A2H text/event/audit semantics.
4. Agent replies remain canonical text rows in `chat.db`/SSE.
5. TTS adapter renders selected canonical text replies into audio for browser playback.
6. Voice artifacts are derivative/transient; text chat remains source of truth.

Preferred component strategy:
- UI/WebSocket reference: adapt patterns from `Purple-Horizons/openclaw-voice`.
- STT implementation: prefer `KoljaB/RealtimeSTT` if OpenClaw Voice's simpler Whisper wrapper is insufficient or stale.
- TTS implementation: prefer `KoljaB/RealtimeTTS` with a no-spend/local or system-engine default first; cloud engines require explicit approval.

## Minimum adapter boundary
- Add a PWA-side voice endpoint/service, not changes to OpenClaw/Hermes internals.
- Keep OpenClaw/Hermes gateways loopback-bound.
- Keep `/api/messages` as the only path that creates canonical user text turns.
- Add explicit feature flag, e.g. `A2A2H_VOICE_ENABLED=false` by default until tested.
- Require existing PWA auth token for voice endpoints; do not expose unauthenticated microphone/audio endpoints.
- Store no raw audio by default. If debugging audio capture is ever needed, make it opt-in, local, short-lived, and excluded from memory/logs.

## Risks
- Mobile browsers require HTTPS for microphone access; current PWA/Caddy path is the right place to terminate HTTPS.
- Local STT/TTS can be CPU/RAM-heavy; start with smallest models and make cloud engines explicit opt-in only.
- Continuous voice mode risks accidental input; default should be push-to-talk or hold-to-talk.
- Audio and transcripts may contain sensitive personal data; canonical text rows are already visible to John, but raw audio should not become durable state.
- OpenClaw Voice default host/auth settings are not safe enough for direct production use without hardening.

## Rollback
Disable the voice feature flag and hide PWA voice controls. Leave text A2A2H untouched. Remove any voice systemd unit/dependencies if installed. Since voice is an adapter, rollback should not affect A2A, OpenClaw, Hermes, chat.db canonical text, or decision logs.

## Implementation outline for a later approved phase
1. Add a no-op feature flag and PWA UI placeholder behind `A2A2H_VOICE_ENABLED`.
2. Add tests that verify voice endpoints are disabled by default and require PWA auth when enabled.
3. Add a WebSocket endpoint that accepts audio chunks and returns mocked transcript/audio in test mode.
4. Adapt OpenClaw Voice browser capture/playback into the existing PWA UI.
5. Integrate RealtimeSTT for STT; verify with local sample audio and no raw audio persistence.
6. Integrate RealtimeTTS with a local/no-spend engine first; cloud engines remain disabled unless explicitly approved.
7. Wire STT text into existing `/api/messages`; wire TTS from canonical chat rows back to audio playback.
8. Add docs, rollback, and resource sizing notes before enabling for John.
