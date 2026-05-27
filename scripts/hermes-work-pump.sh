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

export HERMES_WORK_PUMP_START_EPOCH="$(date -u +%s)"
/opt/cto/scripts/pwa-chat-first-gate.sh

python3 - <<'PY'
import glob, json, os, subprocess, time, urllib.request, urllib.error

token = os.environ['HERMES_A2A_TOKEN']
now = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
STATE_DIR = '/opt/cto/.cache'
PROVIDER_FAILURE_STATE = os.path.join(STATE_DIR, 'hermes-work-pump-provider-failure.json')
START_EPOCH = os.environ.get('HERMES_WORK_PUMP_START_EPOCH', str(int(time.time())))


def run_frontend_touch_gate_if_needed() -> None:
    frontend_paths = [
        'services/pwa/frontend/index.html',
        'services/pwa/frontend/app.js',
        'services/pwa/frontend/style.css',
        'services/pwa/frontend/service-worker.js',
    ]
    cmd = ['git', '-C', '/opt/cto', 'log', f'--since=@{START_EPOCH}', '--name-only', '--format=', '--', *frontend_paths]
    completed = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, timeout=30)
    touched = sorted({line.strip() for line in completed.stdout.splitlines() if line.strip()})
    if not touched:
        return
    token_value = os.environ.get('PWA_AUTH_TOKEN', '')
    if not token_value:
        raise SystemExit('PWA frontend gate failed: PWA_AUTH_TOKEN is not set while frontend commits landed in this Hermes tick')
    pytest_bin = '/home/cto/.local/bin/pytest'
    if not os.path.exists(pytest_bin):
        raise SystemExit(f'PWA frontend gate failed: {pytest_bin} is missing')
    env = os.environ.copy()
    env['PWA_BASE_URL'] = env.get('PWA_BASE_URL') or 'https://cto.husband.llc'
    env['PWA_AUTH_TOKEN'] = token_value
    result = subprocess.run(
        [pytest_bin, 'tests/test_pwa_chat_first_layout.py', '-v'],
        cwd='/opt/cto', env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, timeout=120,
    )
    print(result.stdout[:4000])
    if result.returncode != 0 or 'skipped' in result.stdout.lower():
        raise SystemExit(f'PWA frontend gate failed or skipped after frontend touch: {", ".join(touched)}')


def _load_provider_failure_state() -> dict:
    try:
        with open(PROVIDER_FAILURE_STATE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _save_provider_failure_state(state: dict) -> None:
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        tmp = f"{PROVIDER_FAILURE_STATE}.tmp"
        with open(tmp, 'w', encoding='utf-8') as f:
            json.dump(state, f, sort_keys=True)
        os.replace(tmp, PROVIDER_FAILURE_STATE)
    except Exception:
        pass


def clear_provider_failure_state() -> None:
    try:
        os.remove(PROVIDER_FAILURE_STATE)
    except FileNotFoundError:
        pass
    except Exception:
        pass


def record_provider_failure(artifact: str, recovery_note: str) -> dict:
    state = _load_provider_failure_state()
    last_failure_epoch = float(state.get('last_failure_epoch') or 0)
    now_epoch = time.time()
    # Keep the consecutive count only while failures are part of the same outage.
    if last_failure_epoch and now_epoch - last_failure_epoch < 3600:
        count = int(state.get('consecutive_failures') or 0) + 1
    else:
        recent_artifacts = [
            p for p in glob.glob('/opt/cto/logs/repairs/hermes-work-pump-agent-incomplete-*.md')
            if now_epoch - os.path.getmtime(p) < 3600
        ]
        count = max(1, len(recent_artifacts))
    state = {
        'consecutive_failures': count,
        'last_failure_epoch': now_epoch,
        'last_failure_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(now_epoch)),
        'last_artifact': artifact,
        'last_recovery': recovery_note,
        'reason': 'agent_incomplete_provider_NoneType',
    }
    _save_provider_failure_state(state)
    return state


def provider_outage_circuit_breaker() -> tuple[bool, str, dict]:
    """Avoid hammering Hermes/Codex when the same provider-side bug repeats.

    The work pump already performs a fresh-session retry and a bounded service
    restart. When the provider keeps returning the same non-retryable Codex
    `NoneType`/agent_incomplete error, more calls in the next few ticks only
    spam John and consume provider/runtime budget. After three consecutive
    failures within an hour, pause semantic Hermes delegation briefly while
    leaving services/timers up and OpenClaw free to continue safe work.
    """
    state = _load_provider_failure_state()
    count = int(state.get('consecutive_failures') or 0)
    last = float(state.get('last_failure_epoch') or 0)
    base_cooldown = int(os.environ.get('HERMES_WORK_PUMP_PROVIDER_FAILURE_COOLDOWN_SECONDS', '2700'))
    max_cooldown = int(os.environ.get('HERMES_WORK_PUMP_PROVIDER_FAILURE_MAX_COOLDOWN_SECONDS', '21600'))
    if count < 3 or not last or base_cooldown <= 0:
        return False, '', state
    multiplier = 2 ** max(0, count - 3)
    cooldown = min(max_cooldown if max_cooldown > 0 else base_cooldown * multiplier, base_cooldown * multiplier)
    elapsed = time.time() - last
    if elapsed >= cooldown:
        return False, '', state
    remaining = int(cooldown - elapsed)
    return True, f'known provider-side agent_incomplete outage; semantic Hermes delegation paused for another {remaining}s after {count} consecutive failures (adaptive cooldown {cooldown}s)', state


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
            ],
            "pwa_chat_first_gate": {
                "frontend_paths": [
                    "services/pwa/frontend/index.html",
                    "services/pwa/frontend/app.js",
                    "services/pwa/frontend/style.css",
                    "services/pwa/frontend/service-worker.js"
                ],
                "required_command": "PWA_BASE_URL=https://cto.husband.llc PWA_AUTH_TOKEN=<from /opt/cto/.env> /home/cto/.local/bin/pytest tests/test_pwa_chat_first_layout.py",
                "rule": "If a frontend path is touched, the Playwright test must pass after the change. Failure or skip means do not commit. CSS string-search tests do not count for visible UI verification; new visible-shell features must stay within chat-first thresholds."
            }
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


