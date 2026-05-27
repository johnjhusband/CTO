# OpenClaw work pump repair: policy + Hermes circuit alignment — 2026-05-27T05:10Z

## Selected item
Hemisphere health / A2A delegation reliability and continuous-work policy reconciliation.

## Priority basis
- A2A2H per-tick check was clean: no upstream-eligible CTO commits since the tracked last-synced SHA.
- P0 BACKLOG-005 and BACKLOG-006 remain blocked on John-approved coordinated public-history scrub and live credential rotation/revocation windows.
- P0 PWA items BACKLOG-004/014/016 are implemented/runtime-verified but still require John/device evidence for final closure.
- Recent failed verification shows Hermes semantic delegation is provider-degraded (`agent_incomplete` / Codex `NoneType`) and the provider circuit is currently open.

## Problem
`wiki/continuous-work-policy.md` now requires every OpenClaw tick to run the A2A2H upstream-port check before selecting backlog work. The systemd-launched `scripts/openclaw-work-pump.sh` prompt still mentioned only the older generic context list and did not explicitly tell OpenClaw to honor the active Hermes provider-failure circuit. That risked future scheduled ticks drifting from policy and attempting futile Hermes delegation while the provider outage is already known.

## Repair
Updated `scripts/openclaw-work-pump.sh` so scheduled OpenClaw ticks now explicitly:

1. Inspect `wiki/A2A2H_MAINTENANCE.md` and `wiki/A2A2H_LAST_SYNC.md`.
2. Execute the A2A2H per-tick upstream-port check before selecting any backlog item.
3. Port/update/commit/push/write an artifact first if upstream-eligible drift exists.
4. Check `.cache/hermes-work-pump-provider-failure.json` and avoid semantic Hermes delegation while the provider circuit is open, advancing an OpenClaw-owned safe item directly instead.

## Verification
- `bash -n scripts/openclaw-work-pump.sh` — passed.
- A2A2H drift check returned empty:
  `git log $(awk -F'**Last synced CTO SHA:** ' '/Last synced CTO SHA/ {print $2}' wiki/A2A2H_LAST_SYNC.md)..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py`
- Current Hermes provider circuit state was inspected and remains open with 5 consecutive provider-side `agent_incomplete` failures, last artifact `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T044455Z.md`.

## Result
The scheduled OpenClaw work-pump launcher is now aligned with the durable A2A2H maintenance policy and with the current Hermes provider-outage circuit, reducing the chance that future ticks skip the upstream-port prerequisite or keep delegating into a known failing semantic Hermes path.
