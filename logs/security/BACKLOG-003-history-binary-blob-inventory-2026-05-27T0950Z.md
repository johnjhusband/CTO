# BACKLOG-003 git-history binary/blob inventory — 2026-05-27T09:50Z

## Scope
Public-repo history audit support. This tick added and ran a metadata-only helper that inventories binary or large blobs reachable from git history. It did not print blob contents, rotate credentials, rewrite history, change infrastructure, restart services, spend money, or delegate semantic work to Hermes.

## Required pre-checks
- A2A2H per-tick drift check: clean; no upstream-eligible CTO commits since `27abb1203d2a13253e8c1b7e9658518d77794236`.
- Git state before selection: `/opt/cto` and `/opt/a2a2h` clean and synced.
- Services: no failed user units; OpenClaw Gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers active.
- Hermes provider circuit: open/degraded with `agent_incomplete_provider_NoneType`; no Hermes semantic delegation was attempted.
- Backlog completion scan: P0 credential/history work remains blocked on coordinated rotation/scrub; PWA P0 items remain pending phone/device confirmation; no item was safely closable from disk evidence.

## Action
Added `scripts/security/list-history-binary-blobs.py`, a value-silent git-history inventory helper. It reports object id prefixes, sizes, paths, and whether a blob appears binary or large text. It never emits blob contents.

## Verification
- `python3 -m py_compile scripts/security/list-history-binary-blobs.py` passed.
- Ran `python3 scripts/security/list-history-binary-blobs.py --min-size 262144 --limit 120` successfully.
- Existing local pre-commit and pre-push guards ran during commit/push.

## Inventory summary
`history_blob_inventory total_blobs=1060 flagged=10 binary=10 large_text=0 min_size=262144`

## First metadata rows
```text
binary oid=510f6aa9ba91 size=897024 path=.memweave/index.sqlite
binary oid=97a04d6fab90 size=40737 path=services/pwa/backend/server.py
binary oid=4f4cfd0bd464 size=25770 path=logs/install/install-20260511-164935.log
binary oid=997f1b45b7fe size=20480 path=chat.db
binary oid=61bb06748b14 size=19410 path=scripts/install-cto.sh
binary oid=8e36674a1317 size=11407 path=PRD.md
binary oid=b9490536bd31 size=11293 path=BACKLOG.md
binary oid=33663d40dbd6 size=9080 path=services/pwa/frontend/app.js
binary oid=228a8e44c404 size=3847 path=services/pwa/frontend/icon-512.png
binary oid=06208dbe1ebf size=1093 path=services/pwa/frontend/icon-192.png
```

## Result
BACKLOG-003 now has a reusable source-visible helper for non-destructive binary/large-blob history inventory. The broader audit remains open: flagged historical blobs still need manual metadata triage, known BACKLOG-005 history scrub remains coordinated-window blocked, and GitHub-side secret scanning/push-protection settings still need confirmation.
