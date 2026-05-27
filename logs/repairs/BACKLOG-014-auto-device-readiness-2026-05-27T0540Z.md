# BACKLOG-014/BACKLOG-004 auto device-readiness reporting

- Timestamp: 2026-05-27T05:40Z
- Selected item: P0 PWA improvements — background alerts and voice mode are still waiting on real phone/browser evidence.
- A2A2H per-tick check before work: no upstream-eligible CTO commits were pending at tick start (`git log a5a13d56..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py` returned empty).

## Change

Added one-per-UTC-day automatic device-readiness reports from the authenticated PWA on load:

- `/api/push/device_status` now receives a sanitized `auto_daily: true` snapshot with Notification/Web Push support, permission, subscription state, standalone mode, platform family, and bounded status text.
- `/api/voice/device_status` now receives a sanitized `auto_daily: true` snapshot with SpeechSynthesis/SpeechRecognition support, voice toggle state, language, standalone mode, platform family, and bounded status text.
- Manual Report buttons still work; shared helper now avoids duplicating push subscription logic.
- Service worker cache bumped from `cto-shell-v16` to `cto-shell-v17` so the installed PWA refreshes the new app shell.

## Why

John/device confirmation is the current blocker for BACKLOG-014 and BACKLOG-004. This makes the phone itself report safe capability evidence whenever John opens the PWA, instead of relying only on John noticing and pressing Report status.

## A2A2H port

Ported CTO `0226a115ae19534d08150c569e490b196023ed68` to A2A2H as `094edef16d3030786530a00adc7e6d62258a6a4f`; updated `wiki/A2A2H_LAST_SYNC.md`.

## Verification

Passed locally:

```text
python3 -m unittest -v tests.test_pwa_routing tests.test_pwa_voice_ui tests.test_redact_operational_secrets
node --check services/pwa/frontend/app.js
python3 -c "import ast; ast.parse(open('services/pwa/backend/server.py').read())"
```

Result: 41/41 tests passed; frontend JavaScript syntax and backend Python AST parse passed.

A2A2H verification passed: backend Python AST parse, frontend `node --check`, and required `grep -RIn "cto\|/opt/cto\|husband.llc" services scripts frontend` returned no CTO-specific strings.

## Safety

No raw audio, push endpoint URL, auth token, cookie, or full user-agent is persisted by the backend summary. The auto-report is bounded to once per UTC day per browser profile using localStorage.
