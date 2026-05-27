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
artifact_stamp="$(date -u +%Y-%m-%dT%H%M%SZ)"
# Keep scheduled pump runs bounded. The pump rehydrates state from durable
# files every tick; reusing one long-lived session eventually causes context
# overflow before useful work can start.
pump_session_id="openclaw-work-pump-$(date -u +%Y%m%dT%H%M)"
artifact_dir="/opt/cto/logs/repairs"
degraded_artifact="${artifact_dir}/openclaw-work-pump-degraded-${artifact_stamp}.md"

prompt="Continuous safe work pump fired at ${now}.

You are OpenClaw, CTO's left hemisphere. Pick exactly one highest-priority safe item and advance it now.

Before choosing, inspect the relevant current state: recent John/PWA chat messages if available, /opt/cto/BACKLOG.md, /opt/cto/HEARTBEAT.md, /opt/cto/wiki/continuous-work-policy.md, /opt/cto/wiki/A2A2H_MAINTENANCE.md, /opt/cto/wiki/A2A2H_LAST_SYNC.md, git status, service health, and recent failed verification/logs.

Before selecting any backlog item, execute the A2A2H per-tick upstream-port check from /opt/cto/wiki/A2A2H_MAINTENANCE.md. If upstream-eligible drift exists, port it, update the tracker, commit/push, and write the tick artifact before doing anything else.

Before picking a new item, scan open and pending backlog items for evidence of completion already on disk. Close anything where the work is observably done.

If /opt/cto/.cache/hermes-work-pump-provider-failure.json shows the Hermes provider circuit is open, do not delegate semantic work to Hermes this tick; record the degraded state if relevant and advance the highest-priority safe OpenClaw-owned item directly.

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
  --session-id "$pump_session_id" \
  --timeout 660 \
  --json \
  --message "$prompt" >"$tmp_output"
rc=$?
set -e

summarize_json() {
  python3 - "$tmp_output" "$degraded_artifact" "$now" "$rc" "$pump_session_id" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
artifact_path = Path(sys.argv[2])
started_at = sys.argv[3]
process_status = sys.argv[4]
session_id = sys.argv[5]
try:
    data = json.loads(path.read_text())
except Exception:
    artifact_path.parent.mkdir(parents=True, exist_ok=True)
    artifact_path.write_text(
        "# OpenClaw work pump degraded output\n\n"
        f"- Timestamp: {started_at}\n"
        f"- Process status: {process_status}\n"
        "- Finding: OpenClaw work pump produced non-JSON output.\n"
        "- Handling: Raw output stayed only in the temporary file and was deleted by the cleanup trap.\n"
        "- Next safe action: inspect OpenClaw Gateway/session health if this repeats.\n",
        encoding="utf-8",
    )
    print(f"openclaw work pump degraded: produced non-JSON output; sanitized artifact written to {artifact_path}")
    sys.exit(1)


def latest_assistant_text_from_session():
    """Fallback for OpenClaw JSON envelopes that omit finalAssistant* fields."""
    state_dir = Path(os.environ.get("OPENCLAW_STATE_DIR", str(Path.home() / ".openclaw")))
    session_path = state_dir / "agents" / "main" / "sessions" / f"{session_id}.jsonl"
    if not session_path.exists():
        return ""
    latest = ""
    try:
        for line in session_path.read_text(encoding="utf-8").splitlines():
            try:
                row = json.loads(line)
            except Exception:
                continue
            message = row.get("message") or {}
            if row.get("type") != "message" or message.get("role") != "assistant":
                continue
            parts = []
            for item in message.get("content") or []:
                if item.get("type") == "text" and item.get("text"):
                    parts.append(item["text"])
            if parts:
                latest = "\n".join(parts).strip()
    except Exception:
        return ""
    return latest

visible = data.get("finalAssistantVisibleText") or data.get("finalAssistantRawText") or latest_assistant_text_from_session()
stop_reason = data.get("stopReason") or data.get("completion", {}).get("stopReason") or "unknown"
if visible:
    # Keep journald concise and avoid persisting raw model/tool envelopes.
    one_line = re.sub(r"\s+", " ", visible).strip()
    if len(one_line) > 500:
        one_line = one_line[:497].rstrip() + "..."
    print(f"openclaw work pump completed (stopReason={stop_reason}): {one_line}")
else:
    err = data.get("error") or data.get("message") or data.get("status") or "no visible final text"
    one_line = re.sub(r"\s+", " ", str(err)).strip()
    if len(one_line) > 500:
        one_line = one_line[:497].rstrip() + "..."
    artifact_path.parent.mkdir(parents=True, exist_ok=True)
    artifact_path.write_text(
        "# OpenClaw work pump degraded output\n\n"
        f"- Timestamp: {started_at}\n"
        f"- Process status: {process_status}\n"
        f"- Stop reason: {stop_reason}\n"
        f"- Sanitized status: {one_line}\n"
        "- Finding: The scheduled work pump returned without visible final text, so journald alone would not prove a durable tick result.\n"
        "- Handling: Raw JSON stayed only in the temporary file and was deleted by the cleanup trap.\n"
        "- Next safe action: if repeated, inspect OpenClaw Gateway/session transport errors and the persistent `openclaw-work-pump` session.\n",
        encoding="utf-8",
    )
    print(f"openclaw work pump degraded (stopReason={stop_reason}): {one_line}; sanitized artifact written to {artifact_path}")
    sys.exit(2)
PY
}

if [[ "$rc" -eq 0 ]]; then
  if summarize_json; then
    exit 0
  fi
  # A JSON response with no visible final assistant text means the scheduled
  # tick did not prove that any work was completed. Preserve the sanitized
  # artifact and mark the unit failed so service health catches the degraded
  # pump instead of treating it as a clean run.
  exit 1
fi

# OpenClaw 2026.5.7 can return a non-zero process status after producing a
# complete JSON response with a normal stop reason. Treat that shape as a
# successful pump tick so systemd does not mark completed work as failed.
if python3 - "$tmp_output" "$pump_session_id" <<'PY'
import json
import os
import sys
from pathlib import Path

path = Path(sys.argv[1])
session_id = sys.argv[2]
try:
    data = json.loads(path.read_text())
except Exception:
    sys.exit(1)

visible = data.get("finalAssistantVisibleText") or data.get("finalAssistantRawText")
if not visible:
    state_dir = Path(os.environ.get("OPENCLAW_STATE_DIR", str(Path.home() / ".openclaw")))
    session_path = state_dir / "agents" / "main" / "sessions" / f"{session_id}.jsonl"
    if session_path.exists():
        try:
            for line in session_path.read_text(encoding="utf-8").splitlines():
                row = json.loads(line)
                message = row.get("message") or {}
                if row.get("type") == "message" and message.get("role") == "assistant":
                    if any(item.get("type") == "text" and item.get("text") for item in message.get("content") or []):
                        visible = True
        except Exception:
            visible = False
if visible:
    sys.exit(0)
sys.exit(1)
PY
then
  summarize_json || true
  echo "openclaw work pump returned status $rc after a complete stop response; treating tick as successful"
  exit 0
fi

summarize_json || true
exit "$rc"
