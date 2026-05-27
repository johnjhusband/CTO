# BACKLOG-012 UI dependency update — 2026-05-27T22:15Z

## Scope
- [verified] Advanced BACKLOG-012 dependency hygiene by landing the previously validated combined UI dev-dependency update: `vite` 6.4.2 → 8.0.14 and `@vitejs/plugin-react` 4.7.0 → 6.0.2 in `ui/cto-chat`.
- [verified] Did not mutate production OpenClaw, spend money, touch infrastructure, read/store secrets, or delegate semantic work to Hermes.

## Required pre-checks
- [verified] A2A2H per-tick upstream-port check ran first: `git log 6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no upstream-eligible drift.
- [verified] Open/pending backlog scan found no safe closure from disk evidence alone. PWA confirmation items still require John/device-visible confirmation; credential/history-scrub items still require coordinated windows.
- [verified] Hermes provider circuit is open with `agent_incomplete_provider_NoneType`; no Hermes semantic delegation was attempted.

## Change
- [verified] Updated `ui/cto-chat/package.json` and `ui/cto-chat/package-lock.json` with the paired Vite/plugin-react major update. This follows the earlier validation result that Vite 8 is blocked standalone by the plugin peer range but build-viable when paired with plugin-react 6.

## Verification
- [verified] `npm --prefix ui/cto-chat ci --ignore-scripts` passed.
- [verified] `npm --prefix ui/cto-chat run build` passed under Vite 8.0.14.
- [verified] `npm --prefix ui/cto-chat audit --audit-level=high` passed with 0 vulnerabilities.
- [verified] `scripts/security/dependency-security-scan.sh` passed with 0 high/critical findings across discovered npm lockfile projects.

## Result
- [verified] The highest-risk visible dependency pair from the Dependabot queue is now represented directly in CTO's manifests/lockfile with local build and audit evidence.
- [verified] Production runtime remains unchanged; OpenClaw runtime upgrade still requires clone-test-replace validation before promotion.
