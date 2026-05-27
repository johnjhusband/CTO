#!/usr/bin/env bash
# Enforce the rendered PWA chat-first regression gate whenever frontend shell files are touched.
# Requires PWA_AUTH_TOKEN to be sourced by the caller from /opt/cto/.env. Never prints secrets.
set -euo pipefail

REPO_DIR="${PWA_GATE_REPO_DIR:-/opt/cto}"
PYTEST_BIN="${PWA_GATE_PYTEST_BIN:-/home/cto/.local/bin/pytest}"
TEST_PATH="${PWA_GATE_TEST_PATH:-tests/test_pwa_chat_first_layout.py}"
BASE_URL="${PWA_BASE_URL:-https://cto.husband.llc}"

frontend_status="$(git -C "$REPO_DIR" status --porcelain --untracked-files=all -- \
  services/pwa/frontend/index.html \
  services/pwa/frontend/app.js \
  services/pwa/frontend/style.css \
  services/pwa/frontend/service-worker.js || true)"

if [[ -z "$frontend_status" ]]; then
  exit 0
fi

if [[ -z "${PWA_AUTH_TOKEN:-}" ]]; then
  echo "PWA chat-first gate failed: PWA_AUTH_TOKEN is not set; source /opt/cto/.env before committing frontend shell changes." >&2
  exit 1
fi

if [[ ! -x "$PYTEST_BIN" ]]; then
  echo "PWA chat-first gate failed: pytest not executable at $PYTEST_BIN" >&2
  exit 1
fi

output_file="$(mktemp /tmp/pwa-chat-first-gate.XXXXXX.log)"
cleanup() {
  rm -f "$output_file"
}
trap cleanup EXIT

set +e
(
  cd "$REPO_DIR" && \
  PWA_BASE_URL="$BASE_URL" \
  PWA_AUTH_TOKEN="$PWA_AUTH_TOKEN" \
  "$PYTEST_BIN" "$TEST_PATH" -q
) >"$output_file" 2>&1
rc=$?
set -e

cat "$output_file"

if [[ "$rc" -ne 0 ]]; then
  echo "PWA chat-first gate failed: Playwright regression test exited $rc." >&2
  exit "$rc"
fi

if grep -Eiq '(^|[[:space:]])[0-9]+[[:space:]]+skipped|SKIPPED|no tests ran' "$output_file"; then
  echo "PWA chat-first gate failed: the Playwright regression test skipped; skipped UI gates do not count as tested." >&2
  exit 1
fi

if ! grep -Eiq '(^|[[:space:]])[0-9]+[[:space:]]+passed' "$output_file"; then
  echo "PWA chat-first gate failed: no passing Playwright assertion was detected." >&2
  exit 1
fi

echo "PWA chat-first gate passed for touched frontend shell files."
