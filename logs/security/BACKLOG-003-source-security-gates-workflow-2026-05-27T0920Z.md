# BACKLOG-003 GitHub source security gates workflow — 2026-05-27T09:20Z

## Scope
Public-repo future-commit discipline and dependency/security hygiene. This tick added a GitHub Actions workflow for source-safe security checks. It did not rotate credentials, rewrite history, change infrastructure, restart services, spend money, or delegate semantic work to Hermes.

## Required pre-checks
- A2A2H per-tick drift check: no upstream-eligible CTO commits since `27abb1203d2a13253e8c1b7e9658518d77794236`; no port required.
- Git state: `/opt/cto` and `/opt/a2a2h` were clean and synced before selection.
- Services: no failed user units; OpenClaw Gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers were active.
- Hermes provider circuit: open after repeated provider-side `agent_incomplete_provider_NoneType`; no Hermes semantic delegation was attempted.
- Backlog completion scan: P0 credential/history work remains coordinated-window blocked; P0 PWA voice/background/audit items remain pending John/device evidence; no item was safely closable from disk evidence.

## Action
Added `.github/workflows/source-security-gates.yml` for push and pull request checks with read-only repository permissions.

The workflow runs only source-safe checks that do not need runtime secrets:
1. `scripts/security/check-secret-artifacts.sh`
2. `scripts/security/check-install-secret-handling.sh`
3. `python3 -m unittest -v tests/test_redact_operational_secrets.py`
4. `python3 -m unittest -v tests/test_pwa_routing.py tests/test_pwa_voice_ui.py`

It intentionally does not run the full `scripts/security/run-safe-security-gates.sh` suite because that includes live credential preflight and local service smoke checks that depend on the production VPS environment.

## Verification
- Local workflow structure check passed for required entries and read-only permissions.
- `scripts/security/check-secret-artifacts.sh` passed.
- `scripts/security/check-install-secret-handling.sh` passed.
- Local unit/regression tests passed: redaction, PWA routing, and PWA voice UI.
- Existing local pre-commit and pre-push security guards ran and passed during commit/push.

## Result
GitHub will now run source-safe security gates on pushes and pull requests, reducing the chance that future public commits introduce source-visible secrets or regress PWA access-control behavior. BACKLOG-003 remains open for full-history scanning, GitHub secret-scanning/push-protection settings, and deeper live deployment hardening.
