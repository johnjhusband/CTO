# OpenClaw work-pump session bounding — 2026-05-27T10:00Z

## Scope
Hemisphere/work-pump reliability repair after the scheduled OpenClaw pump hit context overflow on the long-lived `openclaw-work-pump` session.

No credentials were read or changed, no service was restarted, no infrastructure was changed, no history rewrite was attempted, and no semantic work was delegated to Hermes because the provider circuit remains open.

## Required pre-checks
- A2A2H per-tick drift check: clean; no upstream-eligible CTO commits since `27abb1203d2a13253e8c1b7e9658518d77794236`.
- Git state before selection: `/opt/cto` and `/opt/a2a2h` clean and synced.
- Services: no failed user units; OpenClaw Gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers active.
- Hermes provider circuit: open/degraded with `agent_incomplete_provider_NoneType`; no Hermes semantic delegation was attempted.
- Backlog completion scan: P0 credential/history work remains coordinated-window blocked; PWA P0 items remain pending John/device evidence; no item was safely closable from disk evidence.

## Evidence
`cto-openclaw-work-pump.service` logged context overflow on the reused `agent:main:explicit:openclaw-work-pump` session:

```text
context-overflow-diag ... sessionKey=agent:main:explicit:openclaw-work-pump ... messages=72 ... error=Context overflow: estimated context size exceeds safe threshold during tool loop.
auto-compaction succeeded ... retrying prompt
```

## Repair
Updated `scripts/openclaw-work-pump.sh` to use a bounded per-tick session id: `openclaw-work-pump-YYYYMMDDTHHMM`.

Reasoning: each pump tick already rehydrates state from durable files (`BACKLOG.md`, heartbeat/policy docs, A2A2H tracker, git/service/chat state, recent logs). Keeping all prior tool output in a single transcript creates preventable context overflow and weakens the pump.

## Verification
- `bash -n scripts/openclaw-work-pump.sh` passed.
- Local git pre-commit/pre-push security hooks ran during commit/push.

## Result
Future scheduled OpenClaw pump ticks should start with bounded transcript context while preserving durable continuity through repo/state inspection.
