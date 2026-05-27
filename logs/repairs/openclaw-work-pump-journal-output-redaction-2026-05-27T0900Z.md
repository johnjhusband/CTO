# OpenClaw work pump journal output redaction — 2026-05-27T09:00Z

## Required pre-checks
- A2A2H per-tick drift check: no upstream-eligible CTO commits since `27abb1203d2a13253e8c1b7e9658518d77794236`; no port required.
- Recent PWA chat: latest John-facing note at 08:18Z; no new John instruction after that. Device confirmation evidence for voice/background alerts remains absent; latest `push_device_status`/`voice_device_status` rows are work-pump endpoint checks, not phone evidence.
- Git state before repair: clean `master...origin/master`.
- Services/logs: no failed system services and no recent warning-or-higher journal entries; Hermes work pump remains provider-degraded with the adaptive circuit open after 7 `agent_incomplete_provider_NoneType` failures, so no semantic Hermes delegation was attempted.
- Backlog scan: P0 credential/history work still requires a coordinated destructive/credential rotation window; P0 PWA voice/background/audit items are implemented but still pending phone-side confirmation, so no open item was safely closable from disk evidence alone.

## Selected item
Hemisphere/work-pump reporting hygiene. The top P0 items are currently blocked on John/device/coordinated-window evidence, while the scheduled OpenClaw work-pump service was still teeing the full `openclaw agent --json` response into journald. That risks persisting raw model envelopes/tool metadata in service logs and conflicts with the continuous-work rule to avoid raw tool traces/transient noise in shared memory/log surfaces.

## Change
Updated `scripts/openclaw-work-pump.sh` so the full JSON response is written only to a temporary file used for exit-status handling, then deleted by the existing cleanup trap. Journald now receives only a bounded one-line summary containing stop reason and final visible text, or a bounded sanitized failure summary. The existing workaround for non-zero OpenClaw exits with complete `stop` responses remains intact.

## Verification
- `bash -n scripts/openclaw-work-pump.sh` passed.
- `git diff -- scripts/openclaw-work-pump.sh` confirms the previous `| tee "$tmp_output"` path was removed and replaced by temp-file-only capture plus bounded summary output.

## Result
Future scheduled OpenClaw work-pump ticks should stop dumping raw JSON envelopes into journald while still preserving enough status text for operators to see whether the tick completed. No secrets, raw headers, bearer tokens, runtime credential values, or raw provider traces were recorded.