def notify_blocked_note(path: str, recovery_note: str = '') -> None:
    """Best-effort human-visible alert for semantic Hermes work-pump failures.

    The HTTP health endpoint can be green while delegated work is still failing with
    agent_incomplete. Emit a sanitized system_event so the PWA/chat log shows the
    degraded work-pump state instead of hiding it in filesystem artifacts only.
    """
    try:
        import sys
        sys.path.insert(0, '/opt/cto/services')
        from chat.db import append
        event = {
            "event": "hermes_work_pump_blocked",
            "status": "blocked_degraded",
            "reason": "agent_incomplete",
            "artifact": path,
        }
        if recovery_note:
            event["recovery"] = recovery_note
        append(
            sender="system",
            recipient="john",
            kind="system_event",
            correlation="hermes-work-pump",
            content=json.dumps(event),
        )
    except Exception:
        # Failure reporting must never make the scheduled pump fail harder.
        return


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
        f.write("- Human-visible reporting: wrote a sanitized `hermes_work_pump_blocked` system_event to the PWA chat log when possible.\n")
        if recovery_note:
            f.write(f"- Recovery attempt: {recovery_note}\n")
        f.write("- Secret handling: no request headers, bearer tokens, environment values, or raw tool traces recorded.\n")
        f.write("\n## Sanitized error preview\n\n")
        f.write(error_text[:800].replace(os.environ.get('HERMES_A2A_TOKEN', ''), '[REDACTED]'))
        f.write("\n")
    notify_blocked_note(path, recovery_note)
    record_provider_failure(path, recovery_note)
    return path


def write_circuit_open_note(skip_note: str, state: dict) -> str:
    """Record a throttled durable note when the provider circuit is already open.

    The circuit breaker intentionally skips semantic Hermes delegation. Without a
    fresh artifact, a green systemd unit can look like successful work while the
    right hemisphere is still degraded. Throttle artifacts to avoid spam during a
    single outage while preserving visible evidence for the current cooldown.
    """
    now_epoch = time.time()
    last_notice = float(state.get('last_circuit_notice_epoch') or 0)
    existing = str(state.get('last_circuit_artifact') or state.get('last_artifact') or '')
    if existing and last_notice and now_epoch - last_notice < 900:
        return existing

    log_dir = "/opt/cto/logs/repairs"
    os.makedirs(log_dir, exist_ok=True)
    stamp = time.strftime('%Y-%m-%dT%H%M%SZ', time.gmtime(now_epoch))
    path = os.path.join(log_dir, f"hermes-work-pump-circuit-open-{stamp}.md")
    with open(path, 'w', encoding='utf-8') as f:
        f.write("# Hermes work pump circuit open\n\n")
        f.write(f"- Timestamp: {now}\n")
        f.write("- Selected item: hemisphere health / Hermes continuous work pump reliability\n")
        f.write("- Status: blocked_degraded_circuit_open\n")
        f.write("- Evidence: provider failure cache shows repeated `agent_incomplete` / `NoneType` failures, so semantic Hermes delegation was intentionally skipped this tick.\n")
        f.write(f"- Circuit state: {skip_note}\n")
        if state.get('last_artifact'):
            f.write(f"- Previous failure artifact: {state.get('last_artifact')}\n")
        f.write("- Action taken: left services running, avoided another provider call, and preserved this durable degraded-state note for OpenClaw strategy follow-up.\n")
        f.write("- Secret handling: no request headers, bearer tokens, environment values, or raw tool traces recorded.\n")
    state['last_circuit_notice_epoch'] = now_epoch
    state['last_circuit_notice_utc'] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(now_epoch))
    state['last_circuit_artifact'] = path
    _save_provider_failure_state(state)
    notify_blocked_note(path, skip_note)
    return path


skip, skip_note, skip_state = provider_outage_circuit_breaker()
if skip:
    artifact = write_circuit_open_note(skip_note, skip_state)
    print(json.dumps({
        "status": "blocked_degraded_circuit_open",
        "artifact": artifact,
        "recovery": skip_note,
    }))
    raise SystemExit(0)


last_error = ""
recovery_attempted = False
recovery_note = ""
for attempt in (1, 2, 3):
    try:
        body = post(build_payload(attempt))
        clear_provider_failure_state()
        if attempt > 1:
            print(f"Hermes work pump retry {attempt} succeeded after transient agent_incomplete")
        print(body[:2000])
        run_frontend_touch_gate_if_needed()
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
                recovery_attempted = True
                prior_state = _load_provider_failure_state()
                prior_count = int(prior_state.get('consecutive_failures') or 0)
                if prior_count >= 3:
                    recovery_note = (
                        'recovery restart skipped; provider outage circuit was already established '
                        f'with {prior_count} consecutive failures, and previous restarts did not change outcome'
                    )
                    artifact = write_blocked_note(last_error, recovery_note)
                    print(json.dumps({"status": "blocked_degraded", "artifact": artifact, "recovery": recovery_note}))
                    raise SystemExit(0)
                print("Hermes work pump got repeat agent_incomplete; restarting existing Hermes user services once before final retry")
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
