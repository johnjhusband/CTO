# BACKLOG-005 history scrub status reconciliation — 2026-05-26T22:31Z

## Selected item
P0 security/access-control: BACKLOG-005 historical VAPID private-key exposure.

## Why selected
Runtime VAPID rotation and provider-submit push verification are complete, and a disposable history-scrub dry run now proves the known `.vapid/private.pem` path can be removed from rewritten history without leaving scanner markers. The backlog status still only said runtime push was verified, which understated the safe preparation already completed for the destructive history scrub.

## Work performed
- Re-ran the disposable dry-run helper from `/opt/cto`; it cloned the repo with `--no-hardlinks`, rewrote only `.vapid/private.pem` in the temporary clone, removed backup refs, and ran the metadata-only history marker scanner.
- Re-ran `scripts/security/run-safe-security-gates.sh` after the dry run.
- Updated BACKLOG-005 status to `dry_run_verified_pending_coordinated_history_scrub` in both `BACKLOG.md` and `logs/backlog/BACKLOG-005.json`.

## Verification
```text
scripts/security/dry-run-vapid-history-scrub.sh
before_revisions_with_target_path=2
after_revisions_with_target_path=0
Git history secret marker scan passed: scanned 199 revision(s); no markers found.
dry-run passed: disposable rewritten history removes target path and marker scanner passes

scripts/security/run-safe-security-gates.sh
Secret artifact guard passed: scanned 256 source-visible files.
Operational secret redaction check passed: scanned 123 file(s) plus chat.db; no unredacted markers found.
Redaction unit tests: 6/6 passed.
PWA auth/routing regression tests: 26/26 passed.
Safe security gates passed.
```

## Stop boundary
Final BACKLOG-005 remediation still requires an explicit coordinated destructive public-history scrub window: rewrite public history, force-push, and provide reclone guidance. This tick did not rewrite `/opt/cto`, change `origin/master`, rotate credentials, or print/store secret values.
