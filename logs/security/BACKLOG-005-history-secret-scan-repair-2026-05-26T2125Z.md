# BACKLOG-005 git-history secret scan repair — 2026-05-26T21:25Z

## Selected item
BACKLOG-005 P0 security/access-control: leaked VAPID/Web Push private key remains in public git history after runtime rotation was verified.

## Work performed
Repaired the non-destructive git-history marker scanner at `scripts/security/check-git-history-secret-markers.sh`.

The prior scanner had two correctness problems:

1. It passed regexes beginning with `-` directly to `git grep`, so the private-key marker was interpreted as an option and silently ignored under `|| true`.
2. It reported installer template references such as `KEY=${KEY}` as secret-looking env assignments, which obscured the real history finding.

The scanner now:

- uses `git grep -e` for marker patterns, including private-key block headers;
- inspects matching lines only in process memory and still emits only revision/marker/path metadata, never values;
- suppresses installer shell-template matches where the value is a variable expansion such as `${KEY}`;
- allowlists scanner/test files that intentionally contain marker regex fixtures.

## Verification

```text
$ bash -n scripts/security/check-git-history-secret-markers.sh
ok

$ scripts/security/check-git-history-secret-markers.sh
HISTORY_SECRET_MARKER rev=5fe0e4a9c210 marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=817b91736370 marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=bb60cb1e6658 marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=1c631b8ede17 marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=33251919140b marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=79c0b370c1a9 marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=4c2b18d597e6 marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=8bbbcdf8431b marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=612d214f7d8a marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=3ebe7e300cd7 marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=051717cbe6a3 marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=df13224728d3 marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=11c03a38b7d1 marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=9f1b384d56e1 marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=6e134ac51b5b marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=134b644cb1ce marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=a6108420148d marker=private_key_block path=.vapid/private.pem
HISTORY_SECRET_MARKER rev=25029cc38a65 marker=private_key_block path=.vapid/private.pem
Git history secret marker scan found 18 marker(s) across 185 revision(s). Values were not printed.
```

`git-filter-repo` and `bfg` are not installed on this host. Even if installed, rewriting public history remains a destructive/coordinated operation and is not safe for an unattended pump tick.

## Result
The remaining BACKLOG-005 exposure is now verified by a value-safe scanner: `.vapid/private.pem` exists in 18 historical revisions. Runtime rotation and push delivery are already verified; public-history scrub or documented risk acceptance still requires coordinated approval because it rewrites shared history.
