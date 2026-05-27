# BACKLOG-019 stale PWA worker watchdog — 2026-05-27T12:45Z

## Selection
OpenClaw continuous work pump selected BACKLOG-019 after the mandatory A2A2H upstream-port check showed no eligible drift since `97a48575c029778b483433ef7f2ea594fad2bd31`.

Higher P0 credential/history-scrub items remain blocked on coordinated secret rotation and destructive git-history scrub. BACKLOG-016/017 remain pending John-visible phone verification by their own guardrail. Hermes is degraded from a provider-side `NoneType`/`agent_incomplete` failure, so no semantic work was delegated to Hermes.

## Change
Added a stale in-process PWA chat worker watchdog:
- assigns each live in-process PWA worker a `pwa-worker-*` correlation id;
- tracks active workers in memory;
- emits one visible `pwa_chat_worker_stuck` `system_event` after `PWA_PENDING_WORKER_WARN_S` (default 180s) if the worker is still pending;
- includes the same worker id on `pwa_chat_worker_crashed` events.

## Verification
- `python3 -m py_compile services/pwa/backend/server.py` — passed.
- `python3 -m unittest -v tests.test_pwa_routing tests.test_pwa_layout tests.test_pwa_voice_ui` — 42/42 passed.

## A2A2H
This touched `services/pwa/backend/server.py`, so the A2A2H port/update step is required before the tick is complete.
