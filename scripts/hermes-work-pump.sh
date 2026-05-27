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
import json, os, subprocess, time, urllib.request, urllib.error

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


def sidecar_health(timeout: int = 5) -> bool:
    try:
        with urllib.request.urlopen('http://127.0.0.1:8643/health', timeout=timeout) as resp:
            return resp.status == 200
    except Exception:
        return False


def recover_hermes_runtime() -> tuple[bool, str]:
    """Restart existing Hermes services, with cooldown, after repeated agent_incomplete.

    This is intentionally narrow: it does not touch credentials, data, cloud resources,
    or create a new scheduler. A cooldown prevents provider-side failures from causing
    repeated service restarts every work-pump tick when restart is not changing outcome.
    """
    if os.environ.get('HERMES_WORK_PUMP_RECOVERY_RESTART', '1') == '0':
        return False, 'recovery restart disabled by HERMES_WORK_PUMP_RECOVERY_RESTART=0'
    cooldown_seconds = int(os.environ.get('HERMES_WORK_PUMP_RECOVERY_COOLDOWN_SECONDS', '3600'))
    state_dir = '/opt/cto/.cache'
    state_path = os.path.join(state_dir, 'hermes-work-pump-recovery-restart.ts')
    try:
        with open(state_path, 'r', encoding='utf-8') as f:
            last_restart = float(f.read().strip() or '0')
    except FileNotFoundError:
        last_restart = 0.0
    except Exception:
        last_restart = 0.0
    now_epoch = time.time()
    if cooldown_seconds > 0 and last_restart and now_epoch - last_restart < cooldown_seconds:
        remaining = int(cooldown_seconds - (now_epoch - last_restart))
        return False, f'recovery restart skipped; cooldown active for another {remaining}s'
    cmd = [
        'systemctl', '--user', 'restart',
        'hermes-gateway.service',
        'cto-hermes-a2a-sidecar.service',
    ]
    try:
        completed = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=90)
    except Exception as e:
        return False, f'restart command failed: {type(e).__name__}'
    if completed.returncode != 0:
        return False, f'restart command exited {completed.returncode}'
    try:
        os.makedirs(state_dir, exist_ok=True)
        with open(state_path, 'w', encoding='utf-8') as f:
            f.write(str(now_epoch))
    except Exception:
        pass
    for _ in range(30):
        if sidecar_health(timeout=2):
            return True, 'restarted hermes-gateway and cto-hermes-a2a-sidecar; sidecar health is ok'
        time.sleep(1)
    return False, 'services restarted but sidecar health did not recover within 30s'


def is_transient_agent_incomplete(status: int, text: str) -> bool:
    if status != 502:
        return False
    return "agent_incomplete" in text or "'NoneType' object is not iterable" in text


def write_blocked_note(error_text: str, recovery_note: str = '') -> str:
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
        f.write("- Action taken: retried with a fresh task-scoped session; after repeat failure, attempted the configured existing-service recovery restart once unless cooldown was active, then recorded this explicit blocked note and allowed the systemd pump unit to complete cleanly.\n")
        if recovery_note:
            f.write(f"- Recovery attempt: {recovery_note}\n")
        f.write("- Secret handling: no request headers, bearer tokens, environment values, or raw tool traces recorded.\n")
        f.write("\n## Sanitized error preview\n\n")
        f.write(error_text[:800].replace(os.environ.get('HERMES_A2A_TOKEN', ''), '[REDACTED]'))
        f.write("\n")
    return path


last_error = ""
recovery_attempted = False
recovery_note = ""
for attempt in (1, 2, 3):
    try:
        body = post(build_payload(attempt))
        if attempt > 1:
            print(f"Hermes work pump retry {attempt} succeeded after transient agent_incomplete")
        print(body[:2000])
        raise SystemExit(0)
    except urllib.error.HTTPError as e:
        text = e.read().decode('utf-8', 'replace')[:1000]
        last_error = f"HTTP {e.code}: {text}"
        if is_transient_agent_incomplete(e.code, text):
            if attempt == 1:
                print("Hermes work pump got transient agent_incomplete from Hermes; retrying once with a fresh task-scoped session")
                time.sleep(5)
                continue
            if attempt == 2 and not recovery_attempted:
                print("Hermes work pump got repeat agent_incomplete; restarting existing Hermes user services once before final retry")
                recovery_attempted = True
                ok, recovery_note = recover_hermes_runtime()
                if ok:
                    time.sleep(5)
                    continue
                artifact = write_blocked_note(last_error, recovery_note)
                print(json.dumps({"status": "blocked_degraded", "artifact": artifact, "recovery": recovery_note}))
                raise SystemExit(0)
            artifact = write_blocked_note(last_error, recovery_note)
            print(json.dumps({"status": "blocked_degraded", "artifact": artifact, "recovery": recovery_note}))
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
