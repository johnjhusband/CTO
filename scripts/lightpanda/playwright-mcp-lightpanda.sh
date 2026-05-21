#!/usr/bin/env bash
# Wrapper that launches @playwright/mcp pointed at Lightpanda's CDP endpoint
# instead of letting Playwright spawn its own Chromium.
#
# Lifecycle: starts `lightpanda serve` in the background if nothing is already
# listening on port 9222, then execs the Playwright MCP. When the MCP exits,
# Lightpanda is killed.
#
# Register with Claude Code:
#   claude mcp add playwright /home/john/repos/CTO/scripts/lightpanda/playwright-mcp-lightpanda.sh

set -eu

LP_HOST="${LP_HOST:-127.0.0.1}"
LP_PORT="${LP_PORT:-9222}"
LOG_FILE="${LOG_FILE:-/tmp/lightpanda-mcp.log}"

# If nothing is listening on the port, start Lightpanda
if ! ss -tln 2>/dev/null | grep -q "${LP_HOST}:${LP_PORT}"; then
  if ! command -v lightpanda >/dev/null 2>&1; then
    echo "lightpanda not on PATH — install it first" >&2
    exit 1
  fi
  lightpanda serve --host "$LP_HOST" --port "$LP_PORT" > "$LOG_FILE" 2>&1 &
  LP_PID=$!
  trap 'kill $LP_PID 2>/dev/null || true' EXIT
  # Wait up to 5s for the port to be ready
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if ss -tln 2>/dev/null | grep -q "${LP_HOST}:${LP_PORT}"; then
      break
    fi
    sleep 0.5
  done
  if ! ss -tln 2>/dev/null | grep -q "${LP_HOST}:${LP_PORT}"; then
    echo "lightpanda failed to bind ${LP_HOST}:${LP_PORT} — see ${LOG_FILE}" >&2
    exit 1
  fi
fi

# Hand off to Playwright MCP pointed at Lightpanda's CDP
exec npx -y @playwright/mcp@latest --cdp-endpoint "ws://${LP_HOST}:${LP_PORT}" "$@"
