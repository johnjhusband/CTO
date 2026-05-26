#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-/opt/cto}"
projects=(
  "lib/a2a-secure"
  "plugins/openclaw-secure-a2a"
  "scripts/namecheap-playwright"
  "ui/cto-chat"
)

for project in "${projects[@]}"; do
  echo "== npm audit: ${project} =="
  (cd "${ROOT}/${project}" && npm audit --omit=dev --audit-level=moderate)
done

installed_openclaw="$(openclaw --version | awk '{print $2}')"
latest_openclaw="$(npm view openclaw version)"
echo "== openclaw version =="
echo "installed=${installed_openclaw} latest=${latest_openclaw}"

if [[ "${installed_openclaw}" != "${latest_openclaw}" ]]; then
  echo "OpenClaw update available: ${installed_openclaw} -> ${latest_openclaw}" >&2
  exit 2
fi
