# OpenClaw work-pump Hermes circuit chat-noise repair — 2026-05-27T16:45Z

## Selection
OpenClaw selected broken communication/reporting as the highest-priority safe item. John had just replied in PWA that the repeated Hermes degraded notices were “old news” and asked OpenClaw to respond. P0 credential/history work remains blocked on a coordinated rotation/history-scrub window; PWA visible items remain pending John/device verification rather than unattended closure.

## A2A2H per-tick upstream-port check
Last synced CTO SHA: `353253a7366345676d06c775bdcd5c7f9d61daf7`.
Scope checked: `services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py`.
Result: no upstream-eligible CTO commits since the tracker SHA; no A2A2H port required this tick.

## Current state inspected
- PWA chat showed repeated `hermes_work_pump_blocked` system events, then John's “This is all old news” / “Respind” messages at 16:38Z.
- Hermes provider circuit is open in `/opt/cto/.cache/hermes-work-pump-provider-failure.json` with repeated `agent_incomplete_provider_NoneType`; semantic Hermes delegation was skipped.
- User and system failed-unit lists were empty; OpenClaw gateway, Hermes gateway, Hermes sidecar, and the OpenClaw work-pump timer were running.
- Open/pending backlog scan showed P0 credential/history items blocked on coordinated action, and PWA-visible P0 items still pending John-visible phone confirmation.

## Action taken
Updated `scripts/hermes-work-pump.sh` so repeated already-open provider-circuit ticks no longer emit PWA `hermes_work_pump_blocked` system_events. The first concrete `agent_incomplete` failure remains human-visible; later circuit-open skips remain durable repair artifacts for OpenClaw strategy without spamming John's chat with unchanged status.

## Verification
- `git log 353253a7366345676d06c775bdcd5c7f9d61daf7..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no commits.
- `bash -n scripts/hermes-work-pump.sh` passed.
- The embedded Python heredoc in `scripts/hermes-work-pump.sh` parsed with `ast.parse` after extraction.
- No PWA frontend files were touched, so the Playwright chat-first gate was not required.

## Result
John should stop seeing repeated “Hermes work pump blocked” chat events for the same already-open provider outage. The degraded state remains visible on disk and to OpenClaw's work-pump inspections. No secrets, raw tool traces, or transient provider payloads were recorded.
