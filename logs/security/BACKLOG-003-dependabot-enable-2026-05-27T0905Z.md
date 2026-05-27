# BACKLOG-003 Dependabot dependency monitoring — 2026-05-27T09:05Z

## Scope
Public-repo/deployment security audit hygiene. This tick enabled repository-native dependency update monitoring for source-visible package manifests. It did not rotate credentials, rewrite history, change infrastructure, restart services, spend money, or delegate semantic work to Hermes.

## Required pre-checks
- A2A2H per-tick drift check: no upstream-eligible CTO commits since `27abb1203d2a13253e8c1b7e9658518d77794236`; no port required.
- Git state: `/opt/cto` and `/opt/a2a2h` were clean and synced before selection.
- Services: no failed user units; OpenClaw Gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers were active.
- Hermes provider circuit: open after repeated provider-side `agent_incomplete_provider_NoneType`; no Hermes semantic delegation was attempted.
- Backlog completion scan: P0 credential/history work remains coordinated-window blocked; P0 PWA voice/background/audit items remain pending John/device evidence; no item was safely closable from disk evidence.

## Action
Added `.github/dependabot.yml` with weekly checks for:
- `/lib/a2a-secure`
- `/plugins/openclaw-secure-a2a`
- `/scripts/namecheap-playwright`
- `/ui/cto-chat`
- GitHub Actions at repository root

## Verification
- Enumerated source-visible dependency manifests before writing the config.
- Ran a local structure check for the expected Dependabot entries and whitespace.
- Existing local pre-commit and pre-push security guards ran and passed during commit/push.

## Result
GitHub can now raise dependency update PRs for the CTO repo's source-visible npm package roots and GitHub Actions. BACKLOG-003 remains open for full-history scanning, GitHub secret-scanning/push-protection settings, and deeper live deployment hardening.
