# BACKLOG-005 coordinated history-scrub runbook — 2026-05-27T03:30Z

## Selected item
P0 security/access-control: BACKLOG-005 remains open because the runtime VAPID key has been rotated and verified, but the public git history still needs a coordinated destructive rewrite or explicit risk acceptance.

## Current safe state
- Runtime VAPID/Web Push identity was rotated and server-side push delivery was verified earlier.
- Disposable local dry run already proved that removing only `.vapid/private.pem` from rewritten history clears the metadata-only history marker scanner.
- This tick did **not** rewrite `/opt/cto`, force-push, revoke credentials, delete data, or mutate runtime state.

## Stop boundary
Do not run the real scrub from an unattended work-pump tick. The real operation is destructive to public git history and must happen only in an explicit coordinated window with John aware that clones/forks need repair or reclone.

## Coordinated window checklist
1. Announce the history-rewrite window and pause normal pushes to `johnjhusband/CTO`.
2. Confirm a clean local tree and pushed latest work:
   - `git status --short --branch`
   - `git fetch origin`
   - `git log --oneline --max-count=5`
3. Snapshot/backup before rewrite:
   - create a local backup branch/tag pointing at current `origin/master`;
   - keep runtime key backup files ignored and local only;
   - do not copy or print secret values.
4. Prefer `git-filter-repo` or BFG for the real rewrite. Target scope is narrow: remove `.vapid/private.pem` from all refs. If tooling is not installed, install choice must be deliberate in the coordinated window; do not silently use unreviewed tooling.
5. Verify the rewritten candidate before publishing:
   - `scripts/security/check-git-history-secret-markers.sh <rewritten-repo>`
   - `git rev-list --all -- .vapid/private.pem` returns zero revisions.
6. Force-push only after verification and explicit go/no-go confirmation for the window.
7. Immediately after force-push, verify public clone state in a fresh disposable clone:
   - history marker scan passes;
   - `.vapid/private.pem` does not appear in history;
   - working tree does not contain runtime secret material.
8. Communicate reclone/repair guidance: existing clones must reclone or hard-reset to the rewritten `origin/master`; stale branches may reintroduce the removed path if pushed.
9. Re-run `scripts/security/run-safe-security-gates.sh` in `/opt/cto`.
10. Only then update BACKLOG-005 to resolved, with the public verification evidence and any rollback/risk notes.

## Abort conditions
Abort before force-push if any of these occur:
- local tree is dirty with unrelated changes;
- history marker scan still reports markers after rewrite;
- unexpected paths beyond `.vapid/private.pem` would be removed;
- runtime push verification is broken;
- John has not confirmed the destructive window.

## Rollback posture
Before force-push, rollback is simply discarding the rewritten candidate and keeping `origin/master` unchanged. After force-push, rollback means pushing the backup ref back to `master`, which would intentionally restore the compromised history; use only if the rewrite breaks the repo and after acknowledging the security tradeoff.

## Status
BACKLOG-005 is still `dry_run_verified_pending_coordinated_history_scrub`. This artifact converts the remaining work into an explicit coordinated runbook, but final closure is still blocked on John-approved public history rewrite/force-push timing or documented risk acceptance.
