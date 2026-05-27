#!/usr/bin/env bash
# Non-destructive BACKLOG-006 coordinated credential-rotation readiness gate.
# Checks rotation artifacts, permissions, and service dependencies by name only.
# Never prints secret values and never mutates runtime state.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/security/credential-rotation-plan.sh --check-only

Non-destructively verifies that the coordinated credential-rotation window has
its local safety artifacts in place. Output is metadata/name-only.
USAGE
}

if [[ "${1:-}" != "--check-only" || "${2:-}" != "" ]]; then
  usage >&2
  exit 2
fi

ROOT="${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
ENV_FILE="${ENV_FILE:-$ROOT/.env}"
cd "$ROOT"

required_artifacts=(
  scripts/security/rotation-preflight.sh
  scripts/security/rotation-smoke.sh
  scripts/security/redact-operational-secrets.py
  scripts/security/check-git-history-secret-markers.sh
  scripts/security/run-safe-security-gates.sh
)

required_vars=(
  HETZNER_API_TOKEN
  GITHUB_TOKEN
  HERMES_API_SERVER_KEY
  HERMES_A2A_TOKEN
  OPENAI_API_KEY
  PWA_AUTH_TOKEN
)

restart_order=(
  openclaw-gateway.service
  hermes-gateway.service
  cto-hermes-a2a-sidecar.service
  cto-pwa-backend.service
  cto-a2a-registry.service
)

fail=0

echo "Credential rotation coordinated plan check (metadata only)"
echo "root=$ROOT"

echo
echo "Required local artifacts:"
for rel in "${required_artifacts[@]}"; do
  if [[ -f "$rel" ]]; then
    if [[ -x "$rel" ]]; then
      mode="executable"
    else
      mode="present_not_executable"
    fi
    echo "- $rel: $mode"
  else
    echo "- $rel: MISSING"
    fail=1
  fi
done

echo
echo "Artifact syntax:"
for rel in scripts/security/rotation-preflight.sh scripts/security/rotation-smoke.sh scripts/security/check-git-history-secret-markers.sh scripts/security/run-safe-security-gates.sh; do
  if [[ -f "$rel" ]] && bash -n "$rel"; then
    echo "- $rel: syntax_ok"
  else
    echo "- $rel: syntax_failed"
    fail=1
  fi
done
if [[ -f scripts/security/redact-operational-secrets.py ]] && python3 -m py_compile scripts/security/redact-operational-secrets.py; then
  echo "- scripts/security/redact-operational-secrets.py: syntax_ok"
else
  echo "- scripts/security/redact-operational-secrets.py: syntax_failed"
  fail=1
fi

echo
echo "Secret store hygiene:"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "- env_file: MISSING"
  fail=1
elif [[ ! -r "$ENV_FILE" ]]; then
  echo "- env_file: unreadable"
  fail=1
else
  owner="$(stat -c '%U:%G' "$ENV_FILE")"
  mode="$(stat -c '%a' "$ENV_FILE")"
  echo "- env_file: present owner=$owner mode=$mode"
  if [[ "$mode" != "600" ]]; then
    echo "- env_file_mode: expected_600 actual=$mode"
    fail=1
  fi

  declare -A present=()
  declare -A nonempty=()
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    present["$key"]=1
    normalized="${value%$'\r'}"
    if [[ -n "$normalized" && "$normalized" != '""' && "$normalized" != "''" ]]; then
      nonempty["$key"]=1
    fi
  done < <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$ENV_FILE" || true)

  echo "Required credential names:"
  for key in "${required_vars[@]}"; do
    if [[ -z "${present[$key]:-}" ]]; then
      echo "- $key: MISSING"
      fail=1
    elif [[ -z "${nonempty[$key]:-}" ]]; then
      echo "- $key: EMPTY"
      fail=1
    else
      echo "- $key: present_nonempty"
    fi
  done
fi

echo
echo "Dependent restart/verification order (names only):"
for svc in "${restart_order[@]}"; do
  state="$(systemctl --user is-active "$svc" 2>/dev/null || true)"
  echo "- $svc: ${state:-unknown}"
done

echo
echo "Required operator actions outside this script:"
echo "1. Prepare replacement credential values out of band; do not paste them into chat/logs."
echo "2. Atomically update $ENV_FILE with mode 600 during the approved rotation window."
echo "3. Restart services in the order above and run rotation-smoke plus safe security gates."
echo "4. Revoke superseded external credentials only after local verification succeeds."
echo "5. Decide separately whether to coordinate public git-history rewrite or risk acceptance."

echo
if (( fail )); then
  echo "Plan check result: blocked"
  exit 1
fi

echo "Plan check result: ready_for_coordinated_rotation_window"
