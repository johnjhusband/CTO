# Hermes work pump circuit open

- Timestamp: 2026-05-27T21:42:32Z
- Selected item: hemisphere health / Hermes continuous work pump reliability
- Status: blocked_degraded_circuit_open
- Evidence: provider failure cache shows repeated `agent_incomplete` / `NoneType` failures, so semantic Hermes delegation was intentionally skipped this tick.
- Circuit state: known provider-side agent_incomplete outage; semantic Hermes delegation paused for another 2573s after 2 consecutive failures (adaptive cooldown 2700s)
- Previous failure artifact: /opt/cto/logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T214026Z.md
- Action taken: left services running, avoided another provider call, and preserved this durable degraded-state note for OpenClaw strategy follow-up.
- Secret handling: no request headers, bearer tokens, environment values, or raw tool traces recorded.
