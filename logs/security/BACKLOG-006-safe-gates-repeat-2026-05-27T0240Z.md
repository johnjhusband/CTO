# BACKLOG-006 safe credential-hygiene verification — 2026-05-27T02:40Z

## Selected item
BACKLOG-006 remains the highest-priority safe queue item that can be advanced without unattended live credential rotation, provider revocation, or public-history rewrite.

## A2A2H per-tick check
- Tracker read: `wiki/A2A2H_LAST_SYNC.md` last synced CTO SHA `bfe5ad51f99dd15019ebb3dbd510b73d0ea49072`.
- Command: `git log bfe5ad51f99dd15019ebb3dbd510b73d0ea49072..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py`.
- Result: no upstream-eligible CTO commits since the tracker SHA; no A2A2H port required this tick.

## Recent failed verification
- Recent failed artifact found: `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T023417Z.md`.
- Service health is green (`cto-a2a-registry`, `cto-hermes-a2a-sidecar`, `cto-pwa-backend`, `openclaw-gateway`; safe security smoke also checked `hermes-gateway`).
- The Hermes failure is a provider-side `agent_incomplete`/`NoneType` 502 on A2A POST while `/health` remains OK; no restart was forced from this tick because the Hermes work-pump recovery path had already honored its cooldown.

## Verification run
Ran `scripts/security/run-safe-security-gates.sh`.

Passed gates:
- Secret artifact guard: scanned 308 source-visible files.
- Operational secret redaction check: scanned 170 file(s) plus chat.db; no unredacted markers.
- Install secret-handling guard.
- Credential rotation preflight syntax.
- Credential rotation smoke syntax.
- Credential rotation preflight runtime check: required credential names present/nonempty; `.env` owner `cto:cto`, mode `600`; dependent services active; result `ready_for_coordinated_rotation_window`.
- Credential rotation smoke check: dependent services active and local health endpoints OK for OpenClaw Gateway, Hermes Gateway, Hermes A2A sidecar, and PWA backend.
- Redaction unit tests: 8/8.
- PWA auth/routing regression tests: 28/28.
- PWA voice UI regression test: 1/1.

## Status
Safe non-destructive credential-hygiene gates remain green. BACKLOG-006 is still open because closure requires a coordinated live credential rotation/revocation window and any approved broader log/history cleanup. This tick did not print or store secret values.
