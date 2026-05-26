# Hermes work pump agent_incomplete recovery repair — 2026-05-26T23:55Z

Scope: OpenClaw continuous-work pump selected hemisphere health because the P0 security items are currently blocked on coordinated live-credential rotation or destructive public-history rewrite, while the latest failed verification showed Hermes work-pump `agent_incomplete` failures at 23:38–23:48 UTC.

Root cause evidence:
- `cto-hermes-work-pump.service` had started returning Hermes HTTP 502 responses with provider-side `agent_incomplete` / `NoneType` errors.
- The first repair made those failures non-fatal by writing explicit blocked notes, but it still left the next timer tick likely to hit the same wedged Hermes runtime state.
- The existing scheduler and A2A sidecar were otherwise healthy; this did not require a new cron job or a new nudger.

Repair performed:
- Updated `scripts/hermes-work-pump.sh` in the existing Hermes work-pump path.
- On `agent_incomplete`, the pump now retries once with a fresh task-scoped Hermes session as before.
- If the retry also returns `agent_incomplete`, it restarts the existing user services `hermes-gateway.service` and `cto-hermes-a2a-sidecar.service` once, waits for sidecar `/health`, then tries one final fresh task.
- If recovery still fails, it writes a sanitized blocked note and exits successfully so systemd does not mark an explicit blocked state as a failed unit.
- Recovery is opt-out via `HERMES_WORK_PUMP_RECOVERY_RESTART=0`.

Verification:
- `bash -n scripts/hermes-work-pump.sh` passed.
- User service inventory confirms `hermes-gateway.service`, `cto-hermes-a2a-sidecar.service`, and `cto-hermes-work-pump.service` are the existing units being repaired; no new scheduler was added.
- Sidecar health was reachable before the repair (`127.0.0.1:8643/health` via service/listener inspection).
- Git status was clean before this change; this artifact and script patch are the only intended changes.

Safety:
- No secrets, bearer tokens, environment values, raw tool traces, or credential material are recorded here.
- The repair does not spend money, rewrite history, rotate live secrets, destroy data, or change public exposure.
