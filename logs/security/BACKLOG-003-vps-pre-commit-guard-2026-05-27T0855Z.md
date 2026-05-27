# BACKLOG-003 VPS pre-commit security guard — 2026-05-27T08:55Z

## Scope
Future-commit discipline for the public CTO repo. This tick installed a local VPS pre-commit guard and committed its source-visible template. It did not rotate credentials, rewrite history, change infrastructure, spend money, or delegate semantic work to Hermes.

## Required pre-checks
- A2A2H per-tick drift check: no upstream-eligible CTO commits since `27abb1203d2a13253e8c1b7e9658518d77794236`; no port required.
- Git state: `/opt/cto` and `/opt/a2a2h` were clean and synced before selection.
- Services: no failed user units; OpenClaw Gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers were active.
- Hermes provider circuit: open after repeated provider-side `agent_incomplete_provider_NoneType`; no Hermes semantic delegation was attempted.
- Backlog completion scan: P0 credential/history work remains coordinated-window blocked; P0 PWA voice/background/audit items remain pending John/device evidence; no item was safely closable from disk evidence.

## Action
Added a versioned hook template at `scripts/security/git-hooks/pre-commit` and installed it as `.git/hooks/pre-commit` on the VPS repo.

The hook blocks local commits unless both value-silent checks pass:
1. `scripts/security/check-secret-artifacts.sh` — scans source-visible tracked/staged/unignored files for private-key or live-secret artifacts.
2. `scripts/security/redact-operational-secrets.py --check` — scans logs plus `chat.db` for unredacted operational secret markers.

This complements the existing pre-push guard from `logs/security/BACKLOG-003-vps-pre-push-guard-2026-05-27T0835Z.md`; pre-commit catches mistakes earlier, pre-push remains a final VPS-side outbound gate.

## Verification
- `bash -n scripts/security/git-hooks/pre-commit .git/hooks/pre-commit` passed.
- `.git/hooks/pre-commit` passed locally before commit.
- The hook also ran during the commit and passed.
- Existing `.git/hooks/pre-push` ran during push and passed.
- Hook outputs remained value-silent: scan status only, no secret values.

## Result
The VPS now has active pre-commit and pre-push guards against future source-visible secret artifacts or unredacted operational-log leaks. BACKLOG-003 remains open for broader full-history, GitHub-side, dependency, and public attack-surface audit work.
