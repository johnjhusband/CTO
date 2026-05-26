# BACKLOG-016 — PWA A2A coordination audit repair

Timestamp: 2026-05-26T20:55Z

Selected item: BACKLOG-016 P0 human-interface transparency. P0 live security rotation remains coordinated/blocked, so this tick advanced the next safe P0 PWA blocker.

Change made:
- Added sanitized A2A audit logging around PWA-originated Hermes requests/responses.
- Request/response rows are written as `a2a_request` / `a2a_response` in `chat.db`, so the existing PWA A2A toggle can expose the coordination transcript.
- Added recursive audit sanitization for token/secret/password/auth/cookie/private-key shaped fields and common pasted credential patterns.
- Added regression tests proving sanitized rows are written and obvious secrets are not stored.

Verification:
- `python3 -m py_compile services/pwa/backend/server.py tests/test_pwa_routing.py` passed.
- `python3 -m unittest -v tests/test_pwa_routing.py` passed: 20/20.
- `scripts/security/run-safe-security-gates.sh` passed: secret artifact guard, operational redaction check, 6/6 redaction tests, 20/20 PWA auth/routing tests.

Remaining:
- Runtime verification in the live PWA after backend reload/restart.
- Broader transcript UX polish if John wants a dedicated panel beyond the existing A2A/JSON toggles.
