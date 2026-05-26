#!/usr/bin/env python3
"""Configure Hermes' daily /opt/cto sync-audit cron job.

The job writes its own one-line result into the CTO PWA chat DB because Hermes
cron delivery has no stable origin target in A2A-created jobs. Scheduler delivery
is set to local to avoid stale unresolved-delivery errors; chat visibility is
handled explicitly by the agent job itself.
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

JOBS_PATH = Path.home() / ".hermes" / "cron" / "jobs.json"
JOB_ID = "66b2675817d2"
JOB_NAME = "CTO Hermes daily sync audit"
CRON_EXPR = "53 17 * * *"
PROMPT = """Daily Hermes sync audit for /opt/cto. You are Hermes, CTO's right hemisphere, implementing John's coordinated sync-audit request under OpenClaw strategy/routing authority. Do not create or modify cron jobs from this cron run.

Run as an agent job (no_agent=false). Audit scope:
1. /opt/cto uncommitted changes.
2. HEAD vs origin/master divergence after fetching origin/master.
3. VPS-vs-origin push divergence, because Hermes owns the credential-helper repair.
4. New untracked or ignored secret-looking files matching: .env, .vapid*, *.pem, *.key. Never print secret contents; only report paths/metadata and whether ignored/tracked.
5. Any .vapid-new/ or .vapid-compromised-*/ artifacts that should have been gitignored or rotated.

Required behavior:
- If clean, prepare exactly this concise line: `sync-audit clean: /opt/cto clean and HEAD matches origin/master; no untracked secret artifacts requiring action`.
- If dirty, fix safely: inspect paths, do not expose secrets, gitignore/quarantine/rotate artifacts only when appropriate, commit focused changes, push origin/master, document the fix under /opt/cto/logs/repairs/, then prepare one concise line per remaining item or one clean line if resolved.
- Do not spend money, destroy data/infrastructure, rewrite public history, rotate live credentials, or touch repos outside /opt/cto.
- Always append the final one-line status to the CTO PWA chat database using this pattern from /opt/cto:
  `python3 - <<'PY'\nfrom services.chat.db import append\nappend(sender='hermes', recipient='john', kind='chat', content='YOUR ONE-LINE STATUS')\nPY`
  Escape quotes safely and do not include secrets or raw tool traces.

Verification commands to prefer:
- `git status --short`
- `git fetch origin master --quiet && git rev-list --left-right --count HEAD...origin/master`
- `git ls-files --others --exclude-standard` and `git ls-files -o -i --exclude-standard` filtered for the secret-looking path patterns above
- `git push origin master` only if there are local commits ahead of origin/master.

Final response must be concise structured JSON with: clean boolean, chat_line_appended boolean, commits, pushed boolean, repair_docs, remaining_items."""


def main() -> int:
    data = json.loads(JOBS_PATH.read_text())
    jobs = data.get("jobs", [])
    matches = [j for j in jobs if j.get("id") == JOB_ID or j.get("name") == JOB_NAME]
    if len(matches) != 1:
        raise SystemExit(f"expected exactly one {JOB_NAME!r} job, found {len(matches)}")
    job = matches[0]
    job.update(
        {
            "name": JOB_NAME,
            "prompt": PROMPT,
            "skills": ["systematic-debugging"],
            "skill": "systematic-debugging",
            "script": None,
            "no_agent": False,
            "enabled_toolsets": ["terminal", "file", "skills"],
            "workdir": "/opt/cto",
            "deliver": "local",
        }
    )
    job["schedule"] = {"kind": "cron", "expr": CRON_EXPR, "display": CRON_EXPR}
    job["schedule_display"] = CRON_EXPR
    job["enabled"] = True
    job["state"] = "scheduled"
    data["updated_at"] = datetime.now(timezone.utc).isoformat()
    JOBS_PATH.write_text(json.dumps(data, indent=2) + "\n")
    print(f"configured {job['id']} {JOB_NAME}: schedule={CRON_EXPR} no_agent={job['no_agent']} deliver={job['deliver']} workdir={job['workdir']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
