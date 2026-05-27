# OpenClaw Gateway cron work-pump alignment — 2026-05-27T07:16Z

## Scope
Continuous-work scheduler reliability. This tick did not delegate to Hermes because the provider circuit was open, did not mutate credentials, did not rewrite history, did not restart services, and did not spend money.

## Preconditions checked
- Git state: `/opt/cto` and `/opt/a2a2h` were clean and synced with origin before selection.
- A2A2H per-tick drift check: no upstream-eligible drift since `2208320fa5761e5e8318133860fc64e840d79d89`.
- Services: no failed user units; OpenClaw Gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers were active.
- Recent chat/logs: Hermes semantic delegation remains degraded by provider-side `agent_incomplete`; `.cache/hermes-work-pump-provider-failure.json` showed 7 consecutive failures.
- Backlog scan: P0 security items remain coordinated-window blocked; P0 PWA items remain pending John/device evidence; no open backlog item was safely closable from disk evidence.

## Repair
Updated Gateway cron job `cto-openclaw-continuous-work-pump` so future Gateway-fired OpenClaw work-pump runs use the same current contract as the systemd script and John-triggered pump prompts:
- inspect current state before choosing work;
- execute the A2A2H upstream-port check before selecting backlog work;
- scan open/pending backlog for closable evidence;
- honor the Hermes provider-failure circuit instead of delegating semantic work into a known failing provider path;
- choose exactly one safe highest-priority item;
- use `thinking: medium` instead of the unsupported `adaptive` setting that was producing recurring Gateway log noise.

## Verification
- `cron list` now shows `cto-openclaw-continuous-work-pump` with the updated description, current work-pump instructions, and `payload.thinking = medium`.
- The job remains enabled, runs every 900 seconds, targets isolated agent turns, and has delivery disabled as before.

## Result
The Gateway cron pump is aligned with the durable continuous-work/A2A2H/Hermes-circuit policy, reducing the chance of future ticks skipping prerequisites or generating unsupported-thinking warnings. No secrets, raw headers, bearer tokens, environment values, or raw provider traces were recorded.
