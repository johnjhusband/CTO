# Hermes sync-audit chat delivery repair — 2026-05-26T19:20Z

## Selected item
Broken communication/reporting for the Hermes daily sync-audit cron.

## Why this item
The daily sync-audit job `66b2675817d2` existed and had run with `last_status=ok`, but Hermes cron delivery reported `no delivery target resolved` for both `deliver=origin` and later `deliver=all`. That meant the audit could succeed internally without producing John's required one-line chat status.

## Root cause
The job was created/updated from A2A/tool context, so Hermes cron had no stable platform origin target to resolve. `deliver=all` also did not resolve a connected channel for this scheduler context. Relying on scheduler delivery alone is therefore insufficient for this CTO PWA reporting path.

## Repair
Added `scripts/repair/configure-hermes-daily-sync-audit.py` and ran it. It configures the existing job `66b2675817d2` without creating a duplicate:

- schedule `53 17 * * *`
- `no_agent=false`
- workdir `/opt/cto`
- toolsets `terminal,file,skills`
- skill `systematic-debugging`
- scheduler delivery `local` to avoid unresolved-delivery noise
- prompt requires the agent to append the final one-line clean/dirty status directly to `/opt/cto/chat.db` through `services.chat.db.append(sender='hermes', recipient='john', kind='chat', ...)`

## Verification before manual run

```bash
python3 scripts/repair/configure-hermes-daily-sync-audit.py
python3 -m py_compile scripts/repair/configure-hermes-daily-sync-audit.py
python3 - <<'PY'
import json
from pathlib import Path
job=[j for j in json.loads((Path.home()/'.hermes/cron/jobs.json').read_text())['jobs'] if j['id']=='66b2675817d2'][0]
assert job['schedule_display']=='53 17 * * *'
assert job['no_agent'] is False
assert job['deliver']=='local'
assert job['workdir']=='/opt/cto'
assert set(job['enabled_toolsets'])=={'terminal','file','skills'}
assert 'append(sender=' in job['prompt']
print('hermes_daily_sync_audit_config_ok')
PY
```

Observed: `hermes_daily_sync_audit_config_ok`.

## Manual run expectation
After this repair artifact is committed and pushed, run job `66b2675817d2` once manually and verify:

- cron `last_status=ok`
- `/opt/cto/chat.db` contains the one-line sync-audit status from Hermes
- `/opt/cto` returns to clean `master...origin/master`
