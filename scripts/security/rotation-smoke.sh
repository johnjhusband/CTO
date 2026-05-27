#!/usr/bin/env bash
# Non-destructive BACKLOG-006 post/pre-rotation smoke checks.
# Verifies local service health and env-file hygiene without printing secret values.
set -euo pipefail

ROOT="${ROOT:-/opt/cto}"
ENV_FILE="${ENV_FILE:-$ROOT/.env}"

required_services=(
  openclaw-gateway.service
  hermes-gateway.service
  cto-hermes-a2a-sidecar.service
  cto-pwa-backend.service
  cto-a2a-registry.service
)

health_urls=(
  "openclaw-gateway http://127.0.0.1:18789/health"
  "hermes-gateway http://127.0.0.1:8642/health"
  "hermes-a2a-sidecar http://127.0.0.1:8643/health"
  "pwa-backend http://127.0.0.1:8088/api/health"
)

echo "Credential rotation smoke check (no secret values printed)"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "missing env file: $ENV_FILE" >&2
  exit 2
fi

mode="$(stat -c '%a' "$ENV_FILE")"
owner="$(stat -c '%U:%G' "$ENV_FILE")"
echo "env_file=$ENV_FILE owner=$owner mode=$mode"
if [[ "$mode" != "600" ]]; then
  echo "env_file_mode_not_600"
  exit 1
fi

echo
echo "Dependent user services:"
service_fail=0
for svc in "${required_services[@]}"; do
  state="$(systemctl --user is-active "$svc" 2>/dev/null || true)"
  echo "- $svc: ${state:-unknown}"
  if [[ "$state" != "active" ]]; then
    service_fail=1
  fi
done

echo
echo "Local health endpoints:"
health_fail=0
for entry in "${health_urls[@]}"; do
  name="${entry%% *}"
  url="${entry#* }"
  if body="$(curl -fsS --max-time 5 "$url" 2>/dev/null)"; then
    # Only report coarse result and byte count; never echo bodies in case a future endpoint changes.
    bytes="$(printf '%s' "$body" | wc -c | tr -d ' ')"
    echo "- $name: ok (${bytes} bytes)"
  else
    echo "- $name: failed"
    health_fail=1
  fi
done

echo
if (( service_fail || health_fail )); then
  echo "Smoke result: failed"
  exit 1
fi

echo "Smoke result: local_services_healthy"
