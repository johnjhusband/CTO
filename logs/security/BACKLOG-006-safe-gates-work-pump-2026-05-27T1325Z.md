# BACKLOG-006 safe credential/security gate — 2026-05-27T13:25Z

## Scope
Advanced the highest-priority safe OpenClaw-owned item available this tick: BACKLOG-006 credential hygiene, without rotating/revoking live credentials, rewriting history, spending money, or delegating semantic work to Hermes.

## Required pre-checks
- A2A2H per-tick upstream-port check: clean. Tracker SHA `ff51e4440f2150c4596f50d71d802dbee4fce7e6`; `git log <tracker>..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no upstream-eligible commits, so no port was required.
- Recent PWA chat: John asked "What's new today?" and OpenClaw responded; Hermes coordinated handoff is still failing with provider `agent_incomplete` / `NoneType`.
- Hermes provider circuit: open per `/opt/cto/.cache/hermes-work-pump-provider-failure.json`; no semantic Hermes delegation attempted.
- Completed-backlog scan: no open/pending item was closed. BACKLOG-014 and BACKLOG-004 have fresh phone/browser evidence but still require John-visible confirmation; BACKLOG-005 remains blocked on a coordinated history-scrub/risk-acceptance decision; BACKLOG-006 remains blocked on a coordinated live credential-rotation/revocation window.

## Verification
Ran `scripts/security/run-safe-security-gates.sh` successfully.

Passed gates:
- Secret artifact guard: scanned 431 source-visible files.
- Operational secret redaction check: scanned 285 files plus `chat.db`; no unredacted markers found.
- Install secret-handling guard: passed.
- Credential rotation preflight: names/status only; required credential names present and non-empty; `.env` mode `600`; result `ready_for_coordinated_rotation_window`.
- Credential rotation smoke: dependent user services active and local health endpoints healthy; result `local_services_healthy`.
- Redaction unit tests: 8/8 passed.
- PWA auth/routing regression tests: 38/38 passed.
- PWA voice UI regression test: 1/1 passed.

## Result
Safe credential/security gates are still green at 2026-05-27T13:25Z. BACKLOG-006 remains open only for the coordinated live rotation/revocation window and any approved broader cleanup.