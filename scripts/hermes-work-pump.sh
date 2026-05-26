#!/usr/bin/env bash
# Wake Hermes periodically and ask it to perform one safe unit of continuous work.
# No secrets are printed. A2A sidecar logs request/response into the PWA audit layer.
set -euo pipefail

ENV_FILE="/opt/cto/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${HERMES_A2A_TOKEN:?HERMES_A2A_TOKEN is required}"

python3 - <<'PY'
import json, os, time, urllib.request, urllib.error

token = os.environ['HERMES_A2A_TOKEN']
now = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())


def build_payload(attempt: int) -> dict:
    suffix = int(time.time())
    task_id = f"hermes-work-pump-{suffix}" if attempt == 1 else f"hermes-work-pump-{suffix}-retry{attempt}"
    return {
        "task_id": task_id,
        "sender": "openclaw-work-pump",
        "capability": "Continuous safe work pump. Inspect recent John messages in PWA chat, /opt/cto/BACKLOG.md, /opt/cto/HEARTBEAT.md, git status, service health, and recent failed verification. Before picking a new item, scan open and pending backlog items for evidence of completion already on disk; close anything observably done, or report closure evidence to OpenClaw if strategy authority is needed. Pick exactly one highest-priority safe item and advance it.",
        "inputs": {
            "timestamp_utc": now,
            "policy_path": "/opt/cto/wiki/continuous-work-policy.md",
            "priority_order": [
                "P0 security/access-control",
                "broken communication/reporting or human-interface delivery",
                "hemisphere health/A2A reliability/repair",
                "clone-test validation and installer repeatability",
                "uncommitted or unpushed artifacts/documentation reconciliation",
                "scheduled heartbeat/research work"
            ],
            "stop_conditions": [
                "spend money without prior approval",
                "destroy data or infrastructure without authorization",
                "create external risk",
                "require a non-retrievable decision from John",
                "override OpenClaw strategy or routing authority"
            ]
        },
        "success_criteria": "Produce one durable artifact, verification result, repair, commit, or explicit blocked note. Do not store secrets, raw tool traces, or transient noise in shared memory. Return concise structured findings for OpenClaw."
    }


def post(payload: dict) -> str:
    req = urllib.request.Request(
        'http://127.0.0.1:8643/a2a/',
        data=json.dumps(payload).encode('utf-8'),
        method='POST',
        headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {token}'},
    )
    with urllib.request.urlopen(req, timeout=660) as resp:
        return resp.read().decode('utf-8', 'replace')


def is_transient_agent_incomplete(status: int, text: str) -> bool:
    if status != 502:
        return False
    return "agent_incomplete" in text or "'NoneType' object is not iterable" in text


def write_blocked_note(error_text: str) -> str:
    """Record a durable, sanitized blocked note for strategy follow-up."""
    log_dir = "/opt/cto/logs/repairs"
    os.makedirs(log_dir, exist_ok=True)
    stamp = time.strftime('%Y-%m-%dT%H%M%SZ', time.gmtime())
    path = os.path.join(log_dir, f"hermes-work-pump-agent-incomplete-{stamp}.md")
    with open(path, 'w', encoding='utf-8') as f:
        f.write("# Hermes work pump blocked: agent_incomplete\n\n")
        f.write(f"- Timestamp: {now}\n")
        f.write("- Selected item: hemisphere health / Hermes continuous work pump reliability\n")
        f.write("- Status: blocked_degraded\n")
        f.write("- Evidence: Hermes A2A sidecar returned HTTP 502 with `agent_incomplete` / provider-side `NoneType` error after a fresh task-scoped retry.\n")
        f.write("- Action taken: recorded this explicit blocked note and allowed the systemd pump unit to complete cleanly; OpenClaw remains responsible for follow-up repair.\n")
        f.write("- Secret handling: no request headers, bearer tokens, environment values, or raw tool traces recorded.\n")
        f.write("\n## Sanitized error preview\n\n")
        f.write(error_text[:800].replace(os.environ.get('HERMES_A2A_TOKEN', ''), '[REDACTED]'))
        f.write("\n")
    return path


last_error = ""
for attempt in (1, 2):
    try:
        body = post(build_payload(attempt))
        if attempt > 1:
            print(f"Hermes work pump retry {attempt} succeeded after transient agent_incomplete")
        print(body[:2000])
        raise SystemExit(0)
    except urllib.error.HTTPError as e:
        text = e.read().decode('utf-8', 'replace')[:1000]
        last_error = f"HTTP {e.code}: {text}"
        if attempt == 1 and is_transient_agent_incomplete(e.code, text):
            print("Hermes work pump got transient agent_incomplete from Hermes; retrying once with a fresh task-scoped session")
            time.sleep(5)
            continue
        if is_transient_agent_incomplete(e.code, text):
            artifact = write_blocked_note(last_error)
            print(json.dumps({"status": "blocked_degraded", "artifact": artifact}))
            raise SystemExit(0)
        print(last_error)
        raise SystemExit(1)
    except Exception as e:
        last_error = f"work pump failed: {e!r}"
        print(last_error)
        raise SystemExit(1)

print(last_error or "work pump failed")
raise SystemExit(1)
PY
