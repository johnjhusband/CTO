# Hermes work pump repair: provider-failure circuit breaker

- Timestamp: 2026-05-27T04:48:00Z
- Selected item: hemisphere health / Hermes continuous work-pump reliability.
- Priority basis: continuous-work policy queue item 3 after P0/PWA/security items were either already blocked on external/user/device state or unsafe to advance without approval.
- A2A2H maintenance check: clean; `wiki/A2A2H_LAST_SYNC.md` last synced CTO SHA `33c4418a325c54c8a3f309908ba06b7e85c53104`, no upstream-eligible drift, `/opt/a2a2h` HEAD `ed62bc9ffba6b37562949253261aa354a186a56b`.

## Evidence

- `cto-hermes-work-pump.service` repeatedly completed as `blocked_degraded` at 04:05Z, 04:20Z, and 04:35Z.
- Hermes gateway journal shows repeated non-retryable `openai-codex/gpt-5.5` provider failures: `TypeError: 'NoneType' object is not iterable`, surfaced through the A2A sidecar as HTTP 502 `agent_incomplete`.
- Request dumps show valid task-scoped A2A requests failing provider-side before Hermes can perform work; the failure is not fixed by fresh session ids or restart cooldown retries.

## Repair

Changed `/opt/cto/scripts/hermes-work-pump.sh` to add a provider-failure circuit breaker:

- Track consecutive `agent_incomplete` / provider `NoneType` failures in `/opt/cto/.cache/hermes-work-pump-provider-failure.json`.
- After 3 consecutive failures within an hour, pause semantic Hermes delegation for 2700 seconds instead of repeatedly hammering the provider and spamming John/PWA with identical blocked events.
- Keep Hermes services and timers up; this only gates the failing semantic delegation path.
- Clear the provider-failure state automatically on the next successful Hermes work-pump response.
- Seeded the state from existing recent blocked artifacts so the repair takes effect immediately.

## Verification

- `bash -n scripts/hermes-work-pump.sh` passed.
- Extracted and compiled the embedded Python heredoc successfully.
- Manual verification with recovery restart disabled reproduced the provider-side failure and wrote sanitized artifact `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T044455Z.md`.
- After seeding the circuit state, running `./scripts/hermes-work-pump.sh` returned immediately with:
  `{"status": "blocked_degraded_circuit_open", "artifact": "/opt/cto/logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T044455Z.md", "recovery": "known provider-side agent_incomplete outage; semantic Hermes delegation paused ..."}`

## Residual status

Hermes semantic work remains provider-degraded. This repair prevents repeated futile retries and user-visible spam while preserving evidence and allowing OpenClaw to continue advancing safe work. A real recovery still requires fixing the Codex/Hermes provider path or switching Hermes to a working model/provider with available credentials and acceptable strategy risk.
