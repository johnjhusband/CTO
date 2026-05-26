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
payload = {
    "task_id": f"hermes-work-pump-{int(time.time())}",
    "sender": "openclaw-work-pump",
    "capability": "Continuous safe work pump. Inspect recent John messages in PWA chat, /opt/cto/BACKLOG.md, /opt/cto/HEARTBEAT.md, git status, service health, and recent failed verification. Pick exactly one highest-priority safe item and advance it.",
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
req = urllib.request.Request(
    'http://127.0.0.1:8643/a2a/',
    data=json.dumps(payload).encode('utf-8'),
    method='POST',
    headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {token}'},
)
try:
    with urllib.request.urlopen(req, timeout=660) as resp:
        body = resp.read().decode('utf-8', 'replace')
        print(body[:2000])
except urllib.error.HTTPError as e:
    print(f"HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:1000]}")
    raise SystemExit(1)
except Exception as e:
    print(f"work pump failed: {e!r}")
    raise SystemExit(1)
PY
