#!/usr/bin/env python3
"""Repair the existing Hermes cron watchdog into an LLM-bound autonomy loop.

This does not create a second scheduler. It updates the existing Hermes cron job
that was previously a no-agent health watchdog so the already-running scheduler
can periodically pick safe CTO backlog work and produce verifiable artifacts.
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

JOBS_PATH = Path.home() / ".hermes" / "cron" / "jobs.json"
WATCHDOG_SCRIPT = "cto_health_watchdog.py"
JOB_NAME = "CTO autonomous backlog work loop"
PROMPT = """You are Hermes, right hemisphere of CTO, running from the existing Hermes cron scheduler. Do not create or modify cron jobs. Work in /opt/cto only. Your job on each tick is to prevent idle drift by producing one small, verifiable artifact.

Prerequisites:
1. Read /opt/cto/AGENTS.md, /opt/cto/MEMORY.md, /opt/cto/HERMES_ROLE.md, and /opt/cto/BACKLOG.md enough to choose safe work.
2. Check git status. Do not overwrite or commit unrelated uncommitted changes; commit only files you create or intentionally edit.
3. If the injected watchdog script context reports a health/security alert, prioritize a safe diagnostic artifact for that alert.

Selection rule:
Pick the highest-priority unblocked CTO backlog or standing-work item that can be advanced safely without spending money, destroying data, rotating live credentials, changing external services, or needing John's non-retrievable decision. If all high-priority items are blocked by those constraints, pick a safe evidence-gathering or documentation/testing substep for the highest-priority item.

Execution rule:
Produce a real artifact every run: a log under /opt/cto/logs/repairs/, /opt/cto/logs/research/, /opt/cto/logs/security/, or a small script/test/doc improvement. Include exact before/after evidence and a verification command in the artifact. If code/docs changed, run a focused verification command. Commit only your own changed artifact(s) with a concise subject. If no safe work is possible, create a BACKLOG entry only after documenting the exact blocker and search/evidence trail.

Final response:
Return structured JSON with selected_item, artifacts, commit (or null), verification_command, verification_result, and blockers. Keep it concise."""


def main() -> int:
    data = json.loads(JOBS_PATH.read_text())
    jobs = data.get("jobs", [])
    matches = [j for j in jobs if j.get("script") == WATCHDOG_SCRIPT or j.get("name") in {"CTO health watchdog", JOB_NAME}]
    if len(matches) != 1:
        raise SystemExit(f"expected exactly one Hermes watchdog cron job, found {len(matches)}")

    job = matches[0]
    job.update(
        {
            "name": JOB_NAME,
            "prompt": PROMPT,
            "skills": ["systematic-debugging"],
            "skill": "systematic-debugging",
            "script": WATCHDOG_SCRIPT,
            "no_agent": False,
            "enabled_toolsets": ["terminal", "file", "skills"],
            "workdir": "/opt/cto",
        }
    )
    job.setdefault("schedule", {})["kind"] = "interval"
    job["schedule"]["minutes"] = 45
    job["schedule"]["display"] = "every 45m"
    job["schedule_display"] = "every 45m"
    data["updated_at"] = datetime.now(timezone.utc).isoformat()
    JOBS_PATH.write_text(json.dumps(data, indent=2) + "\n")
    print(f"updated {job.get('id')} -> {JOB_NAME}; no_agent={job.get('no_agent')}; schedule={job.get('schedule_display')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
