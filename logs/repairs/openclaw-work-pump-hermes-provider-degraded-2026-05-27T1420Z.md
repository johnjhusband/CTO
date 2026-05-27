# OpenClaw work pump: Hermes provider degraded — 2026-05-27T14:20Z

## Selected item
Hemisphere health / A2A delegation reliability. This was the highest-priority safe OpenClaw-owned item after the mandatory checks because the Hermes provider circuit is degraded and semantic delegation is currently unsafe.

## Mandatory pre-checks
- A2A2H per-tick upstream-port check: no upstream-eligible CTO commits since `353253a7366345676d06c775bdcd5c7f9d61daf7`; no port required.
- Backlog completion scan: no open/pending item was safely closable from disk evidence alone. BACKLOG-004, BACKLOG-014, BACKLOG-016, and BACKLOG-017 still explicitly require John/device visible confirmation; P0 credential/history items remain coordinated-window/destructive-risk blocked.
- Hermes provider circuit: `/opt/cto/.cache/hermes-work-pump-provider-failure.json` records repeated `agent_incomplete_provider_NoneType` failures and a recovery cooldown.

## Verification
- User services active: `cto-a2a-registry`, `cto-hermes-a2a-sidecar`, `cto-pwa-backend`, `hermes-gateway`, and `openclaw-gateway`.
- Health endpoints returned 200: Hermes gateway `127.0.0.1:8642/health`, Hermes A2A sidecar `127.0.0.1:8643/health`, PWA backend `127.0.0.1:8088/api/health`, OpenClaw gateway `127.0.0.1:18789/health`.
- Recent Hermes logs still show provider-side `TypeError: 'NoneType' object is not iterable` for `openai-codex/gpt-5.5`; the transport processes are healthy but semantic Hermes agent calls are failing.

## Action taken
- Did not delegate semantic work to Hermes during this tick.
- Preserved the existing Hermes work-pump blocked artifact (`logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T140837Z.md`) for durable evidence.
- Wrote this OpenClaw-side degraded-state artifact so future ticks can distinguish live process health from provider/agent-call failure.

## Next safe step
When the cooldown expires, run one non-destructive Hermes semantic smoke test through the existing sidecar/work-pump path. If the same `NoneType` failure persists after recovery, inspect Hermes provider/Codex adapter code and open or update a focused repair artifact before attempting further delegation.
