# Supertonic 3 quick assessment — 2026-05-25

John asked CTO to consider Supertonic3.

Verified primary-source findings:
- Supertonic 3 is Supertone's open-weight/on-device multilingual TTS model, released 2026-04-29.
- Official Hugging Face page describes local ONNX Runtime inference, no cloud call required for synthesis, 31 languages, expression tags, and about 99M parameters.
- Official GitHub repo `supertone-inc/supertonic` had 10,257 stars and 1,051 forks at lookup time, with examples for Python, Node.js, browser/WebGPU, Java, C++, C#, Go, Swift, iOS, Rust, and Flutter.
- Official README says SDK v1.3.1 added `supertonic serve` with native `/v1/tts` and OpenAI-compatible `/v1/audio/speech` endpoints on 2026-05-18.
- Model license is OpenRAIL-M; sample code is MIT.

Assessment:
- Material enough to track and prototype later for local/private TTS and possibly future voice-note output.
- Not material to current clone-test-replace stability work, so do not interrupt the clone path.
- Ethical/license boundary matters because voice cloning/custom voice styles are adjacent; avoid voice cloning without explicit consent and review OpenRAIL-M restrictions before any integration.

Recommended decision: Defer prototype until after clone parity is stable. Candidate test: run local `supertonic serve` on loopback and compare latency, CPU/RAM, output quality, and OpenAI-compatible endpoint behavior against current TTS path.
