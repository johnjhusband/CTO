# A2A2H maintenance path repair — 2026-05-27T07:10Z

## Scope
Continuous-work tick hygiene for the A2A2H upstream-port check. This tick did not delegate to Hermes because the provider circuit was open, did not mutate credentials, did not rewrite history, and did not spend money.

## Preconditions checked
- Git state: `/opt/cto` and `/opt/a2a2h` were clean and synced with origin.
- A2A2H per-tick drift check: no upstream-eligible drift since `2208320fa5761e5e8318133860fc64e840d79d89`.
- Services: no failed user units; OpenClaw Gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers were active.
- Hermes provider circuit: open at 7 consecutive provider-side `agent_incomplete` failures, so no semantic Hermes work was delegated.
- Backlog scan: open P0 items remain blocked on coordinated destructive/history/credential windows or John/device confirmation; no backlog item was safely closable from disk evidence.

## Repair
Fixed `wiki/A2A2H_MAINTENANCE.md` to track the real chat database module path:
- `services/chat/db.py` in CTO
- `services/chat/db.py` in A2A2H

The maintenance doc previously referenced stale `chat/db.py`, which could cause future drift checks to miss chat database changes or produce noisy missing-file reads.

## Verification
- Confirmed both real files exist: `/opt/cto/services/chat/db.py` and `/opt/a2a2h/services/chat/db.py`.
- Confirmed no standalone stale `chat/db.py` reference remains in `wiki/A2A2H_MAINTENANCE.md`.
- Rechecked that the current A2A2H drift query has no upstream-path commits pending after the latest synced SHA.

## Result
A2A2H per-tick maintenance now points at the actual shared chat DB path, reducing drift-check blind spots without touching runtime services or secrets.
