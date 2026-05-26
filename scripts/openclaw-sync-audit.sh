#!/usr/bin/env bash
# Audit CTO repo sync/secrets state for OpenClaw's daily scheduler job.
# Prints paths/status only; never prints secret contents.
set -euo pipefail

REPO_DIR="${1:-/opt/cto}"
cd "$REPO_DIR"

git fetch origin master --quiet

branch_line="$(git status --short --branch)"
dirty_lines="$(git status --short --untracked-files=all)"
divergence="$(git rev-list --left-right --count HEAD...origin/master)"
ahead="${divergence%%$'\t'*}"
behind="${divergence##*$'\t'}"

secret_untracked="$(git ls-files --others --exclude-standard -z -- \
  '.env' '.env.*' '.vapid*' '*.pem' '*.key' \
  | tr '\0' '\n' | sed '/^$/d')"

if [[ -z "$dirty_lines" && "$ahead" == "0" && "$behind" == "0" && -z "$secret_untracked" ]]; then
  echo "OPENCLAW_SYNC_AUDIT_CLEAN branch=${branch_line#\#\# }"
  exit 0
fi

echo "OPENCLAW_SYNC_AUDIT_DIRTY"
echo "branch=${branch_line#\#\# }"
echo "divergence_ahead=${ahead} divergence_behind=${behind}"
if [[ -n "$dirty_lines" ]]; then
  echo "dirty_paths:"
  printf '%s\n' "$dirty_lines"
fi
if [[ -n "$secret_untracked" ]]; then
  echo "untracked_secret_like_paths:"
  printf '%s\n' "$secret_untracked"
fi
exit 2
