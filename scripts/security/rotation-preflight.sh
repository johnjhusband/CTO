#!/usr/bin/env bash
# Non-destructive BACKLOG-006 credential rotation preflight.
# Prints credential names and service dependencies only; never prints secret values.
set -euo pipefail

ROOT="${ROOT:-/opt/cto}"
ENV_FILE="${ENV_FILE:-$ROOT/.env}"

required_vars=(
  HETZNER_API_TOKEN
  GITHUB_TOKEN
  HERMES_API_SERVER_KEY
  HERMES_A2A_TOKEN
  OPENAI_API_KEY
  PWA_AUTH_TOKEN
)
optional_or_retired_vars=(
  CTO_EMAIL_SMTP_PASSWORD
  GOOGLE_ACCOUNT_PASSWORD_PENDING
  OPENROUTER_API_KEY
)
services=(
  openclaw-gateway.service
  hermes-gateway.service
  cto-hermes-a2a-sidecar.service
  cto-pwa-backend.service
  cto-a2a-registry.service
)

if [[ ! -f "$ENV_FILE" ]]; then
  echo "missing env file: $ENV_FILE" >&2
  exit 2
fi

if [[ ! -r "$ENV_FILE" ]]; then
  echo "env file is not readable by current user: $ENV_FILE" >&2
  exit 2
fi

mode="$(stat -c '%a' "$ENV_FILE")"
owner="$(stat -c '%U:%G' "$ENV_FILE")"
echo "Credential rotation preflight (no secret values printed)"
echo "env_file=$ENV_FILE owner=$owner mode=$mode"
if [[ "$mode" != "600" ]]; then
  echo "WARN env_file_mode_expected_600 actual=$mode"
fi

declare -A present=()
while IFS='=' read -r key _value; do
  [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
  present["$key"]=1
done < <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$ENV_FILE" || true)

missing=0
echo

echo "Required credential names:"
for key in "${required_vars[@]}"; do
  if [[ -n "${present[$key]:-}" ]]; then
    echo "- $key: present"
  else
    echo "- $key: MISSING"
    missing=1
  fi
done

echo

echo "Optional/retired credential names to reconcile during rotation window:"
for key in "${optional_or_retired_vars[@]}"; do
  if [[ -n "${present[$key]:-}" ]]; then
    echo "- $key: present"
  else
    echo "- $key: absent"
  fi
done

echo

echo "Dependent user services:"
for svc in "${services[@]}"; do
  state="$(systemctl --user is-active "$svc" 2>/dev/null || true)"
  echo "- $svc: ${state:-unknown}"
done

echo

echo "Recommended coordinated order (names only):"
echo "1. Prepare replacement values out of band for all present required names."
echo "2. Update $ENV_FILE atomically with mode 600 and no shell history echo."
echo "3. Restart dependent user services in a controlled window."
echo "4. Verify PWA auth, Hermes A2A, OpenClaw gateway, embeddings, GitHub, and Hetzner paths."
echo "5. Revoke superseded provider credentials only after verification."
echo "6. Run scripts/security/run-safe-security-gates.sh and record evidence."

if (( missing )); then
  echo
  echo "Preflight result: blocked_missing_required_names"
  exit 1
fi

echo

echo "Preflight result: ready_for_coordinated_rotation_window"
