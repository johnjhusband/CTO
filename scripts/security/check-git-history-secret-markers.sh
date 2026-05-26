#!/usr/bin/env bash
# Report secret markers present anywhere in git history without printing values.
# This is a non-destructive evidence gate for BACKLOG-005/BACKLOG-006; it does
# not rewrite history or rotate credentials.
set -euo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

# marker name -> extended regex. Keep patterns focused on high-signal secrets.
declare -a checks=(
  'private_key_block|-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'github_token|gh[pousr]_[0-9A-Za-z_]{20,}'
  'openai_key|sk-[A-Za-z0-9_-]{20,}'
  'aws_access_key|AKIA[0-9A-Z]{16}'
  'slack_token|xox[baprs]-[0-9A-Za-z-]+'
  'vapid_private_key_env|\bVAPID_PRIVATE_KEY\s*=\s*['"'"'"]?[A-Za-z0-9_-]{32,}'
  'pwa_auth_token_env|\bPWA_AUTH_TOKEN\s*=\s*['"'"'"]?[^[:space:]'"'"'";]{16,}'
  'hermes_api_key_env|\b(HERMES_API_SERVER_KEY|API_SERVER_KEY|HERMES_A2A_TOKEN)\s*=\s*['"'"'"]?[^[:space:]'"'"'";]{16,}'
  'provider_api_key_env|\b(OPENAI_API_KEY|OPENROUTER_API_KEY|BRAVE_API_KEY|HETZNER_API_TOKEN)\s*=\s*['"'"'"]?[^[:space:]'"'"'";]{16,}'
  'smtp_password_env|\b(SMTP_PASSWORD|CTO_EMAIL_SMTP_PASSWORD)\s*=\s*['"'"'"]?[^[:space:]'"'"'";]{12,}'
)

hit_count=0
rev_count=0

is_placeholder_match() {
  local marker="$1"
  local line="$2"

  # Shell/template references such as KEY=${KEY}, KEY="$KEY", or
  # Environment=API_SERVER_KEY=${HERMES_API_SERVER_KEY} are not leaked values.
  # They are common in installer scripts and should not mask real literal
  # values elsewhere in history.
  case "$marker" in
    *_env)
      if [[ "$line" =~ =[[:space:]]*[\"\']?\$\{?[A-Za-z_][A-Za-z0-9_]*\}? ]]; then
        return 0
      fi
      ;;
  esac

  return 1
}

while IFS= read -r rev; do
  rev_count=$((rev_count + 1))
  short="${rev:0:12}"
  for check in "${checks[@]}"; do
    name="${check%%|*}"
    regex="${check#*|}"
    # Use -n so we can suppress template-only matches without printing values.
    # Output below remains path + marker only; matching line content is kept in
    # process memory and never emitted.
    while IFS= read -r match; do
      [[ -n "$match" ]] || continue
      rest="${match#*:}"
      path="${rest%%:*}"
      content="${rest#*:}"
      content="${content#*:}"
      case "$path" in
        tests/test_redact_operational_secrets.py|scripts/security/check-secret-artifacts.sh|scripts/security/check-git-history-secret-markers.sh)
          # Synthetic fixtures and scanner regex definitions deliberately contain
          # marker strings but no secret values.
          continue
          ;;
      esac
      if is_placeholder_match "$name" "$content"; then
        continue
      fi
      printf 'HISTORY_SECRET_MARKER rev=%s marker=%s path=%s\n' "$short" "$name" "$path"
      hit_count=$((hit_count + 1))
    done < <(git grep -I -E -n -e "$regex" "$rev" -- . 2>/dev/null || true)
  done
done < <(git rev-list --all)

if [[ "$hit_count" -gt 0 ]]; then
  printf 'Git history secret marker scan found %d marker(s) across %d revision(s). Values were not printed.\n' "$hit_count" "$rev_count" >&2
  exit 1
fi

printf 'Git history secret marker scan passed: scanned %d revision(s); no markers found.\n' "$rev_count"
