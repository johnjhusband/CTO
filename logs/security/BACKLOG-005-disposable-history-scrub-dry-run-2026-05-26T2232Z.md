# BACKLOG-005 disposable history-scrub dry run — 2026-05-26T22:32Z

## Selected item
P0 security/access-control: BACKLOG-005 still has a public git-history exposure after runtime Web Push identity rotation and server-side push verification.

## Why this was selected
The real remediation requires public history rewrite and force-push coordination, which is destructive and unsafe for an unattended work-pump tick. The safe next step was to prove the exact scrub procedure in a disposable local clone without changing `/opt/cto`, `origin/master`, live credentials, subscriptions, or runtime state.

## Repair/artifact
Added `scripts/security/dry-run-vapid-history-scrub.sh`.

The helper:
- clones `/opt/cto` to a temporary directory with `--no-hardlinks`;
- rewrites only the known historical path `.vapid/private.pem` in the disposable clone;
- removes filter-branch backup refs so `rev-list --all` does not keep the old secret-bearing refs alive;
- runs the existing metadata-only history marker scanner against the rewritten candidate;
- prints only counts, path metadata, and pass/fail status — never secret values;
- deletes the temporary clone on exit.

`git-filter-repo` or BFG remains preferred for the real coordinated public scrub window. This dry run uses built-in `git filter-branch` only to validate target-path scope on the production host without installing new tooling or touching the live checkout.

## Verification
```text
chmod +x scripts/security/dry-run-vapid-history-scrub.sh && scripts/security/dry-run-vapid-history-scrub.sh

dry_run_workdir=/tmp/cto-history-scrub-dry-run/repo.GsRx5p
source_root=/opt/cto
target_path=.vapid/private.pem
before_revisions_with_target_path=2
after_revisions_with_target_path=0
Git history secret marker scan passed: scanned 198 revision(s); no markers found.
dry-run passed: disposable rewritten history removes target path and marker scanner passes
```

## Stop boundary
BACKLOG-005 remains blocked for final resolution on an explicit coordinated destructive history-scrub window: rewrite public history, force-push, and collaborator reclone guidance must not run from an unattended pump tick.
