# BACKLOG-006 safe credential/security gates — 2026-05-27T15:25Z

## Selection
OpenClaw selected BACKLOG-006 safe credential-hygiene verification as the highest-priority safe item. BACKLOG-005 remains blocked on a coordinated destructive public-history scrub/risk-acceptance window, and BACKLOG-006 cannot fully close until live credentials are rotated/revoked in a coordinated window.

## A2A2H per-tick upstream-port check
Last synced CTO SHA: `353253a7366345676d06c775bdcd5c7f9d61daf7`.
Scope checked: `services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py`.
Result: no upstream-eligible CTO commits since the tracker SHA; no A2A2H port required this tick.

## Current state inspected
- PWA chat: latest events show repeated `hermes_work_pump_blocked (status=blocked_degraded)` notices; no newer John unblock/approval for destructive rotation or history rewrite.
- Hermes provider cache: latest recorded failure is `agent_incomplete_provider_NoneType`; semantic Hermes delegation was not used for this tick.
- Services: no failed system or user units; `openclaw-gateway`, `hermes-gateway`, `cto-hermes-a2a-sidecar`, `cto-pwa-backend`, and `cto-a2a-registry` reported active/healthy through the safe gate checks.
- Git: CTO and A2A2H checkouts were clean and tracking `origin/master` before this artifact was written.
- Backlog completion scan: PWA visible items still require John/device confirmation; credential/history items still require coordinated rotation/scrub approval, so no open item was closed from disk evidence this tick.

## Verification performed
Ran `scripts/security/run-safe-security-gates.sh`.

Passed:
- Secret artifact guard: scanned 461 source-visible files.
- Operational secret redaction check: scanned 313 files plus `chat.db`; no unredacted markers found.
- Install secret-handling guard.
- Credential rotation preflight and smoke script syntax checks.
- Credential rotation preflight names/status-only check: `ready_for_coordinated_rotation_window`.
- Rotation smoke local-service health check: `local_services_healthy`.
- Redaction unit tests: 9/9 passed.
- PWA auth/routing regression tests: 38/38 passed.
- PWA voice UI regression test: 1/1 passed.

## Result
Safe, non-destructive credential/security gates are still green after the latest Hermes health repair. BACKLOG-006 remains open pending the coordinated live credential rotation/revocation window and approved broader cleanup. No secret values, raw request traces, or transient provider payloads were recorded.
