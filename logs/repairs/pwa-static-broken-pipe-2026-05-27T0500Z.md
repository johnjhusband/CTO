# PWA static asset disconnect repair — 2026-05-27T05:00Z

## Selected item
Broken communication/reporting / human-interface delivery reliability. P0 credential/history-scrub items remain blocked on coordinated live-rotation or destructive history-rewrite windows, and no open PWA backlog item had enough John/device evidence to close.

## Evidence inspected
- Recent chat: OpenClaw still responds; Hermes semantic delegation remains provider-degraded and circuit-breaker repairs are active.
- Services: `systemctl --user --failed` reported 0 failed units; OpenClaw, PWA backend, Hermes gateway, Hermes sidecar, and work-pump timers were active.
- PWA backend journal showed a `BrokenPipeError` while serving `/manifest.json` after the browser/client disconnected during static asset delivery.
- A2A2H upstream check had no pending drift before this repair.

## Repair
Updated `services/pwa/backend/server.py` so static file delivery treats `BrokenPipeError` and `ConnectionResetError` like SSE disconnects: the client went away, so the handler returns without producing an application traceback. Missing files still return JSON 404. Other errors are not hidden.

Ported the same static-file disconnect handling to `/opt/a2a2h/services/pwa/backend/server.py`.

## Verification
- CTO: `python3 -m unittest -v tests/test_pwa_routing.py tests/test_pwa_voice_ui.py` — 32/32 passed, including new `test_static_file_disconnect_does_not_raise`.
- CTO: `scripts/security/run-safe-security-gates.sh` — passed end-to-end: secret artifact guard, operational redaction, install guard, credential preflight/smoke checks, 8 redaction tests, 31 PWA routing/access-control tests, and 1 PWA voice UI test.
- A2A2H: `python3 -m py_compile services/pwa/backend/server.py` — passed. A2A2H does not currently include the CTO test package in this checkout, so the full CTO PWA unittest suite was run from `/opt/cto`.

## Result
Benign browser/service-worker disconnects during static asset fetches no longer create noisy PWA backend tracebacks. No secrets, bearer tokens, raw headers, or raw provider traces were recorded.
