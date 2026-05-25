# CTO Install Test Plan — Two-Hemisphere

**L0:** Verification plan for the two-hemisphere install. Three test phases: (1) **Static checks** — installer outputs, file existence, config validity; (2) **Service checks** — daemons running, ports bound, health endpoints; (3) **Functional checks** — the canonical bidirectional delegation prompt that proves both hemispheres talk. Pass/fail criteria explicit for each step. Failures map to specific rollback / next-action.

**L1:** Test plan companion to `install-plan.md` §6.4. Run after install completes. Each test has an expected output; deviation is a fail. No "looks fine" — every check is a grep/curl/exit-code assertion. If a test fails, the entry-point script halts and writes the failure to `/opt/cto/logs/install/install-failed-<timestamp>.log`. Rollback policy at the bottom.

**Last updated:** 2026-05-25
**Verification:** Test definitions cross-referenced against install-plan.md, live systemd units/ports on the CTO VPS, and CTO-DECISION-014/015.


---

## Phase 0 — No-Spend Clone-Readiness Gates (run before any VPS approval)

Run from the repo root:

```bash
scripts/validate-no-spend.sh
```

**What it proves:** local scripts parse, Python service modules compile, PWA routing decisions are deterministic, candidate clone chat isolation blocks production `chat.db`, active install surfaces do not reintroduce `OPENROUTER_API_KEY`, and tracked secret/runtime files are not committed.

**Expected:** `PASS: no-spend validation complete`. Skipped npm builds are acceptable only when `node_modules` is absent; if dependencies are installed, build failures are blocking.

**On fail:** fix the named repo issue before provisioning any paid clone.

### 0.1 Candidate chat isolation

Fresh VPS installs created by `scripts/install.sh` must write these candidate-scoped values into `/opt/cto/.env`:

```bash
CTO_INSTANCE_ID=candidate-<VPS_NAME>
CHAT_DB=/opt/cto/.candidate/<CTO_INSTANCE_ID>/chat.db
OPENCLAW_SESSION_ID=<CTO_INSTANCE_ID>-pwa-john-openclaw
HERMES_HUMAN_SESSION_ID=<CTO_INSTANCE_ID>-pwa-john-hermes
HERMES_AGENT_SESSION_ID=<CTO_INSTANCE_ID>-a2a-openclaw-hermes
```

**Pass criteria:** a candidate PWA/backend process refuses to start or append if `CHAT_DB=/opt/cto/chat.db`. Production may use `/opt/cto/chat.db` only when `CTO_INSTANCE_ID=production`.

---

## How To Use This Document

- Each test has: **ID**, **what it proves**, **command**, **expected output**, **failure action**.
- Run linearly. If test N fails, don't run N+1 until N passes.
- The install script `scripts/install.sh` runs phases 1 and 2 automatically. Phase 3 is run by John manually after install — it requires the agent to actually do work.

---

## Phase 1 — Static Checks (run by install script as section 6 verification)

### 1.1 Both binaries on PATH
```bash
for bin in openclaw hermes engram github-mcp-server hcloud uv; do
  command -v "$bin" >/dev/null || { echo "FAIL: $bin not on PATH"; exit 1; }
done
echo "PASS: all binaries on PATH"
```
**Expected:** No fail messages, "PASS" printed.
**On fail:** Re-run install §4 for the missing binary.

### 1.2 Versions sane
```bash
openclaw --version | grep -E "v?2026\.[5-9]\." || exit 1
hermes --version | grep -E "v?0\.1[3-9]" || exit 1   # v0.13.0+ as of 2026-05-11
engram --version || exit 1
hcloud version | grep -q "hcloud" || exit 1
```
**Expected:** All exit 0.
**On fail:** Stale binaries — re-run §4 to install latest.

### 1.3 Config files exist
```bash
test -f /home/cto/.openclaw/openclaw.json || exit 1
test -f /home/cto/.hermes/config.yaml || exit 1
test -f /home/cto/.hermes/.env || exit 1
test "$(stat -c '%a' /home/cto/.hermes/.env)" = "600" || { echo "FAIL: ~/.hermes/.env not 0600"; exit 1; }
```
**Expected:** All present, `.env` 0600.
**On fail:** Re-run §5.2–5.3.

### 1.4 OpenClaw config schema valid
```bash
openclaw doctor 2>&1 | tee /tmp/doctor.out
grep -qiE "error|fail" /tmp/doctor.out && exit 1
```
**Expected:** No error/fail in output.
**On fail:** Fix config per the specific error and re-run §5.6.

