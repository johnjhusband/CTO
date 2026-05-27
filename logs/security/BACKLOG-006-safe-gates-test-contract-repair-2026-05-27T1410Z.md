# BACKLOG-006 safe gate test-contract repair — 2026-05-27T1410Z

## Required pre-checks
- A2A2H upstream-port check: clean; no upstream-eligible CTO commits since tracker SHA `353253a7366345676d06c775bdcd5c7f9d61daf7`.
- Hermes provider state: degraded recent `agent_incomplete_provider_NoneType`; no semantic Hermes delegation was attempted.
- Backlog completion scan: BACKLOG-004/014 remain pending John phone-visible/audio/notification confirmation; BACKLOG-005 remains pending coordinated history scrub/risk acceptance; BACKLOG-006 remains open pending live credential rotation/revocation.

## Repair
- Updated stale PWA shell regression expectations in `tests/test_pwa_routing.py` and `tests/test_pwa_voice_ui.py` to match the already-shipped chat-first settings-disclosure shell and `cto-shell-v24`.
- No frontend/runtime files, credentials, service config, or infrastructure were changed.

## Verification
- `scripts/security/run-safe-security-gates.sh` passed end-to-end:
  - secret artifact guard passed
  - operational redaction check passed across logs plus chat.db
  - install secret-handling guard passed
  - credential preflight/smoke syntax passed
  - credential preflight names-only check returned `ready_for_coordinated_rotation_window`
  - local service smoke returned healthy for OpenClaw, Hermes, Hermes A2A sidecar, and PWA backend
  - redaction unit tests passed 8/8
  - PWA routing tests passed 38/38
  - PWA voice UI test passed 1/1

## Conclusion
The non-destructive credential/access-control gate suite is green again after the chat-first shell v24 test-contract drift. BACKLOG-006 remains open only for the coordinated live credential rotation/revocation and approved broader cleanup.
