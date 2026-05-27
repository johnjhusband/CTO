# BACKLOG-014 repair: visible push device readiness

- Timestamp: 2026-05-27T03:44Z
- Selected item: BACKLOG-014 / PWA background notifications and visibility
- Status: advanced; remains open pending John/device confirmation that his phone displays a background notification

## Required context checked

- Continuous work policy, A2A2H maintenance protocol, heartbeat, backlog, recent PWA chat, git status, service health, and recent failed verification.
- A2A2H per-tick check before this work: `git log 2a929758804d6f0c005e0182662ff3539e265b67..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py` returned no unported upstream-eligible CTO commits.
- Service health snapshot: `systemctl --user --failed` reported 0 failed user units; OpenClaw and Hermes loopback gateways were listening on 127.0.0.1:18789 and 127.0.0.1:8642.
- Recent failure note reviewed: Hermes work pump `agent_incomplete`/HTTP 502 note at `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T033449Z.md`; this did not block a direct PWA UI repair.

## Why

John reported that PWA improvements were not visible. The app already had an Enable/Test push button, but it did not show persistent device-level readiness. On a phone PWA, this makes the background-alerts feature feel invisible or broken unless a notification actually appears.

## Repair

- Added an inline `push-status` line to the Background alerts card.
- Added `describePushCapability()` on page load to show whether the current browser supports notifications, Web Push, permission state, and an existing subscription.
- Updated `enablePush()` so each phase updates both the top status bar and the inline Background alerts status: unsupported browser, permission request/denial, missing VAPID public key, subscribed/sending test, provider-submit success, provider-submit failure, and thrown errors.
- Changed the feature summary to say push now shows device readiness and sends a test notification from the button.
- Bumped the CTO service-worker cache from `cto-shell-v12` to `cto-shell-v13` so installed PWAs refresh.
- Ported the same generic UI repair to `/opt/a2a2h/` with `a2a2h-shell-v13`.

## Verification

- `python3 -m unittest tests.test_pwa_routing tests.test_pwa_voice_ui tests.test_redact_operational_secrets` — 38/38 passed.
- `node --check services/pwa/frontend/app.js` — passed.
- `node --check /opt/a2a2h/services/pwa/frontend/app.js` — passed.
- `python3 -c "import ast; ast.parse(open('services/pwa/backend/server.py').read())"` — passed.
- `python3 -c "import ast; ast.parse(open('/opt/a2a2h/services/pwa/backend/server.py').read())"` — passed.
- `scripts/security/run-safe-security-gates.sh` — passed, including secret artifact guard, operational log/chat redaction, install secret-handling guard, credential rotation preflight/smoke names-only checks, redaction tests, PWA auth/routing tests, and PWA voice UI tests.
- Live local static checks on the PWA backend returned HTTP 200 for `/static/app.js` and `/service-worker.js`; app.js contains `describePushCapability()` and `setPushStatus`, and service-worker.js contains `cto-shell-v13`.

## Result

The PWA now gives John a visible answer for the background-alerts path before and after pressing Enable/Test. This does not claim final device notification display is confirmed; that still requires John's phone/browser path.

## A2A2H port result

Ported CTO 12539b7 to A2A2H as 14112ae and pushed A2A2H origin/master. Updated `wiki/A2A2H_LAST_SYNC.md` in CTO in a follow-up tracker commit.
