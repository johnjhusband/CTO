# Hermes provider circuit repair: adaptive cooldown — 2026-05-27T06:45Z

## Scope
Hemisphere health / A2A reliability. P0 credential/history items remain coordinated-window blocked, PWA items remain blocked on John/device evidence, and Hermes semantic delegation is provider-degraded. This tick did not call Hermes semantic work, mutate credentials, restart services, spend money, or rewrite history.

## Preconditions checked
- A2A2H upstream-port check before selection: no upstream-eligible drift since tracker SHA `91343b453ea64984a8f68b9bb9b43e5d86b6a3a1`.
- Services: no failed user units; OpenClaw Gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers were active.
- Current Hermes provider state: 7 consecutive provider-side `agent_incomplete` / `NoneType` failures, latest artifact `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T062222Z.md`.
- Backlog scan: no open P0 was safely closable from disk evidence.

## Change
Updated `scripts/hermes-work-pump.sh` so the provider-failure circuit uses adaptive exponential cooldown after repeated failures:
- Base cooldown remains `HERMES_WORK_PUMP_PROVIDER_FAILURE_COOLDOWN_SECONDS` (default 2700s).
- New cap `HERMES_WORK_PUMP_PROVIDER_FAILURE_MAX_COOLDOWN_SECONDS` defaults to 21600s.
- Cooldown doubles from the third consecutive failure until the cap.

Updated `scripts/cache-keepalive.sh` and ported the keepalive behavior to A2A2H so keepalive uses the same adaptive circuit check instead of probing Hermes during a known provider outage.

## Verification
- `bash -n scripts/hermes-work-pump.sh scripts/cache-keepalive.sh` passed.
- `./scripts/hermes-work-pump.sh` returned immediately with `blocked_degraded_circuit_open` and did not attempt semantic delegation; at 7 failures it reported adaptive cooldown cap `21600s`.
- `KEEPALIVE_ROOT=/opt/cto scripts/cache-keepalive.sh` skipped Hermes ping with provider circuit open.
- A2A2H: `bash -n /opt/a2a2h/scripts/cache-keepalive.sh` passed.
- A2A2H synthetic provider-state check skipped Hermes ping with provider circuit open.

## A2A2H sync
Ported CTO `2208320fa5761e5e8318133860fc64e840d79d89` to A2A2H as `eefdb9d82d5562af8a44733da760b1ac27c0fa39`.

## Result
OpenClaw and keepalive will stop hammering the same failing Hermes/Codex provider path every ~45 minutes during persistent outages. Hermes services remain up and health-checked; only semantic delegation is paused while the provider circuit is open. No secrets, raw headers, bearer tokens, environment values, or raw provider traces were recorded.
