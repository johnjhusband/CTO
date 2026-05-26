# GitHub push credential repair — 2026-05-26

## Problem
`git push` from `/opt/cto` failed with:

`fatal: could not read Username for 'https://github.com': No such device or address`

The repository remote is HTTPS (`https://github.com/johnjhusband/CTO.git`), `gh` is not installed on the VPS, and no global git credential helper was configured. In a non-interactive Hermes/PWA runtime, git could not prompt for a GitHub username/password.

## Fix applied
- Parsed `GITHUB_TOKEN` from `/opt/cto/.env` without printing the secret.
- Configured persistent git credentials with `git config --global credential.helper store`.
- Wrote `~/.git-credentials` with a GitHub HTTPS credential for `johnjhusband` and chmod `0600`.

## Verification
- `git config --global credential.helper` returns `store`.
- `git ls-remote --heads origin master` succeeds and returns origin/master SHA prefix `823308d7951d`.

## Secret handling
The token value is not written to repo files, repair logs, chat, or memory. It exists only in `/opt/cto/.env` and `~/.git-credentials`, both local runtime secret stores.

## Rollback
Remove `~/.git-credentials` or delete the GitHub line from it, then unset the helper with `git config --global --unset credential.helper`.
