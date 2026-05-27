# OpenClaw work-pump degraded-output hardening — 2026-05-27T09:40Z

## Scope
OpenClaw continuous work-pump reliability repair after recent scheduled ticks produced `no visible final text` summaries and a prior OpenClaw Gateway `WebSocket closed 1006` transport error.

No credentials were read or changed, no infrastructure was restarted, no history rewrite was attempted, and no semantic work was delegated to Hermes because the Hermes provider circuit remains open/degraded with `agent_incomplete_provider_NoneType`.

## Required pre-checks
- A2A2H per-tick drift check: clean; no upstream-eligible CTO commits since `27abb1203d2a13253e8c1b7e9658518d77794236`.
- Git state before repair: `/opt/cto` and `/opt/a2a2h` were clean and synced with origin.
- Recent PWA chat: no new John instruction after the 08:18Z phone-side confirmation checklist.
- Service health: no failed user units; OpenClaw Gateway, Hermes Gateway, PWA backend, A2A registry, Hermes sidecar, and work-pump timers were active.
- Backlog scan: P0 credential/history work remains blocked on coordinated rotation/scrub; P0 PWA items remain pending phone/device confirmation; no open/pending item was safely closable from disk evidence.

## Change
Updated `scripts/openclaw-work-pump.sh` so non-JSON output or JSON responses without visible final text create a sanitized durable repair artifact under `logs/repairs/openclaw-work-pump-degraded-*.md`.

The raw OpenClaw JSON/output remains only in the temporary file and is deleted by the existing cleanup trap. Journald receives a concise degraded summary with the artifact path instead of raw envelopes.

## Verification
- `bash -n scripts/openclaw-work-pump.sh` passed.
- Diff inspection confirmed degraded artifacts include only timestamp, process status, stop reason/sanitized status, finding, handling, and next safe action.
- A2A2H drift check remained clean after the change because `scripts/openclaw-work-pump.sh` is not an upstream A2A2H path.

## Result
Future scheduled OpenClaw work-pump ticks that return no visible final text will leave a durable, sanitized artifact for diagnosis instead of appearing as an empty/ambiguous completed tick.
