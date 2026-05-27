# A2A2H Maintenance Protocol

**Last updated:** 2026-05-26
**Authoritative source for:** how CTO keeps the public A2A2H extraction in sync
**Owner:** OpenClaw (strategy) + Hermes (port execution). Hermes' work-pump and OpenClaw's continuous-work pass MUST include the upstream-port check on every tick. Claude Code does NOT execute ports; it surfaces drift.

## What A2A2H is

A2A2H (`https://github.com/johnjhusband/a2a2h`, public) is a standalone extraction of the chat-bridge layer from CTO. It is meant to be reusable by others who want an Agent-to-Agent-to-Human chat bridge without needing the full CTO machinery. Repo path on the VPS: `/opt/a2a2h/`.

## The problem this protocol solves

Between 2026-05-25 and 2026-05-26, CTO's chat-bridge layer received ~15 visible improvements (cookie auth, fail-closed hardening, `/reset` route, durable `/chat-log/`, A2A audit transcript, token rotation grace, URL-credential log redaction, push notification end-to-end, A2A delegation session-per-call fix, and more). **None of them flowed to A2A2H.** Result: A2A2H is now a stale snapshot drifting toward uselessness.

A maintenance process is required so the public extraction stays a credible reference implementation.

## Files that ARE upstream of A2A2H

When any of these CTO paths change, an A2A2H port is required:

| CTO path | A2A2H path | Genericization rules |
|---|---|---|
| `services/pwa/` | `services/pwa/` | Replace `/opt/cto/` with configurable `${A2A2H_ROOT}` or `/opt/a2a2h/`; rename systemd units `cto-*` → `a2a2h-*`; drop CTO-specific imports (e.g., `chat.db` import paths stay but reference must be parameterized) |
| `services/hermes_a2a_sidecar/` | `services/hermes_a2a_sidecar/` | Same path/unit/import rewrites |
| `services/a2a_delegate/` | `services/a2a_delegate/` | Same |
| `scripts/cache-keepalive.sh` | `scripts/cache-keepalive.sh` | Same |
| `services/pwa/frontend/` | `services/pwa/frontend/` | UI strings: strip "CTO" specifically (e.g., `<title>CTO chat logs</title>` → `<title>A2A2H chat logs</title>`); cache name `cto-shell-v*` → `a2a2h-shell-v*` |
| `services/chat/db.py` (if it changes shape) | `services/chat/db.py` | Same |
| Caddyfile snippets for `cto.husband.llc` | Generic example Caddyfile | Replace host with `{$A2A2H_HOST}` placeholder |

## Files that are NOT upstream

Never port:
- `logs/decisions/`, `logs/backlog/`, `logs/repairs/`, `logs/security/`, `logs/research/`, `logs/clone/`, `logs/install/` (all CTO operational state)
- `BACKLOG.md`, `MEMORY.md`, `SOUL.md`, `HEARTBEAT.md`, `HERMES_ROLE.md`, `OPENCLAW_ROLE.md`, `USER.md`, `PRD.md` (CTO meta)
- `scripts/hermes-work-pump.sh`, `scripts/openclaw-work-pump.sh`, `scripts/repair/*`, `scripts/security/*` (CTO operational scripts)
- `wiki/*` (CTO-specific knowledge)
- `versions/`, `raw/`, `.env*`, `.openclaw/`, `.engram/`, `.cache/`, `.vapid*/` (runtime/secrets)
- `services/openclaw-*`, `plugins/openclaw-*` (CTO architecture-specific)

## The maintenance protocol — per-tick check

On EVERY Hermes work-pump tick AND every OpenClaw continuous-work tick, the agent MUST perform this check before selecting a new item:

1. **List CTO commits since A2A2H was last synced.** Read `wiki/A2A2H_LAST_SYNC.md` for the last-synced CTO SHA (initial value: `1f71f58` — the initial extraction commit). Run `git log <LAST_SYNC>..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` in `/opt/cto`. If empty: no port needed; record this in the tick artifact and proceed. If non-empty: port is required.
2. **For each commit needing a port:**
   - Identify the changed files using the upstream table above
   - Apply the genericization rules
   - Apply the change to `/opt/a2a2h/` (clone, branch, edit, test if possible)
   - Commit with subject prefix `[port from CTO <short_sha>]` and original CTO commit subject
   - Push to `origin/master` on A2A2H
3. **Update `wiki/A2A2H_LAST_SYNC.md` in CTO** with the new last-synced SHA. Commit to CTO and push.
4. **Write a one-line entry in the tick artifact** under `logs/repairs/` summarizing the port (`Ported CTO <sha> to A2A2H as <a2a2h_sha>`).
5. If a port fails (genericization unclear, tests fail, file mapping ambiguous), open a CTO BACKLOG entry under `type: upstream-pr-needed` describing the blocker and defer that specific port. Do NOT mark the work done until the port is on A2A2H origin.

## One-time backfill required (2026-05-26)

Hermes/OpenClaw must port every CTO commit since `1f71f58` (initial extraction) that touched the upstream files. Estimated 10–15 commits. Track progress in a single repair log `logs/repairs/a2a2h-backfill-2026-05-26.md` and update as you go. After the backfill, A2A2H origin should be functionally equivalent to CTO's chat-bridge layer.

## Verification

After every port, run (on the VPS, in `/opt/a2a2h/`):
- `python3 -c "import ast; ast.parse(open('services/pwa/backend/server.py').read())"` — syntax sanity
- If tests exist in A2A2H: run them. If not yet: port the test files too.
- `grep -nR "cto\|/opt/cto\|husband.llc" services/ scripts/ frontend/ 2>/dev/null` — confirm zero CTO-specific strings leaked through the rename rules. Any hit is a port bug — fix before pushing.

## What's NOT in scope

- Building or maintaining a CI pipeline for A2A2H — that's a separate future item
- Versioning/tagging A2A2H releases — also future
- Documenting A2A2H independently (its own README/CONTRIBUTING) — yes eventually, but not part of the per-tick port check

## Where this protocol lives in the agents' workflow

The agents must reference this doc in:
- `HERMES_ROLE.md` — under continuous-work-policy section, add: "On every work-pump tick, check `wiki/A2A2H_MAINTENANCE.md` and execute the per-tick check before selecting a backlog item."
- `OPENCLAW_ROLE.md` — same addition.
- `wiki/continuous-work-policy.md` — add the per-tick A2A2H check as policy item.

Claude Code's monitor sweep will include A2A2H divergence in every report so drift is visible immediately.
