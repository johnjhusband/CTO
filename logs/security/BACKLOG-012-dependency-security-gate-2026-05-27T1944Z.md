# BACKLOG-012 dependency/security scan gate — 2026-05-27T19:44Z

## Scope
Advance BACKLOG-012 (patch management / dependency hygiene) with a substantive, no-spend gate rather than another safe-gate-only tick.

## Required prechecks
- A2A2H per-tick upstream-port check: clean; no upstream-eligible CTO commits after `6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3`.
- Backlog completion scan: no open/pending item had enough new observable evidence to close this tick. PWA-visible items remain pending John/device verification; credential rotation/history scrub items remain blocked on coordinated external steps.
- Hermes delegation: skipped because `/opt/cto/.cache/hermes-work-pump-provider-failure.json` shows the provider circuit open after repeated `agent_incomplete` / `NoneType` failures.

## What changed
- Added `scripts/security/dependency-security-scan.sh`.
- Converted `scripts/security/npm-audit-all.sh` into a compatibility wrapper for the new gate.
- Wired the new scan into `scripts/validate-no-spend.sh` so dependency security scanning runs as part of clone-readiness/no-spend validation.

## Scan behavior
- Discovers committed `package-lock.json` projects.
- Runs `npm audit --package-lock-only --audit-level=high --json` per project.
- Fails the gate on high/critical audit findings or scan errors.
- Reports installed OpenClaw version versus npm latest without upgrading production in place.

## Current result
- `lib/a2a-secure`: 0 high, 0 critical.
- `plugins/openclaw-secure-a2a`: 0 high, 0 critical.
- `scripts/namecheap-playwright`: 0 high, 0 critical.
- `ui/cto-chat`: 0 high, 0 critical.
- OpenClaw runtime: installed `2026.5.7`, npm latest `2026.5.26`; upgrade remains intentionally clone-test-replace only, not in-place.

## Verification
- `scripts/security/dependency-security-scan.sh` → PASS: no high+ npm audit findings.
- `bash scripts/validate-no-spend.sh` → PASS, including the new dependency security scan section.

## Remaining BACKLOG-012 status
Open. This tick adds the recurring dependency/security scan gate. The OpenClaw runtime upgrade itself still needs a clone-test-replace candidate before promotion.