### 1.5 Codex auth chain healthy (3 checkpoints)
```bash
# (a) Upstream Codex CLI auth file present
test -s ~/.codex/auth.json || { echo "FAIL: ~/.codex/auth.json missing"; exit 1; }

# (b) Token bundle has an access token + recent last_refresh
jq -e '.tokens.access_token != null and .last_refresh != null' ~/.codex/auth.json \
  >/dev/null || { echo "FAIL: ~/.codex/auth.json malformed"; exit 1; }

# (c) Both hemisphere CLIs report the openai-codex profile
openclaw models auth list | grep -q "openai-codex" || exit 1
hermes model list 2>/dev/null | grep -q "openai-codex" || \
  { echo "WARN: hermes model list may differ — verify manually with 'hermes model'"; }
```
**Expected:** All three checkpoints green.
**On fail:** Re-run §5.1 device-code flow from the failing checkpoint downstream.

### 1.6 No Telegram artefacts (per architecture-decisions-john.md #9)
```bash
grep -i telegram /home/cto/.openclaw/openclaw.json && { echo "FAIL: Telegram config present"; exit 1; }
grep -i telegram /home/cto/.hermes/config.yaml 2>/dev/null && { echo "FAIL: Telegram in Hermes config"; exit 1; }
echo "PASS: no Telegram artefacts"
```
**Expected:** No matches in either config.
**On fail:** Manually strip Telegram blocks; re-run.

### 1.7 systemd units present
```bash
systemctl --user list-unit-files | grep -E "openclaw-gateway|hermes-gateway|cto-a2a-registry|cto-hermes-a2a-sidecar|cto-pwa-backend" \
  | wc -l | grep -q "^5$" || { echo "FAIL: not all 5 core unit files installed"; exit 1; }
```
**Expected:** Five core unit files present (gateways, registry, Hermes A2A sidecar, PWA backend).
**On fail:** Re-run install §4.4, §4.5, §5.4–5.5.

### 1.8 Linger enabled
```bash
loginctl show-user "$(whoami)" | grep -q "Linger=yes" || exit 1
```
**Expected:** Linger=yes.
**On fail:** Run `sudo loginctl enable-linger "$(whoami)"`.

---

## Phase 2 — Service Checks (run by install script after start)

### 2.1 Core daemons active
```bash
for svc in openclaw-gateway hermes-gateway cto-a2a-registry cto-hermes-a2a-sidecar cto-pwa-backend; do
  systemctl --user is-active "$svc" >/dev/null || { echo "FAIL: $svc not active"; exit 1; }
done
echo "PASS: all core services active"
```
**Expected:** All five active.
**On fail:** `journalctl --user -u <svc> --since "5 minutes ago"` for the failed service.

### 2.2 Ports bound (loopback only)
```bash
ss -tlnp | grep -q "127.0.0.1:18789" || { echo "FAIL: OpenClaw 18789 not bound to loopback"; exit 1; }
ss -tlnp | grep -q "127.0.0.1:8642"  || { echo "FAIL: Hermes 8642 not bound to loopback"; exit 1; }
ss -tlnp | grep -q "127.0.0.1:8643"  || { echo "FAIL: Hermes A2A sidecar 8643 not bound to loopback"; exit 1; }
# Confirm neither is bound to 0.0.0.0
ss -tlnp | grep -E "0\.0\.0\.0:(18789|8642|8643)" && { echo "FAIL: gateway/sidecar bound to public iface"; exit 1; }
```
**Expected:** Gateway and sidecar ports on 127.0.0.1, none on 0.0.0.0.
**On fail:** Check `gateway.bind: loopback` in both configs; restart services.

### 2.3 Health endpoints respond
```bash
curl -fsS http://127.0.0.1:8642/health | grep -q '"status":\s*"ok"' || { echo "FAIL: Hermes /health"; exit 1; }
curl -fsS http://127.0.0.1:8643/health | grep -q '"status"' || { echo "FAIL: Hermes A2A sidecar /health"; exit 1; }
curl -fsS http://127.0.0.1:8088/api/health | grep -q '"status":\s*"ok"' || { echo "FAIL: PWA backend /api/health"; exit 1; }
# OpenClaw health — verify exact endpoint during install (typically /healthz or /api/health)
openclaw status | grep -qi "running\|healthy" || { echo "FAIL: OpenClaw status"; exit 1; }
```
**Expected:** Hermes, Hermes A2A sidecar, and PWA backend health endpoints respond; OpenClaw status reports running/healthy.
**On fail:** Check logs via `journalctl --user -u <service>`.

