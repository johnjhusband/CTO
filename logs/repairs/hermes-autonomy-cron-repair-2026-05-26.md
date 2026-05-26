# Hermes autonomy scheduler repair — 2026-05-26

## Scope
Hermes-side inspection for the coordinated scheduler repair task. OpenClaw owns OpenClaw cron and final integration; this artifact covers the Hermes scheduler layer only.

## Existing schedulers found

1. Hermes cron scheduler
- Job id: `99e93c7b440d`
- Before: name `CTO health watchdog`, schedule `every 30m`, script `cto_health_watchdog.py`, `no_agent=true`, empty prompt, no workdir/toolsets.
- Actual behavior: it fired successfully (`last_status=ok`) but only ran the no-agent health script. The script prints only health alerts, so healthy runs are silent and cannot select backlog work or create artifacts.

2. systemd user timers owned by the CTO install
- `cto-watcher-heartbeat.timer` every 30s: keeps OpenClaw alive/restarts on health failure.
- `cto-watcher-health.timer` every 60s: checks service endpoints/disk/heartbeat freshness and invokes repair only on repeated failures.
- `cto-watcher-anomaly.timer` every 60s: writes anomaly context only; explicitly never triggers action.
- `cto-cache-keepalive.timer` every 30m: pings OpenClaw/Hermes sessions with one-word keepalives to preserve prompt-cache/session warmth.
- Actual behavior: all are firing, but they are health/cache mechanisms, not LLM-bound work selectors.

## Root cause
The scheduler infrastructure was present and firing, but the only Hermes cron job capable of using the Hermes scheduler was configured as `no_agent=true` with an empty prompt. That made it a script-only watchdog, not an autonomous work loop. The 30-minute keepalive timer also deliberately requested one-word replies, so it kept sessions warm but reinforced idle behavior instead of producing artifacts.

## Repair
Updated the existing Hermes cron job `99e93c7b440d`; no new scheduler was created.

After:
- name: `CTO autonomous backlog work loop`
- schedule: `every 45m`
- script: `cto_health_watchdog.py` remains attached as pre-run health context
- `no_agent=false`
- workdir: `/opt/cto`
- enabled toolsets: `terminal,file,skills`
- skill: `systematic-debugging`
- prompt: pick the highest-priority unblocked safe CTO backlog/standing-work item, produce one verifiable artifact, avoid spend/destruction/live credential rotation/external-service changes, commit only intentional files, and return structured JSON.

## Versioned repair artifact
Created `scripts/repair/configure-hermes-autonomy-cron.py` so the repair is reproducible and idempotent. It edits the existing Hermes watchdog cron job in `~/.hermes/cron/jobs.json`; it errors if it cannot find exactly one matching existing watchdog job.

## Verification
Commands run:

```bash
cd /opt/cto
python3 scripts/repair/configure-hermes-autonomy-cron.py
python3 -m py_compile scripts/repair/configure-hermes-autonomy-cron.py
python3 /home/cto/.hermes/scripts/cto_health_watchdog.py; echo watchdog_rc=$?
```

Observed output:

```text
updated 99e93c7b440d -> CTO autonomous backlog work loop; no_agent=False; schedule=every 45m
watchdog_rc=0
```

Hermes cron list after repair showed the same job id `99e93c7b440d` enabled as `CTO autonomous backlog work loop`, schedule `every 45m`, script `cto_health_watchdog.py`, `no_agent=false`, workdir `/opt/cto`, and toolsets `terminal,file,skills`.

## Remaining integration note
This fixes the Hermes-side scheduler. OpenClaw still needs to complete its side of the coordinated task by inspecting OpenClaw cron / `cto-*` timers it owns and deciding whether this Hermes cron loop is the final cross-hemisphere work trigger or whether OpenClaw should add complementary routing/final-integration behavior.
