# OpenClaw work pump — Hermes provider degraded

Timestamp: 2026-05-27T22:55:37Z

## Required pre-checks
- A2A2H upstream-port check: clean. `wiki/A2A2H_LAST_SYNC.md` last synced CTO SHA `6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3`; `git log <last>..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no commits.
- A2A2H repo status: clean against `origin/master`.
- Backlog completion scan: BACKLOG-014/016/017/004 remain explicitly pending John phone/device confirmation; BACKLOG-005/006 remain coordinated-secret/history work; no safe observable closure this tick.
- Hermes provider circuit: open/degraded via `/opt/cto/.cache/hermes-work-pump-provider-failure.json`; no semantic work was delegated to Hermes.

## Selected item
Hemisphere health / A2A delegation reliability.

## Evidence
- `hermes-gateway.service`, `cto-hermes-a2a-sidecar.service`, and `cto-pwa-backend.service` were active.
- Hermes A2A sidecar health endpoint returned OK.
- Recent Hermes gateway logs show repeated non-retryable provider errors from `openai-codex/gpt-5.5`: `TypeError: 'NoneType' object is not iterable`.
- Hermes work pump recorded repeat `agent_incomplete` failures at 22:40Z and 22:55Z. The 22:55Z recovery restart was skipped because the restart cooldown was still active.
- The new Hermes blocked artifact `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T225550Z.md` was preserved for audit.

## Action taken
- Did not delegate semantic work to Hermes while the circuit was open.
- Did not restart Hermes again during the configured cooldown.
- Committed the fresh degraded-state artifacts so the failure is durable and visible instead of remaining as untracked state.

## Verification
- PWA backend health: OK.
- Hermes sidecar health: OK.
- Git commit/push follows this artifact.

## Next safe follow-up
After the cooldown expires, retry Hermes with a minimal health task. If `agent_incomplete` persists, inspect the sanitized request dumps and Hermes provider adapter around the Codex response path; avoid recording raw dumps or credentials in repo artifacts.
