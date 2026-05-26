#!/usr/bin/env bash
# Verify clone/install scripts avoid obvious secret exposure through argv, URLs,
# local env artifacts, or source-visible logs. Metadata-only: never prints values.
set -euo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
INSTALL_SH="${ROOT}/scripts/install.sh"

if [[ ! -f "$INSTALL_SH" ]]; then
  printf 'Install secret-handling guard failed: missing scripts/install.sh\n' >&2
  exit 1
fi

fail=0
line_no=0
in_askpass=0
askpass_blocks=0

# Secret variable names that should not be emitted by shell directly except in
# the short-lived GIT_ASKPASS helper, where git reads the value over stdin.
secret_var_re='(TOKEN|KEY|SECRET|PASSWORD)'

while IFS= read -r line || [[ -n "$line" ]]; do
  line_no=$((line_no + 1))

  if [[ "$line" == *"<<'ASKPASS_SCRIPT'"* ]]; then
    in_askpass=1
    askpass_blocks=$((askpass_blocks + 1))
    continue
  fi
  if [[ "$in_askpass" -eq 1 && "$line" == "ASKPASS_SCRIPT" ]]; then
    in_askpass=0
    continue
  fi

  # Token-bearing auth headers in curl argv are visible to process listings.
  if [[ "$line" =~ curl[[:space:]].*Authorization: ]]; then
    printf 'INSTALL_SECRET_ARGV marker=curl_authorization_header line=%d\n' "$line_no" >&2
    fail=1
  fi

  # Do not embed token variables in clone/API URLs or query strings.
  if [[ "$line" =~ https?://.*\$\{?[A-Za-z0-9_]*${secret_var_re} ]]; then
    printf 'INSTALL_SECRET_ARGV marker=secret_variable_in_url line=%d\n' "$line_no" >&2
    fail=1
  fi

  # Do not write obvious local env snapshots during clone bootstrap.
  if [[ "$line" =~ (cat|tee)[[:space:]]+.*\>[[:space:]]*/tmp/.*\.env ]]; then
    printf 'INSTALL_SECRET_ARTIFACT marker=tmp_env_write line=%d\n' "$line_no" >&2
    fail=1
  fi

  # Directly echoing/printfing secrets is normally unsafe. The one allowed case
  # is the generated GIT_ASKPASS helper, which is chmod 700, removed by trap,
  # and feeds git without placing the token in URLs/remotes.
  if [[ "$in_askpass" -eq 0 && "$line" =~ (^|[[:space:]])(echo|printf)[[:space:]].*\$\{?[A-Za-z0-9_]*${secret_var_re} ]]; then
    printf 'INSTALL_SECRET_OUTPUT marker=shell_secret_emit line=%d\n' "$line_no" >&2
    fail=1
  fi
done < "$INSTALL_SH"

if [[ "$in_askpass" -ne 0 ]]; then
  printf 'Install secret-handling guard failed: unterminated ASKPASS_SCRIPT block\n' >&2
  fail=1
fi

if [[ "$askpass_blocks" -gt 1 ]]; then
  printf 'Install secret-handling guard failed: expected at most one ASKPASS block, found %d\n' "$askpass_blocks" >&2
  fail=1
fi

if ! grep -Fq "umask 077 && cat > /opt/cto/.env && chmod 0600 /opt/cto/.env" "$INSTALL_SH"; then
  printf 'INSTALL_SECRET_ARTIFACT marker=missing_restrictive_remote_env_write\n' >&2
  fail=1
fi

if ! grep -Fq 'GIT_ASKPASS="$ASKPASS" GIT_TERMINAL_PROMPT=0 git clone "$REPO_URL"' "$INSTALL_SH"; then
  printf 'INSTALL_SECRET_ARGV marker=missing_git_askpass_clone\n' >&2
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  printf 'Install secret-handling guard failed. Values were not printed.\n' >&2
  exit 1
fi

printf 'Install secret-handling guard passed: checked scripts/install.sh metadata only.\n'
