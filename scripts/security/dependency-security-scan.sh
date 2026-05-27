#!/usr/bin/env bash
# Non-mutating dependency/security scan for CTO subprojects.
# - Runs npm audit against every committed package-lock project.
# - Reports the installed OpenClaw version vs npm latest without upgrading in place.
# - Fails only when an audit has high/critical vulnerabilities or a project scan errors.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT}/.cache/dependency-security-scan}"
AUDIT_LEVEL="${AUDIT_LEVEL:-high}"
mkdir -p "${OUTPUT_DIR}"

find_package_projects() {
  find "${ROOT}" \
    -path "${ROOT}/.git" -prune -o \
    -path "${ROOT}/node_modules" -prune -o \
    -path "*/node_modules" -prune -o \
    -name package-lock.json -print \
    | sed 's#/package-lock.json$##' \
    | sort
}

current_openclaw_version() {
  if command -v openclaw >/dev/null 2>&1; then
    openclaw --version 2>/dev/null | awk '{print $2}' | head -1
  fi
}

latest_openclaw_version() {
  npm view openclaw version 2>/dev/null || true
}

projects_json="[]"
failures=0
for project in $(find_package_projects); do
  rel="${project#${ROOT}/}"
  safe_name="$(printf '%s' "${rel}" | tr '/ ' '__')"
  out="${OUTPUT_DIR}/${safe_name}-npm-audit.json"
  status="pass"
  exit_code=0
  (cd "${project}" && npm audit --package-lock-only --audit-level="${AUDIT_LEVEL}" --json > "${out}") || exit_code=$?
  if [ "${exit_code}" -ne 0 ]; then
    status="fail"
    failures=$((failures + 1))
  fi
  projects_json=$(PROJECTS_JSON="${projects_json}" PROJECT="${rel}" STATUS="${status}" EXIT_CODE="${exit_code}" OUT="${out}" python3 - <<'PY'
import json, os, pathlib
items=json.loads(os.environ['PROJECTS_JSON'])
out=pathlib.Path(os.environ['OUT'])
try:
    payload=json.loads(out.read_text())
except Exception:
    payload={}
meta=payload.get('metadata', {}).get('vulnerabilities', {})
items.append({
    'project': os.environ['PROJECT'],
    'status': os.environ['STATUS'],
    'exit_code': int(os.environ['EXIT_CODE']),
    'audit_file': str(out),
    'vulnerabilities': {
        'info': int(meta.get('info', 0) or 0),
        'low': int(meta.get('low', 0) or 0),
        'moderate': int(meta.get('moderate', 0) or 0),
        'high': int(meta.get('high', 0) or 0),
        'critical': int(meta.get('critical', 0) or 0),
        'total': int(meta.get('total', 0) or 0),
    },
})
print(json.dumps(items, sort_keys=True))
PY
)
done

current_oc="$(current_openclaw_version || true)"
latest_oc="$(latest_openclaw_version || true)"
summary="${OUTPUT_DIR}/summary.json"
PROJECTS_JSON="${projects_json}" CURRENT_OC="${current_oc}" LATEST_OC="${latest_oc}" AUDIT_LEVEL="${AUDIT_LEVEL}" python3 - <<'PY' > "${summary}"
import json, os
projects=json.loads(os.environ['PROJECTS_JSON'])
current=os.environ.get('CURRENT_OC') or None
latest=os.environ.get('LATEST_OC') or None
print(json.dumps({
    'audit_level': os.environ['AUDIT_LEVEL'],
    'projects': projects,
    'openclaw': {
        'current': current,
        'latest': latest,
        'outdated': bool(current and latest and current != latest),
        'upgrade_policy': 'do not upgrade production in place; use clone-test-replace candidate before promotion',
    },
    'failed_project_count': sum(1 for p in projects if p['status'] != 'pass'),
}, indent=2, sort_keys=True))
PY

cat "${summary}"
if [ "${failures}" -ne 0 ]; then
  echo "FAIL: dependency security scan found ${failures} project(s) with ${AUDIT_LEVEL}+ audit findings or scan errors" >&2
  exit 1
fi

echo "PASS: dependency security scan found no ${AUDIT_LEVEL}+ npm audit findings"
