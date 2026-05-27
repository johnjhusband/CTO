# OpenClaw work pump degraded-exit repair — 2026-05-27T10:25Z

## Pre-checks
- A2A2H per-tick drift check: clean. `git log 27abb1203d2a13253e8c1b7e9658518d77794236..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no commits; `/opt/a2a2h` was clean at `abe5e3a`.
- Recent PWA chat: latest John-facing note says PWA voice controls, background-alert status/testing, chat history, and coordination toggle are visible; phone-side confirmation remains pending.
- Hermes provider circuit: open at 7 consecutive `agent_incomplete_provider_NoneType` failures, so no semantic Hermes delegation was attempted.
- Backlog scan: P0 credential/history work remains coordinated-window blocked; P0 PWA voice/background items remain pending John/device evidence; no open/pending item was safely closable from disk evidence alone.

## Issue
The scheduled OpenClaw work pump produced another sanitized degraded artifact at `logs/repairs/openclaw-work-pump-degraded-2026-05-27T101807Z.md`, but systemd still marked the service run successful because the wrapper exited 0 when OpenClaw returned JSON with no visible final text.

That made degraded ticks too easy to miss in service health even though the wrapper correctly avoided storing raw JSON and wrote a sanitized artifact.

## Repair
Updated `scripts/openclaw-work-pump.sh` so `summarize_json` exits non-zero for JSON responses with no visible final assistant text. When the OpenClaw process status is 0 but the response is degraded, the wrapper now preserves the sanitized artifact and exits 1 so systemd/service health reports the degraded pump instead of a clean run.

The existing special case for non-zero OpenClaw exits with complete visible `stop` responses is unchanged.

## Verification
- `bash -n scripts/openclaw-work-pump.sh` — passed.
- Static marker check confirmed the degraded-output path contains `sys.exit(2)`, the caller checks `if summarize_json`, and the rc=0 degraded branch exits 1.
- `git diff -- scripts/openclaw-work-pump.sh` shows only the degraded-exit handling change.

## Result
Future scheduled OpenClaw work-pump ticks that return no visible final text will still leave a sanitized durable artifact, but they will no longer be falsely reported as successful by systemd.
