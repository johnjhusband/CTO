# BACKLOG-014 push help guidance — 2026-05-27T04:25Z

## Selection
OpenClaw continuous work pump selected BACKLOG-014 because John explicitly prioritized visible PWA improvements, the required A2A2H upstream-port check was clean at the start of the tick, and higher P0 credential/history-scrub items still require a coordinated rotation/scrub window.

## Context checked
- `wiki/continuous-work-policy.md`, `wiki/A2A2H_MAINTENANCE.md`, and `wiki/A2A2H_LAST_SYNC.md`.
- `HEARTBEAT.md`, `BACKLOG.md`, and current P0 PWA backlog JSON.
- Recent PWA chat for John's request that PWA improvements be prioritized.
- Git status and service health: core user services were active; loopback OpenClaw and Hermes gateways were listening; disk and memory were healthy.
- Recent failed verification: Hermes work pump remains degraded with `agent_incomplete`, captured separately in `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T042025Z.md`.

## A2A2H per-tick check
Command scope: `git log a98940f84b3351fa76a6a70ee86a31735f92f4c9..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py`.

Result at selection time: no upstream-eligible CTO commits after the last synced SHA. No pre-work port was required.

## Repair
The PWA Background alerts card now gives John actionable next-step guidance instead of only reporting "unsupported" or "permission denied" states:

- Added persistent `push-help` text under the device-readiness line.
- `describePushCapability()` now explains what to do for unsupported notifications, unsupported Web Push, permission denial, subscribed/ready state, and post-provider-test state.
- Kept the existing `Report status` path so John can write the phone/browser readiness snapshot into chat for later pumps.
- Bumped the service-worker shell cache from `cto-shell-v14` to `cto-shell-v15` so the installed PWA refreshes.
- Ported the same genericized UI/help change to `/opt/a2a2h/` with `a2a2h-shell-v15`.

## Verification
- `python3 -m unittest -v tests.test_pwa_routing tests.test_pwa_voice_ui tests.test_redact_operational_secrets` — 39/39 passed.
- `node --check services/pwa/frontend/app.js` — passed.
- `python3 -c "import ast; ast.parse(open('services/pwa/backend/server.py').read())"` — passed.
- `scripts/security/run-safe-security-gates.sh` — passed, including local service smoke checks.
- Live local PWA static verification after authenticated login: `/`, `/static/app.js`, `/static/service-worker.js`, and `/static/style.css` returned 200 and contained `push-help`, `pushHelpText`, `cto-shell-v15`, and `.feature-help` respectively.
- A2A2H checks: `node --check services/pwa/frontend/app.js`, backend AST parse, test discovery, and the required `grep -nR "cto\|/opt/cto\|husband.llc" services scripts frontend` all passed/clean.

## Result
BACKLOG-014 advanced with a visible phone-facing repair that reduces ambiguity when background notifications do not appear. The item remains open pending actual John/device evidence that the phone displays a notification, but the PWA now tells him what to try and how to report the device state when it fails.
