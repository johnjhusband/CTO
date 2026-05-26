#!/usr/bin/env bash
# Wake OpenClaw periodically and ask it to perform one safe unit of continuous work.
# No secrets are printed. Output goes to journald; OpenClaw should create durable artifacts or visible notes.
set -euo pipefail

LOCK_FILE="/tmp/cto-openclaw-work-pump.lock"
ENV_FILE="/opt/cto/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "openclaw work pump already running; skipping"
  exit 0
fi

now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

prompt="Continuous safe work pump fired at ${now}.

You are OpenClaw, CTO's left hemisphere. Pick exactly one highest-priority safe item and advance it now.

Before choosing, inspect the relevant current state: recent John/PWA chat messages if available, /opt/cto/BACKLOG.md, /opt/cto/HEARTBEAT.md, /opt/cto/wiki/continuous-work-policy.md, git status, service health, and recent failed verification/logs.

Before picking a new item, scan open and pending backlog items for evidence of completion already on disk. Close anything where the work is observably done.

Default priority order:
1. P0 security/access-control.
2. Broken communication/reporting or human-interface delivery.
3. Hemisphere health, A2A delegation reliability, and repair.
4. Clone-test validation and installer repeatability.
5. Uncommitted or unpushed artifacts/documentation reconciliation.
6. Scheduled heartbeat/research work.

Stop conditions: do not spend money, destroy data/infrastructure without authorization, create external risk, require a non-retrievable decision from John, or bypass the two-hemisphere strategy. If the top item is blocked, write a concise blocked note and continue with the next safe item.

Success criteria: produce one durable artifact, verification result, repair, commit, delegated Hermes task, or explicit blocked note. Do not store secrets, raw tool traces, chain-of-thought, or transient noise in shared memory. Keep any John-facing text concise and conversational."

tmp_output="$(mktemp /tmp/cto-openclaw-work-pump.XXXXXX.json)"
cleanup() {
  rm -f "$tmp_output"
}
trap cleanup EXIT

set +e
openclaw agent \
  --local \
  --agent main \
  --model openai-codex/gpt-5.5 \
  --session-id openclaw-work-pump \
  --timeout 660 \
  --json \
  --message "$prompt" | tee "$tmp_output"
rc=${PIPESTATUS[0]}
set -e

if [[ "$rc" -eq 0 ]]; then
  exit 0
fi

# OpenClaw 2026.5.7 can return a non-zero process status after producing a
# complete JSON response with a normal stop reason. Treat that shape as a
# successful pump tick so systemd does not mark completed work as failed.
if python3 - "$tmp_output" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text())
except Exception:
    sys.exit(1)

visible = data.get("finalAssistantVisibleText") or data.get("finalAssistantRawText")
stop_reason = data.get("stopReason") or data.get("completion", {}).get("stopReason")
if visible and stop_reason == "stop":
    sys.exit(0)
sys.exit(1)
PY
then
  echo "openclaw work pump returned status $rc after a complete stop response; treating tick as successful"
  exit 0
fi

exit "$rc"
