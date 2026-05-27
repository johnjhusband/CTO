# Keepalive repair: honor Hermes provider outage circuit

- Timestamp: 2026-05-27T04:55:00Z
- Selected item: hemisphere health / A2A delegation reliability.
- Priority basis: P0 security/history and credential-rotation items require John-approved coordinated destructive/credential rotation windows; P0 PWA items are implemented and pending John/device confirmation. Hermes work-pump/keepalive was actively degraded by repeated provider-side `agent_incomplete` / `NoneType` failures.
- A2A2H pre-check: clean at tick start; `git log 33c4418a325c54c8a3f309908ba06b7e85c53104..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py` returned empty.

## Repair

- Updated `scripts/cache-keepalive.sh` so the Hermes keepalive ping checks `.cache/hermes-work-pump-provider-failure.json` before calling the A2A sidecar.
- If the provider-failure circuit is open (>=3 consecutive failures inside the configured cooldown), keepalive skips the Hermes semantic ping and exits cleanly after the OpenClaw ping.
- This prevents the separate keepalive timer from continuing to hammer the same known provider-side outage while `scripts/hermes-work-pump.sh` has the circuit open.
- Ported the same genericized change to `/opt/a2a2h/scripts/cache-keepalive.sh` and pushed A2A2H commit `11379a90bc186e705152dbe165eb5c8695979eed`.

## Verification

- `bash -n scripts/cache-keepalive.sh` passed.
- `bash -n /opt/a2a2h/scripts/cache-keepalive.sh` passed.
- With a stubbed `openclaw` binary and the live CTO provider-failure state, `scripts/cache-keepalive.sh` printed `hermes ping skipped: provider circuit open`.
- Verified the skip path did not append a new PWA `chat.db` message (max message id unchanged before/after the run).
- With a synthetic A2A2H provider-failure state, `/opt/a2a2h/scripts/cache-keepalive.sh` printed `hermes ping skipped: provider circuit open`.

## Residual status

Hermes semantic work remains provider-degraded until the underlying Codex/Hermes provider path recovers or is deliberately switched. This repair reduces repeated failed calls and chat/audit noise during the outage.
