#!/usr/bin/env bash
# Fail if source-control-visible files contain obvious private-key or live-secret artifacts.
# This scans tracked, staged, and unignored untracked paths only; ignored runtime secret dirs
# such as .env, .vapid/, and .vapid-new/ are intentionally excluded to avoid exposing values.
set -euo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

fail=0
scanned=0

# File names that should never be source-visible unless explicitly allowlisted below.
secret_name_re='(^|/)(private|secret|credentials?|client_secret|token|id_rsa|id_ed25519)(\.|-|_|$)|\.pem$|\.key$|\.p12$|\.pfx$'
allow_name_re='(^|/)(example\.cto-secrets\.env|README|.*\.md|scripts/security/check-secret-artifacts\.sh|scripts/security/credential-rotation-plan\.sh)$'

# Content markers: print only path + marker name, never matching lines.
declare -a content_checks=(
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  '-----BEGIN OPENSSH PRIVATE KEY-----'
  'AKIA[0-9A-Z]{16}'
  'xox[baprs]-[0-9A-Za-z-]+'
  'gh[pousr]_[0-9A-Za-z_]{20,}'
  'sk-[A-Za-z0-9_-]{20,}'
)

# Use process substitution instead of a pipe so fail/scanned state is retained.
while IFS= read -r -d '' path; do
  [[ -f "$path" ]] || continue
  scanned=$((scanned + 1))

  if [[ "$path" =~ $secret_name_re && ! "$path" =~ $allow_name_re ]]; then
    printf 'SECRET_ARTIFACT_NAME %s\n' "$path" >&2
    fail=1
  fi

  if [[ $(wc -c < "$path") -gt 1048576 ]]; then
    continue
  fi

  for marker in "${content_checks[@]}"; do
    if LC_ALL=C grep -Eq "$marker" "$path" 2>/dev/null; then
      printf 'SECRET_ARTIFACT_CONTENT %s marker=%s\n' "$path" "$marker" >&2
      fail=1
    fi
  done
done < <(git ls-files -co --exclude-standard -z)

if [[ "$fail" -ne 0 ]]; then
  printf 'Secret artifact guard failed after scanning %d source-visible files.\n' "$scanned" >&2
  exit 1
fi

printf 'Secret artifact guard passed: scanned %d source-visible files.\n' "$scanned"
