# BACKLOG-005 Secret Artifact Guard Verification — 2026-05-26T19:14Z

## Selected item
BACKLOG-005 (P0 security): prevent VAPID/Web Push private keys and other live secret artifacts from entering source control while rotation/history-cleanup remains coordinated work.

## Why this was the safe P0 step
Live VAPID rotation, push subscription reset, credential revocation, and git-history rewrite can interrupt service, expose secrets if mishandled, or require coordination. This tick advanced the same P0 by verifying the non-destructive source-visible secret guard instead.

## Gate run
Command:

```bash
cd /opt/cto && scripts/security/check-secret-artifacts.sh
```

Result:

```text
Secret artifact guard passed: scanned 210 source-visible files.
```

## What the gate covers
- Scans tracked, staged, and unignored untracked files visible to git.
- Flags private-key-like filenames and common live-secret content markers.
- Prints only path and marker names on failure, not secret values.
- Excludes ignored runtime secret locations such as `.env`, `.vapid/`, and `.vapid-new/` to avoid exposing secret contents during verification.

## Remaining BACKLOG-005 work
Runtime VAPID rotation, push re-enrollment/verification, credential revocation, and any public git-history rewrite remain open coordinated security work.