### 2.4 UFW status
```bash
sudo ufw status | grep -q "Status: active" || exit 1
sudo ufw status | grep -q "22/tcp.*ALLOW" || exit 1
# 18789 and 8642 should NOT be in ufw allow list — they're loopback-only
sudo ufw status | grep -E "18789|8642" && { echo "FAIL: gateway ports exposed in UFW"; exit 1; }
```
**Expected:** UFW active, only 22 allowed, no gateway ports.
**On fail:** Re-run §6.2.

### 2.5 A2A registry has both Agent Cards
```bash
ls /opt/cto/a2a/registry/cards/ | grep -q "openclaw" || exit 1
ls /opt/cto/a2a/registry/cards/ | grep -q "hermes" || exit 1
# Cards reachable via registry HTTP
curl -fsS http://127.0.0.1:<registry_port>/cards | grep -qE "openclaw|hermes"
```
**Expected:** Both Cards present and reachable.
**On fail:** Re-run §5.4 registry setup.

---

## Phase 3 — Functional Check (run manually after install)

> **2026-05-25 update:** Phase 3 is runnable on the live stack. OpenClaw has an `a2a-delegate` MCP server, Hermes has the A2A sidecar on `127.0.0.1:8643`, and the PWA backend can route John-addressed traffic to either hemisphere. Long-job intent is accepted as a detached PWA background job.

The canonical first-real-prompt: a single prompt that exercises decomposition → delegation → execution → synthesis → return.

### 3.1 Canonical bidirectional delegation test

**Test prompt** (sent to OpenClaw via PWA or direct OpenClaw session):

> "Identify what shipped in the Hermes Agent project in the last 7 days — pull from the GitHub releases feed and the CHANGELOG. Categorise by area (features / fixes / security / docs). Return a short structured summary."

**What should happen:**
1. **OpenClaw (thinking)** receives the prompt, decomposes it: (a) fetch GitHub releases for `NousResearch/hermes-agent`; (b) parse and categorise; (c) format summary.
2. OpenClaw delegates (a) and (b) to Hermes via A2A — Hermes does the actual fetch and parse work.
3. **Hermes (doing)** executes: hits the GitHub API or web, parses release notes, returns structured JSON to OpenClaw.
4. OpenClaw synthesises the structured output into a human-readable summary and returns it.

**Expected outcome:**
- Response time: < 60 seconds for short prompts; long-job prompts may return HTTP 202/background job ID first
- Output: structured summary with at least 3 categories populated
- Both hemispheres show activity in their respective logs
- A2A audit log (`/opt/cto/a2a/registry/audit.log`) shows at least one OpenClaw → Hermes delegation entry
- No errors in either daemon's journalctl output

**Concrete pass criteria:**
```bash
# 1. Audit log has the delegation entry
test -s /opt/cto/a2a/registry/audit.log
grep -q "openclaw.*->.*hermes" /opt/cto/a2a/registry/audit.log

# 2. Both daemons logged work
journalctl --user -u openclaw-gateway --since "2 minutes ago" | grep -qi "delegate\|a2a"
journalctl --user -u cto-hermes-a2a-sidecar --since "2 minutes ago" | grep -qi "a2a\|task\|POST"
journalctl --user -u hermes-gateway --since "2 minutes ago" | grep -qi "chat\|completion\|tool_call\|skill"

# 3. The response from OpenClaw mentions both fetched data and categorisation
# (asserted by John reading the output)
```

### 3.2 Both halves on the same Codex subscription
```bash
# A trivial prompt to each side, observe both call openai-codex
openclaw run "what is 2+2"
hermes run "what is 2+2"
# Look at journalctl for both — confirm openai-codex provider invoked
```
**Pass criteria:** Both responses arrive, both logs show `openai-codex` provider in use.

### 3.3 Verify no Telegram code paths fire
```bash
journalctl --user -u openclaw-gateway --since "10 minutes ago" | grep -i telegram \
  && { echo "FAIL: Telegram code path active"; exit 1; }
journalctl --user -u hermes-gateway --since "10 minutes ago" | grep -i telegram \
  && { echo "FAIL: Telegram code path active"; exit 1; }
echo "PASS: no Telegram activity"
```

