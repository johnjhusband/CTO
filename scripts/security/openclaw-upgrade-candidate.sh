#!/usr/bin/env bash
# Validate the latest OpenClaw npm package in an isolated npm exec sandbox.
# This does NOT upgrade production OpenClaw, restart services, or mutate global npm state.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT}/.cache/openclaw-upgrade-candidate}"
PACKAGE="${OPENCLAW_NPM_PACKAGE:-openclaw}"
REQUESTED_VERSION="${OPENCLAW_TARGET_VERSION:-latest}"
mkdir -p "${OUTPUT_DIR}"

current_openclaw_version() {
  if command -v openclaw >/dev/null 2>&1; then
    openclaw --version 2>/dev/null | awk '{print $2}' | head -1
  fi
}

resolve_target_version() {
  if [ "${REQUESTED_VERSION}" = "latest" ]; then
    npm view "${PACKAGE}" version 2>/dev/null
  else
    printf '%s\n' "${REQUESTED_VERSION}"
  fi
}

current="$(current_openclaw_version || true)"
target="$(resolve_target_version)"
if [ -z "${target}" ]; then
  echo "FAIL: could not resolve ${PACKAGE}@${REQUESTED_VERSION}" >&2
  exit 1
fi

safe_target="$(printf '%s' "${target}" | tr -c 'A-Za-z0-9._-' '_')"
run_dir="${OUTPUT_DIR}/${PACKAGE}-${safe_target}"
rm -rf "${run_dir}"
mkdir -p "${run_dir}"

version_out="${run_dir}/openclaw-version.txt"
help_out="${run_dir}/openclaw-help.txt"
summary="${run_dir}/summary.json"

# npm exec installs to npm's temporary cache/prefix, with lifecycle scripts disabled.
# Keep cache local to the repo .cache so no global npm or production OpenClaw state changes.
NPM_CONFIG_CACHE="${run_dir}/npm-cache" \
npm_config_ignore_scripts=true \
npm exec --yes --package "${PACKAGE}@${target}" -- openclaw --version > "${version_out}"

NPM_CONFIG_CACHE="${run_dir}/npm-cache" \
npm_config_ignore_scripts=true \
npm exec --yes --package "${PACKAGE}@${target}" -- openclaw help > "${help_out}"

if ! grep -q "${target}" "${version_out}"; then
  echo "FAIL: candidate version output did not contain target ${target}" >&2
  cat "${version_out}" >&2
  exit 1
fi

CURRENT="${current}" TARGET="${target}" VERSION_OUT="${version_out}" HELP_OUT="${help_out}" python3 - <<'PY' > "${summary}"
import json, os, pathlib
version_text = pathlib.Path(os.environ['VERSION_OUT']).read_text().strip()
help_text = pathlib.Path(os.environ['HELP_OUT']).read_text(errors='replace')
print(json.dumps({
    'package': 'openclaw',
    'current_version': os.environ.get('CURRENT') or None,
    'target_version': os.environ['TARGET'],
    'candidate_version_output': version_text,
    'help_smoke_passed': bool(help_text.strip()),
    'production_mutation': False,
    'global_npm_mutation': False,
    'lifecycle_scripts_disabled': True,
    'upgrade_policy': 'validate latest package in isolated candidate; production upgrade still requires clone-test-replace promotion',
}, indent=2, sort_keys=True))
PY

cat "${summary}"
echo "PASS: isolated OpenClaw candidate ${target} smoke test passed"
