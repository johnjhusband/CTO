# BACKLOG-006 rotation triage packet

- Timestamp: 2026-05-27T19:45:00Z
- Selected item: BACKLOG-006 (P0 security / credential rotation and secret-handling redesign)
- A2A2H per-tick check: clean; no upstream-eligible CTO commits after `6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3`.
- Hermes delegation: skipped because `/opt/cto/.cache/hermes-work-pump-provider-failure.json` shows the provider circuit open after repeated `agent_incomplete` / `NoneType` failures.
- Secret handling: this packet contains only redacted/sanitized finding classes and file paths, no token values, key material, request headers, env values, or raw scanner output.

## Current verified evidence

- Full-history scanner artifact: `logs/security/history-secret-scan-20260527T1925Z/`.
- Sanitized scanner counts: gitleaks reported 10 findings (`generic-api-key`: 9, `private-key`: 1); TruffleHog reported 1 unverified `PrivateKey` finding.
- Independent scanner overlap: both scanners point at historical `.vapid/private.pem` as key material still reachable in public git history.
- Generic-key locations are historical install/security logs and VAPID evidence files, not current `.env` output in the committed tree.
- Safe gates already exist and pass before commits, but they are not a substitute for rotation/history decision work.

## Rotation/decision matrix

| Finding class | Runtime risk | Safe action now | Requires John / external step |
|---|---:|---|---|
| Historical `.vapid/private.pem` in git history | High if the corresponding public key/subscriptions remain in use | Treat current VAPID identity as burned; keep history-scrub path ready; do not paste key material anywhere | Confirm/perform production push identity rotation and decide whether to rewrite public git history |
| Historical `generic-api-key` scanner hits in install/security logs | Medium until manually classified | Keep sanitized finding list only; do not publish raw scanner contexts | Manual review of raw historical contexts in a controlled rotation window, then rotate any matching live services |
| Long-lived `/opt/cto/.env` live tokens | High if copied into logs/process traces | Continue using file-based local secret storage only; avoid shell `echo` propagation in clone scripts | Coordinated rotation of Hetzner/GitHub/OpenAI/OpenClaw/Hermes/PWA credentials |
| Clone/candidate secret propagation | Medium/high during clone-test runs | Prefer secure file transfer or generated candidate env files with strict permissions; never commit generated env files | Clone installer redesign plus parity test before next paid candidate |

## Blocked boundary

Actual credential rotation is intentionally not performed in this autonomous tick because it would affect live external services, OAuth/provider access, push identity, and/or production availability. The safe work this tick is the triage packet that converts the scanner output into a concrete rotation/history decision plan without exposing secrets.

## Next safe step

Create a no-secret `scripts/security/credential-rotation-plan.sh --check-only` verifier that confirms required rotation artifacts and permissions without printing values, then use it as the preflight for the coordinated rotation window.
