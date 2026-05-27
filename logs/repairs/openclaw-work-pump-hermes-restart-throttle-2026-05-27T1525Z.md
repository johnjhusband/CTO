# OpenClaw work-pump Hermes restart-throttle repair — 2026-05-27T15:25Z

## Selection
OpenClaw selected hemisphere health / Hermes continuous-work reliability as the highest-priority safe item after P0 credential/history work remained blocked on a coordinated rotation/scrub window and PWA-visible items remained pending John/device confirmation.

## A2A2H per-tick upstream-port check
Last synced CTO SHA: `353253a7366345676d06c775bdcd5c7f9d61daf7`.
Scope checked: `services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py`.
Result: no upstream-eligible CTO commits since the tracker SHA; no A2A2H port required this tick.

## Evidence inspected
- Hermes provider failure cache reported repeated `agent_incomplete_provider_NoneType` failures.
- Recent Hermes logs showed another post-cooldown probe at 15:23Z with the same `agent_incomplete` / `NoneType` failure.
- The post-cooldown retry restarted `hermes-gateway` and `cto-hermes-a2a-sidecar`, but the restarted Hermes gateway immediately hit the same provider-side error again.
- PWA chat log shows repeated visible `hermes_work_pump_blocked` events, so semantic Hermes delegation remains degraded and should not be used for this OpenClaw tick.

## Action taken
Updated `scripts/hermes-work-pump.sh` so that, once the provider outage circuit is already established (`consecutive_failures >= 3`), a post-cooldown retry may record the repeated failure but skips another Hermes service restart. Restarts are still available for early failures before the outage circuit is established.

This reduces unnecessary service churn during a known provider-side outage while preserving durable blocked notes and visible PWA system events.

## Verification
- `bash -n scripts/hermes-work-pump.sh` passed.
- Git diff was reviewed; only the restart decision branch changed.
- No PWA frontend files were touched, so the Playwright chat-first gate was not required.

## Result
Hermes semantic work remains degraded, but the recurring work pump is now less likely to restart healthy services for the same known provider-side failure. No secrets, raw request dumps, credentials, or transient tool payloads were recorded.
