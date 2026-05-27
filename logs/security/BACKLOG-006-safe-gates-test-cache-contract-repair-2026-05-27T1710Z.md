# BACKLOG-006 safe gates + PWA cache-version test-contract repair — 2026-05-27T17:10Z

- Required A2A2H per-tick upstream-port check ran first: `git log 6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no upstream-eligible drift, so no A2A2H port was required.
- Hermes semantic delegation was skipped because `/opt/cto/.cache/hermes-work-pump-provider-failure.json` still reports `agent_incomplete_provider_NoneType`; recent journals show repeated provider `NoneType` failures and a recovered/restarted gateway with health OK.
- Highest safe P0 work selected: BACKLOG-006 non-destructive credential/access-control verification.
- First safe-gate run failed because PWA regression tests still hard-coded `cto-shell-v24` while the current service worker is `cto-shell-v25` after John's PWA timestamp-date P0 fix. This was a test-contract drift, not a runtime secret/access-control failure.
- Repaired tests to assert a valid `cto-shell-v<digits>` cache contract instead of pinning a stale exact version in `tests/test_pwa_routing.py` and `tests/test_pwa_voice_ui.py`.
- Verification after repair: targeted stale-cache tests passed, then `scripts/security/run-safe-security-gates.sh` passed end-to-end: source-visible secret artifact guard, operational redaction over logs plus chat.db, install secret-handling guard, credential preflight/smoke syntax and runtime names-only checks, local health smoke, 9 redaction tests, 38 PWA auth/routing tests, and 1 voice UI test.
- No credentials were printed, rotated, revoked, or read by value; no infrastructure or paid resources changed.
