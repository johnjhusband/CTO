#!/usr/bin/env bash
# Clone-side OpenClaw upgrade gate.
# Run this on a clone-test-replace candidate after installing/upgrading OpenClaw.
# It is intentionally read-only: no npm installs, service restarts, cloud calls, or secret output.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT}"

SUMMARY="${OPENCLAW_UPGRADE_SUMMARY:-}"
TARGET="${OPENCLAW_TARGET_VERSION:-}"
OUT_DIR="${OPENCLAW_CLONE_GATE_OUT_DIR:-${ROOT}/logs/security}"
mkdir -p "${OUT_DIR}"

usage() {
  cat <<'EOF'
Usage: scripts/security/openclaw-upgrade-clone-gate.sh [--summary PATH] [--target-version VERSION] [--output PATH]

Read-only clone-side gate for OpenClaw upgrade candidates. Expected to run on a clone host,
not as a production upgrade. It fails closed unless the installed OpenClaw version matches the
candidate target and the standard no-spend validation suite passes.
EOF
}

OUTPUT=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --summary)
      SUMMARY="${2:-}"; shift 2 ;;
    --target-version)
      TARGET="${2:-}"; shift 2 ;;
    --output)
      OUTPUT="${2:-}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "FAIL: unknown argument $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "${OUTPUT}" ]; then
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  OUTPUT="${OUT_DIR}/openclaw-upgrade-clone-gate-${stamp}.json"
fi

clone_verify_args=()
if [ -n "${SUMMARY}" ]; then
  clone_verify_args+=(--summary "${SUMMARY}")
fi
if [ -n "${TARGET}" ]; then
  clone_verify_args+=(--target-version "${TARGET}")
fi

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "${tmpdir}"; }
trap cleanup EXIT

clone_json="${tmpdir}/clone-verify.json"
validate_log="${tmpdir}/validate-no-spend.log"
a2a_log="${tmpdir}/a2a2h-drift.log"

status="clone_gate_verified"
failures=()

if ! scripts/security/openclaw-upgrade-clone-verify.py "${clone_verify_args[@]}" > "${clone_json}"; then
  status="blocked"
  failures+=("openclaw clone version/help verification failed")
fi

if ! bash scripts/validate-no-spend.sh > "${validate_log}" 2>&1; then
  status="blocked"
  failures+=("validate-no-spend failed")
fi

last_sync=""
if [ -f wiki/A2A2H_LAST_SYNC.md ]; then
  last_sync="$(grep -E '^\*\*Last synced CTO SHA:\*\* ' wiki/A2A2H_LAST_SYNC.md | awk '{print $5}' | head -1)"
fi
if [ -n "${last_sync}" ]; then
  git log "${last_sync}..HEAD" --oneline -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py > "${a2a_log}"
  if [ -s "${a2a_log}" ]; then
    status="blocked"
    failures+=("A2A2H upstream-eligible CTO drift exists")
  fi
else
  status="blocked"
  failures+=("could not read A2A2H last-sync tracker")
fi

python3 - "$OUTPUT" "$status" "$clone_json" "$validate_log" "$a2a_log" "${failures[@]}" <<'PY'
import json, pathlib, sys
out = pathlib.Path(sys.argv[1])
status = sys.argv[2]
clone_json = pathlib.Path(sys.argv[3])
validate_log = pathlib.Path(sys.argv[4])
a2a_log = pathlib.Path(sys.argv[5])
failures = list(sys.argv[6:])
try:
    clone_payload = json.loads(clone_json.read_text(encoding='utf-8'))
except Exception as exc:
    clone_payload = {'status': 'blocked', 'failures': [f'could not parse clone verifier output: {type(exc).__name__}: {exc}']}
    if 'could not parse clone verifier output' not in failures:
        failures.append('could not parse clone verifier output')
validate_tail = validate_log.read_text(encoding='utf-8', errors='replace').splitlines()[-20:]
a2a_lines = a2a_log.read_text(encoding='utf-8', errors='replace').splitlines()[:20] if a2a_log.exists() else []
payload = {
    'status': status,
    'gate': 'openclaw_upgrade_clone_gate',
    'clone_verify': clone_payload,
    'validate_no_spend_tail': validate_tail,
    'a2a2h_drift_lines': a2a_lines,
    'failures': failures,
    'production_mutated_by_this_check': False,
    'spend_or_infrastructure_change': False,
    'secret_values_printed': False,
    'next_required_step': 'Only promote the clone after this gate reports clone_gate_verified on the clone host; do not upgrade production in place.',
}
out.write_text(json.dumps(payload, indent=2, sort_keys=True) + '\n', encoding='utf-8')
print(json.dumps(payload, indent=2, sort_keys=True))
PY

if [ "${status}" != "clone_gate_verified" ]; then
  echo "FAIL: OpenClaw clone gate blocked; summary: ${OUTPUT}" >&2
  exit 1
fi

echo "PASS: OpenClaw clone gate verified; summary: ${OUTPUT}"