### 3.4 Skill autoInstall blocked (OpenClaw safety)
```bash
grep -q '"autoInstall": false' /home/cto/.openclaw/openclaw.json
```

### 3.5 Backlog file accessible by both halves
```bash
test -r /opt/cto/BACKLOG.md
test -d /opt/cto/logs/backlog
```

---

## Rollback Policy

If Phase 1 fails: fix the specific item, re-run section of install-plan.md it maps to, re-test.

If Phase 2 fails: services not coming up. Likely config drift or missing env var. Check logs, fix, restart, re-test.

If Phase 3 fails after Phase 1+2 passed: the wiring is wrong between hemispheres. Either:
- A2A registry not reachable (re-run §5.4)
- Agent Cards malformed (regenerate)
- Codex auth on one side failing (re-run §5.1 for the failing side)

**Snapshot rollback skipped** per John's install direction. If full rollback is needed: VPS is at known-bad state, manually `systemctl --user stop` all services, `rm -rf ~/.openclaw ~/.hermes /opt/cto/a2a`, and re-run install from scratch.

## What This Plan Does NOT Test (deferred to v1.1)

- Hermes Phase 1-4 self-evolution loop generating PRs end-to-end
- Full long-horizon execution reliability beyond the PWA detached background-job handoff
- Shared budget meter / rate-limit awareness layer
- Daily research cycle end-to-end beyond heartbeat/watchers
- Macro-evolution promotion reliability beyond the paid Phase 4 matrix below

These are tested in subsequent upgrade cycles, one at a time per SOUL.md #15.

---

## Phase 4 — Paid Clone-Test-Replace Acceptance Plan

Run only after John approves paid infrastructure. This is the concrete clone test matrix for promotion.

### 4.1 OpenClaw
- `systemctl --user is-active openclaw-gateway` is active.
- `openclaw agent --agent main --session-id clone-smoke-openclaw --message "Reply with exactly: openclaw-ok" --thinking off --json` returns assistant text `openclaw-ok`.
- Journal shows no provider/auth errors.

### 4.2 Hermes
- `systemctl --user is-active hermes-gateway cto-hermes-a2a-sidecar` is active.
- `curl http://127.0.0.1:8642/health` and `curl http://127.0.0.1:8643/health` return ok.
- A direct sidecar A2A request with sender `john` returns conversational text and uses the candidate `HERMES_HUMAN_SESSION_ID`.

### 4.3 PWA
- `curl http://127.0.0.1:8088/api/health` returns ok.
- Auth rejects `/api/messages` without `PWA_AUTH_TOKEN`.
- A token-authenticated short `@openclaw` message returns HTTP 202 and later appends an OpenClaw chat row.
- A token-authenticated short `@hermes` message returns HTTP 202 and later appends a Hermes chat row.

### 4.4 A2A and coordinated `@both` routing
- `@both` produces one OpenClaw strategy row first, then one Hermes implementation row with the same coordination id.
- Mixed mentions such as `@openclaw ... @hermes ...` route to coordinated `both`, not parallel independent replies.
- `a2a_request` and `a2a_response` rows are present for Hermes sidecar traffic.

### 4.5 Memory
- `MEMORY.md`, `memory/`, and `wiki/` are present and readable by both process users.
- Engram/SQLite files are initialized without corrupting or overwriting production memory artifacts.
- `BACKLOG.md` and `logs/decisions/` are readable from OpenClaw and Hermes working directories.

### 4.6 Keepalive
- `cto-cache-keepalive.timer` is installed and active.
- A manual `scripts/cache-keepalive.sh` run exits 0 and pings candidate session ids, not production session ids.
- Keepalive failures append `system_event` rows to the candidate chat DB only.

### 4.7 Background jobs
- A long-job PWA prompt returns HTTP 202 with `background=true` and a `pwa-bg-*` id.
- `services/pwa/backend/job_runner.py` records the job in the candidate `PWA_JOB_DB` and posts final output to the candidate chat DB.
- A failed job emits `pwa_background_job_failed` or `pwa_background_job_crashed` as a `system_event`.

### 4.8 Promotion blockers
Any one of these blocks promotion: production `chat.db` touched by candidate; gateway/sidecar bound to public interfaces; OpenRouter references in active config; missing Codex OAuth on either hemisphere; PWA auth disabled on a public host; failing no-spend validation script; dirty uncommitted repo changes not explained in HANDOFF.
