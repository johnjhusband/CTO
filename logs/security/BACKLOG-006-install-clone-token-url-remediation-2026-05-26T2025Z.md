# BACKLOG-006 Install Clone Token URL Remediation — 2026-05-26T20:25Z

## Selected item
BACKLOG-006 (P0 security): reduce live credential propagation risk in clone/install automation without rotating credentials or rewriting history.

## Safe repair completed
Updated `scripts/install.sh` Section 8 so the fresh-clone step no longer embeds `GITHUB_TOKEN` in:

- the `git clone` URL,
- the remote shell command string,
- the process arguments used for `git clone`, or
- the persisted `origin` remote URL.

The clone path now uses a short-lived `GIT_ASKPASS` helper on the candidate host. The helper reads `/opt/cto/.env` only when Git asks for credentials, is mode `0700`, and is deleted by an `EXIT` trap. After clone, `origin` is reset to the plain HTTPS repo URL.

## Verification
Non-destructive checks run from `/opt/cto`:

```text
$ bash -n scripts/install.sh scripts/install-cto.sh scripts/security/check-git-history-secret-markers.sh scripts/security/run-safe-security-gates.sh
# passed with no output

$ grep -RIn "oauth2:.*GITHUB_TOKEN\|GITHUB_TOKEN.*@\|git remote set-url origin .*GITHUB_TOKEN" scripts/install.sh scripts/install-cto.sh || true
# no matches

$ scripts/security/run-safe-security-gates.sh
Secret artifact guard passed: scanned 227 source-visible files.
Operational secret redaction check passed: scanned 96 file(s) plus chat.db; no unredacted markers found.
Redaction unit tests: 5/5 passed.
PWA auth/routing regression tests: 18/18 passed.
Safe security gates passed.
```

## Remaining BACKLOG-006 work
This repair reduces future clone/install leakage risk, but does **not** rotate live credentials, revoke old tokens, invalidate sessions, or rewrite public git history. Those remain coordinated P0 work because they can interrupt production access and require John-approved cutover timing.
