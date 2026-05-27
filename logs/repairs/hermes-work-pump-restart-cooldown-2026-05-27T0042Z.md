# Hermes work pump recovery restart cooldown

- Timestamp: 2026-05-27T00:42Z
- Selected item: hemisphere health / Hermes continuous work pump reliability.
- Evidence inspected: Hermes work pump is repeatedly receiving provider-side `agent_incomplete` / `NoneType` failures. Services recover to active, but the previous recovery path restarted `hermes-gateway` and the A2A sidecar on every failed pump tick.
- Repair: added a one-hour default cooldown to `scripts/hermes-work-pump.sh` recovery restarts, controlled by `HERMES_WORK_PUMP_RECOVERY_COOLDOWN_SECONDS`. The pump still retries once with a fresh task-scoped session and still writes a blocked artifact, but it will not restart already-healthy Hermes services every 15 minutes when restart is not changing the provider-side failure.
- State file: `/opt/cto/.cache/hermes-work-pump-recovery-restart.ts` (ignored runtime state, no secrets).
- Verification: `bash -n scripts/hermes-work-pump.sh` passed; embedded Python heredoc compiled with `compile(..., 'exec')`.
- Safety: no credentials, infrastructure, data, or external providers were changed.
