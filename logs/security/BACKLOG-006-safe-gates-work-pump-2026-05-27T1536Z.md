# BACKLOG-006 safe credential/security gates — 2026-05-27T15:36Z

## Selection
OpenClaw selected BACKLOG-006 safe credential-hygiene verification as the highest-priority safe item. BACKLOG-005 remains blocked on a coordinated destructive public-history scrub/risk-acceptance window, and BACKLOG-006 cannot fully close until live credentials are rotated/revoked in a coordinated window.

## Required pre-checks
- A2A2H per-tick upstream-port check: clean. Tracker SHA `353253a7366345676d06c775bdcd5c7f9d61daf7`; no upstream-eligible CTO commits under `services/pwa`, `services/hermes_a2a_sidecar`, `services/a2a_delegate`, `scripts/cache-keepalive.sh`, or `services/chat/db.py`.
- Hermes provider circuit: degraded record still present (`agent_incomplete_provider_NoneType`), so no semantic Hermes delegation was attempted.
- Completion scan: no open/pending backlog item had enough on-disk evidence for closure; visible PWA items remain pending John/device confirmation and credential/history items remain pending coordinated rotation/scrub approval.
- Services: user services reported active/running for OpenClaw Gateway, Hermes Gateway, Hermes A2A sidecar, PWA backend, and A2A registry.
- Git: CTO checkout was clean before this artifact/update.

## Verification performed
Ran `scripts/security/run-safe-security-gates.sh`.

Passed:
- Secret artifact guard: scanned 463 source-visible files.
- Operational secret redaction check: scanned 315 files plus `chat.db`; no unredacted markers found.
- Install secret-handling guard.
- Credential rotation preflight and smoke script syntax checks.
- Credential rotation preflight names/status-only check: `ready_for_coordinated_rotation_window`.
- Rotation smoke local-service health check: `local_services_healthy`.
- Redaction unit tests: 9/9 passed.
- PWA auth/routing regression tests: 38/38 passed.
- PWA voice UI regression test: 1/1 passed.

## Result
Safe, non-destructive credential/security gates are green. BACKLOG-006 remains open pending the coordinated live credential rotation/revocation window and approved broader cleanup. No secret values, raw request traces, chain-of-thought, or transient provider payloads were recorded.
