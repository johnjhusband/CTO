# OpenClaw work-pump backlog dashboard reconciliation — 2026-05-27T15:10Z

## Selection
OpenClaw selected broken reporting / human-facing backlog accuracy as the highest-priority safe item. P0 credential/history rotation still requires a coordinated rotation/scrub window, and PWA phone-visible items still require John-visible device confirmation rather than unattended closure.

## A2A2H per-tick upstream-port check
Last synced CTO SHA: `353253a7366345676d06c775bdcd5c7f9d61daf7`.
Command scope: `services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py`.
Result: no upstream-eligible CTO commits since the tracker SHA; no A2A2H port required this tick.

## Current state inspected
- PWA chat: latest John instruction was the chat-first PWA testing rule at 13:35Z; no newer John request after the 13:44Z commit report. Repeated `hermes_work_pump_blocked (status=blocked_degraded)` notices continue.
- Git: CTO had one untracked Hermes circuit-open artifact at tick start.
- Services: user/system failed-unit lists were empty; PWA, A2A registry, Hermes sidecar, Hermes gateway, and OpenClaw gateway services were running.
- Hermes provider circuit: `/opt/cto/.cache/hermes-work-pump-provider-failure.json` reports `consecutive_failures=3` and `reason=agent_incomplete_provider_NoneType`; semantic Hermes delegation was intentionally skipped.
- A2A2H checkout: `origin/master` clean at `af8e065`.

## Action taken
Reconciled `/opt/cto/BACKLOG.md` with the source JSON backlog state:
- Fixed the malformed BACKLOG-014 Active Items row so the date/status columns are correct.
- Moved BACKLOG-016 and BACKLOG-017 back into Active Items as `open_visible_ui_pending_john_verification`.
- Removed BACKLOG-016 and BACKLOG-017 from Resolved / Abandoned because their JSON files explicitly say not to reclose until John confirms the visible phone controls.

## Verification
- `git log 353253a7366345676d06c775bdcd5c7f9d61daf7..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no commits.
- `systemctl --user --failed` and `systemctl --failed` returned zero failed units.
- Open/pending JSON scan showed BACKLOG-016 and BACKLOG-017 still pending John-visible verification before this edit.
- No code/runtime files were changed; the Playwright PWA UI gate was not required.

## Result
Human-facing backlog dashboard now matches the authoritative JSON state for the pending PWA verification items. No secrets, raw tool traces, or transient provider payloads were recorded.
