#!/usr/bin/env bash
# Dry-run BACKLOG-005 git-history scrub in a disposable local clone.
# This does not modify /opt/cto, origin/master, live credentials, or runtime state.
set -euo pipefail

SOURCE_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
CHECKER="$SOURCE_ROOT/scripts/security/check-git-history-secret-markers.sh"
TARGET_PATH=".vapid/private.pem"

if [[ ! -x "$CHECKER" ]]; then
  echo "missing executable checker: $CHECKER" >&2
  exit 2
fi

TMP_PARENT="${TMPDIR:-/tmp}/cto-history-scrub-dry-run"
mkdir -p "$TMP_PARENT"
WORKDIR="$(mktemp -d "$TMP_PARENT/repo.XXXXXX")"
cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

printf 'dry_run_workdir=%s\n' "$WORKDIR"
printf 'source_root=%s\n' "$SOURCE_ROOT"
printf 'target_path=%s\n' "$TARGET_PATH"

git clone --quiet --no-hardlinks "$SOURCE_ROOT" "$WORKDIR/repo"
cd "$WORKDIR/repo"

before_count="$(git rev-list --all -- "$TARGET_PATH" | wc -l | tr -d ' ')"
printf 'before_revisions_with_target_path=%s\n' "$before_count"

# git-filter-repo/BFG are preferred for a real coordinated scrub window. This
# dry-run intentionally uses built-in git-filter-branch so the production host
# can validate the exact target path without installing tooling or rewriting the
# live checkout. Suppress value output; only metadata is printed.
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --force \
  --index-filter "git rm --cached --ignore-unmatch '$TARGET_PATH' >/dev/null 2>&1" \
  --prune-empty --tag-name-filter cat -- --all >/dev/null 2>&1

# Remove filter-branch backup refs so the marker scanner's rev-list --all sees
# only the rewritten candidate history.
git for-each-ref --format='%(refname)' refs/original/ | while read -r ref; do
  [[ -n "$ref" ]] && git update-ref -d "$ref"
done
git reflog expire --expire=now --all
git gc --prune=now --quiet

after_count="$(git rev-list --all -- "$TARGET_PATH" | wc -l | tr -d ' ')"
printf 'after_revisions_with_target_path=%s\n' "$after_count"

if "$CHECKER" "$WORKDIR/repo" >/tmp/cto-history-scrub-marker-check.$$ 2>&1; then
  marker_status=0
else
  marker_status=$?
fi
sed -n '1,40p' /tmp/cto-history-scrub-marker-check.$$
rm -f /tmp/cto-history-scrub-marker-check.$$

if [[ "$after_count" != "0" ]]; then
  echo "dry-run failed: target path still appears in rewritten history" >&2
  exit 1
fi
if [[ "$marker_status" != "0" ]]; then
  echo "dry-run failed: marker scanner still reports history markers" >&2
  exit "$marker_status"
fi

echo "dry-run passed: disposable rewritten history removes target path and marker scanner passes"
