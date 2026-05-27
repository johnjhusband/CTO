# BACKLOG-017 closeout — durable PWA chat log

- Timestamp: 2026-05-27T03:25Z
- Selected queue item: P0 human-interface/backlog reconciliation (`BACKLOG-017`)
- Action: closed `BACKLOG-017` as resolved and moved it from Active Items to Resolved / Abandoned in `BACKLOG.md`.

## Why this was safe to close

John's standing directive says closing shipped backlog items is CTO's job when evidence supports closure. `BACKLOG-017` asked for a durable, human-readable chat log/export and foreground history recovery. Observable evidence now supports closure:

- Daily markdown chat logs exist under `logs/pwa-chat/`, including current-day content.
- The backend `GET /chat-log/` and `/api/chat/export` paths were already runtime-verified for authenticated access, unauthenticated denial, markdown content, and traversal rejection in `logs/repairs/BACKLOG-017-runtime-chat-log-verification-2026-05-26T2040Z.md`.
- The visible PWA shell includes the `Chat history` feature card and `Review full logs` link.
- The frontend reloads full history from `/api/messages?since_id=0` on `visibilitychange` and `focus`.
- The service worker is at `cto-shell-v12`, uses network-first shell refresh, and keeps `/chat-log/` network-only so private/stale log views are not served from shell cache.

Any remaining phone-specific visibility/cache defect should be tracked as a narrower follow-up, not as the original durable-chat-log capability gap.

## Required continuous-work checks

- A2A2H per-tick upstream-port check: no drift. Command result was empty for `git log 2a929758804d6f0c005e0182662ff3539e265b67..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py`.
- Recent PWA chat context: John reported the visible PWA work still did not appear at 2026-05-27T02:42Z, so this tick favored human-interface/backlog reconciliation over new research.
- Service health: no failed system or user services were listed. A small disk check attempt used `python` instead of `python3` and was ignored; no secret-bearing output recorded.
- Recent failed verification: Hermes work-pump A2A delegation is degraded with `agent_incomplete` / `NoneType` 502; recovery restart was skipped by cooldown in `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T031930Z.md`.

## Verification

- `python3 -m unittest -v tests.test_pwa_routing tests.test_pwa_voice_ui` — PASS, 30 tests.
- `bash -n scripts/security/run-safe-security-gates.sh scripts/security/credential-rotation-preflight.sh scripts/security/rotation-smoke.sh` — PASS.
- `scripts/security/run-safe-security-gates.sh` — PASS. Includes secret artifact guard, operational redaction over logs plus `chat.db`, install guard, rotation preflight/smoke syntax and runtime checks, redaction tests, PWA routing/access-control tests, and PWA voice UI test.
