#!/usr/bin/env bash
# Compatibility wrapper for the recurring dependency security gate.
set -euo pipefail
ROOT="${1:-/opt/cto}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT}/.cache/dependency-security-scan}" "${ROOT}/scripts/security/dependency-security-scan.sh"
