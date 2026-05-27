# BACKLOG-014 device readiness retry — 2026-05-27T11:45Z

## Required pre-checks
- A2A2H upstream-port check ran first from `wiki/A2A2H_LAST_SYNC.md` (`27abb1203d2a13253e8c1b7e9658518d77794236`): `git log 27abb1203d2a13253e8c1b7e9658518d77794236..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no commits before this work, so no pre-existing port was required.
- Recent PWA chat inspected: latest John-facing message still reported PWA features implemented and pending phone-side confirmation.
- Backlog completion scan found no safe closure from disk evidence: BACKLOG-004/BACKLOG-014 still need John/device behavior evidence; BACKLOG-005/BACKLOG-006 remain coordinated-window blocked; BACKLOG-015 remains credential-blocked.
- Hermes provider circuit is open (`agent_incomplete_provider_NoneType` in `/opt/cto/.cache/hermes-work-pump-provider-failure.json`), so no semantic Hermes delegation was attempted.

## Selected item
BACKLOG-014 — make PWA background delivery observable/reliable enough for John to confirm phone behavior.

## Change
- Changed `services/pwa/frontend/app.js::autoReportDailyDeviceReadiness()` so the once-per-day local marker is written only after at least one device-status POST succeeds.
- This prevents a transient offline/auth/server failure from suppressing push/voice readiness retries for the rest of the day.
- Bumped CTO shell cache to `cto-shell-v19` and visible app marker to `Updated 2026-05-27 11:45 UTC · shell v19`.
- Ported the genericized frontend change to A2A2H as `b9b3e27a01864bf64981026736732e49b5b8fa12`.

## Verification
- CTO targeted tests: `python3 -m unittest tests.test_pwa_routing tests.test_pwa_voice_ui` passed (34/34).
- CTO frontend/backend syntax: `node --check services/pwa/frontend/app.js` and backend AST parse passed.
- CTO safe security gates: `scripts/security/run-safe-security-gates.sh` passed end-to-end, including secret artifact guard, operational redaction checks, credential rotation preflight/smoke (names only), redaction unit tests, PWA auth/routing tests, and PWA voice UI tests.
- A2A2H backend syntax: `python3 -c "import ast; ast.parse(open('services/pwa/backend/server.py').read())"` passed.
- A2A2H has no `tests/` directory present in the extraction.
- A2A2H CTO-string grep over `services/` and `scripts/` returned no hits for `cto`, `/opt/cto`, or `husband.llc`.
- A2A2H origin/master is at `b9b3e27a01864bf64981026736732e49b5b8fa12`.

## Port / commits
- CTO upstream-eligible commit: `9bd83ce9c4d3af7f787884d51eeb1dec96bd5235` (`Improve PWA device readiness retry`).
- A2A2H port commit: `b9b3e27a01864bf64981026736732e49b5b8fa12` (`[port from CTO 9bd83ce9] Improve PWA device readiness retry`).
- CTO tracker/artifact commit: `641fb094f138cd7a161b00571bcdbc329aa57a9f` (`Record PWA readiness retry verification`).

## Result
The PWA now retries daily phone readiness reporting until the report actually reaches the server. BACKLOG-014 remains open because final closure still requires John/device evidence that a background notification is displayed on the phone.
