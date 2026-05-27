# BACKLOG-014 push device status reporting — 2026-05-27T04:10Z

## Selection
OpenClaw continuous work pump selected BACKLOG-014 after the required A2A2H drift check returned no upstream-eligible CTO commits. P0 credential/history-scrub work remains blocked on a coordinated rotation/scrub window; John's latest PWA direction makes visible background-alert progress the highest-priority safe communication item.

## Context checked
- `wiki/continuous-work-policy.md`, `HEARTBEAT.md`, `BACKLOG.md`.
- `wiki/A2A2H_MAINTENANCE.md`, `wiki/A2A2H_LAST_SYNC.md`.
- Recent PWA chat: John said PWA improvements must be prioritized and that feature requests were not visible.
- Service health: no failed user units; OpenClaw, Hermes, PWA backend, A2A sidecar, and registry were active. Hermes A2A sidecar still returns `agent_incomplete` for delegated work; previous restart cooldown was active.
- Recent failed verification/artifact: `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T040503Z.md`.

## A2A2H per-tick check before work
Command scope: `git log 12539b7c4dcd2f21f06d4e2bd7e9d84db627aceb..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py`.

Result: no upstream-eligible CTO commits were pending before this repair. The new PWA change from this tick must be ported after commit.

## Repair
Added a visible **Report status** button to the PWA Background alerts card and a new authenticated backend endpoint:

- `POST /api/push/device_status` records a bounded `push_device_status` system event in the chat log.
- The frontend reports Notification support, service worker support, PushManager support, permission state, current subscription state, standalone/PWA mode, status text, and post-test attempted/failed counts.
- Successful `Enable/Test` calls automatically report post-test status; John can also tap **Report status** manually.
- Full user-agent strings are not stored; the backend keeps only a bounded family token and other non-secret booleans/status fields.
- Bumped service-worker cache to `cto-shell-v14` so installed clients pick up the feature.

## Verification
- `python3 -m unittest -v tests/test_pwa_routing.py tests/test_pwa_voice_ui.py tests/test_redact_operational_secrets.py` — 39/39 passed.
- `python3 -c "import ast; ast.parse(open('services/pwa/backend/server.py').read())"` — passed.
- `node --check services/pwa/frontend/app.js` — passed.
- `scripts/security/run-safe-security-gates.sh` — passed after rerun; first run exposed an existing order-sensitive A2A audit test flake, but an isolated rerun and full safe gate rerun passed cleanly.

## Result
BACKLOG-014 advanced from visible readiness display to retrievable phone/device evidence. The item remains open until John/device evidence shows the notification actually displayed, but future work pumps can now inspect chat-log `push_device_status` rows instead of relying only on a non-retrievable verbal check.


## A2A2H port result
Ported CTO `a98940f` to A2A2H as `a189f2538736a600fd1d7db542de7f6c07f7984c` and pushed `origin/master`. Updated `wiki/A2A2H_LAST_SYNC.md` to track the new synced CTO SHA. A2A2H verification passed: backend AST parse, frontend `node --check`, and genericization grep for `cto|/opt/cto|husband.llc` returned no hits under services/scripts/frontend.
