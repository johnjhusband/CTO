# BACKLOG-005 secret artifact guard script — 2026-05-26T19:10Z

## Selected item
BACKLOG-005 (P0 security): reduce risk of VAPID/Web Push private key and other credential artifacts being added to source control during rotation/cleanup work.

## Safe action taken
Added `scripts/security/check-secret-artifacts.sh`, a non-destructive source-visible artifact guard.

The guard scans only files visible to git (`git ls-files -co --exclude-standard`) so ignored runtime secret locations such as `.env`, `.vapid/`, `.vapid-new/`, `.cache/`, and `chat.db` remain excluded. It reports only paths and marker names, never secret values.

## Verification
Command:

```bash
cd /opt/cto && scripts/security/check-secret-artifacts.sh
```

Result:

```text
Secret artifact guard passed: scanned 209 source-visible files.
```

## Remaining BACKLOG-005 work
This does not rotate the live VAPID identity, clear push subscriptions, rotate broader service credentials, or rewrite public git history. Those remain coordinated P0 work because they touch live credentials, subscriptions, or destructive history operations.
