# BACKLOG-003 VPS pre-push security guard — 2026-05-27T08:35Z

## Scope
Future-commit discipline for the now-public CTO repo. This tick installed a local VPS pre-push guard and committed its source-visible template. It did not rotate credentials, rewrite history, change infrastructure, spend money, or delegate semantic work to Hermes.

## Required pre-checks
- A2A2H per-tick drift check: no upstream-eligible CTO commits since `27abb1203d2a13253e8c1b7e9658518d77794236`; no port required.
- Git state: `/opt/cto` and `/opt/a2a2h` were clean and synced before selection.
- Services: no failed user units; OpenClaw Gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers were active.
- Hermes provider circuit: open after repeated provider-side `agent_incomplete_provider_NoneType`; no Hermes semantic delegation was attempted.
- Backlog completion scan: P0 credential/history work remains coordinated-window blocked; P0 PWA voice/background/audit items remain pending John/device evidence; no item was safely closable from disk evidence.

## Action
Added a versioned hook template at `scripts/security/git-hooks/pre-push` and installed it as `.git/hooks/pre-push` on the VPS repo.

The hook blocks pushes unless both value-silent checks pass:
1. `scripts/security/check-secret-artifacts.sh` — scans source-visible tracked/staged/unignored files for private-key or live-secret artifacts.
2. `scripts/security/redact-operational-secrets.py --check` — scans logs plus `chat.db` for unredacted operational secret markers.

The hook intentionally does not run the git-history marker scan because the known historical VAPID leak is already tracked under BACKLOG-005 and would block all pushes until the coordinated destructive history scrub happens.

## Verification
- `bash -n scripts/security/git-hooks/pre-push .git/hooks/pre-push` passed.
- `.git/hooks/pre-push` passed locally.
- The hook output remained value-silent: it reported scan status only, not secret values.

## Result
The VPS now has an active pre-push guard against future source-visible secret artifacts or unredacted operational-log leaks. BACKLOG-003 remains open for broader full-history, GitHub-side, dependency, and public attack-surface audit work.
