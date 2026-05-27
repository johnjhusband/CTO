# BACKLOG-014 visible PWA release notes — 2026-05-27T05:55Z

## Selection
OpenClaw continuous work pump selected a safe PWA improvement after required inspection. P0 security items remain blocked on coordinated live credential rotation / public history rewrite decisions, and John explicitly reported that PWA improvements were not visible. BACKLOG-014 remains the highest-priority safe human-interface item that can be advanced without spend, data destruction, or external risk.

## Required context checked
- `wiki/continuous-work-policy.md`, `HEARTBEAT.md`, `BACKLOG.md`.
- `wiki/A2A2H_MAINTENANCE.md` and `wiki/A2A2H_LAST_SYNC.md`.
- Per-tick A2A2H drift check before work: `git log b54d04e45cb491e4baebc9ace65a61e643af15ac..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py` returned empty.
- Recent PWA chat showed John’s concern that feature requests were not visible and recurring Hermes degraded-work-pump events.
- User service health: no failed user units; OpenClaw Gateway, Hermes Gateway, CTO PWA backend, Hermes A2A sidecar, and A2A registry were active.
- Open/pending backlog scan: BACKLOG-005 and BACKLOG-006 remain blocked on coordinated security windows; BACKLOG-004/014/016 remain pending phone/device confirmation; no item was safely closable from disk evidence alone.

## Change
Added an unmistakable visible release-notes panel to the authenticated PWA shell:
- Feature summary now includes `Updated 2026-05-27 05:55 UTC · shell v18`.
- Added expandable `What changed today` notes listing background alerts, agent coordination, chat history, voice controls, and the fallback instruction to tap **Update app** if the panel is missing.
- Added CSS for `.app-version` and `.release-notes` so the change is visually distinct on phone-sized screens.
- Bumped service-worker cache from `cto-shell-v17` to `cto-shell-v18`.
- Updated regression tests to pin this visible contract.

## Verification
Passed locally:

```text
python3 -m unittest -v tests.test_pwa_routing tests.test_pwa_voice_ui tests.test_redact_operational_secrets
node --check services/pwa/frontend/app.js
python3 -c "import ast; ast.parse(open('services/pwa/backend/server.py').read())"
scripts/security/run-safe-security-gates.sh
```

Results: 41 targeted tests passed; frontend JavaScript syntax passed; backend Python AST parse passed; full safe security gates passed including secret artifact guard, operational redaction over logs plus chat.db, credential preflight/smoke checks, PWA auth/routing tests, and voice UI test.

## Result
PWA improvements should now be self-evident in the app shell instead of only buried in repair logs. BACKLOG-014 remains open pending actual phone notification display evidence, but the visibility gap John reported has a concrete UI repair and regression coverage.

## A2A2H port
After the CTO commit introduced upstream-eligible `services/pwa/frontend` changes, ported the genericized release-notes shell update to A2A2H and pushed origin/master.

- CTO commit: `91343b453ea64984a8f68b9bb9b43e5d86b6a3a1`
- A2A2H commit: `8eeb87f77de200f0acc857908e2da34ce09997f1`
- A2A2H verification: backend Python AST parse passed; frontend `node --check` passed; required `grep -RIn "cto\|/opt/cto\|husband.llc" services scripts frontend` returned no CTO-specific strings.
- Updated `wiki/A2A2H_LAST_SYNC.md` to the CTO commit above.
