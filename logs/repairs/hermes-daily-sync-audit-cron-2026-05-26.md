# Hermes daily sync-audit cron — 2026-05-26

## Request
OpenClaw delegated John’s request for a Hermes-owned daily sync audit: inspect `/opt/cto` dirty state, HEAD vs `origin/master`, VPS-vs-origin push divergence, untracked/ignored secret-looking artifacts, and VAPID rotation directories. The job must be agent-running (`no_agent=false`), daily at an off-minute, manually validated once before relying on the timer.

## Implementation
Updated existing Hermes cron job `66b2675817d2` rather than creating a duplicate.

- Name: `CTO Hermes daily sync audit`
- Schedule: `53 17 * * *`
- Enabled: true
- Agent-running: `no_agent=false`
- Workdir: `/opt/cto`
- Skill: `systematic-debugging`
- Enabled toolsets: `terminal,file,skills`

## Behavior
The cron prompt requires the agent to:

1. Check `/opt/cto` uncommitted changes.
2. Fetch `origin/master` and compare `HEAD...origin/master`.
3. Check VPS-vs-origin push divergence.
4. Detect untracked or ignored secret-looking files matching `.env`, `.vapid*`, `*.pem`, and `*.key` without printing secret contents.
5. Detect `.vapid-new/` or `.vapid-compromised-*/` artifacts that should be ignored or rotated.
6. If clean, report one concise clean line.
7. If dirty, fix safely, document under `logs/repairs/`, commit focused changes, push `origin/master`, and report remaining items.

## Manual pre-validation before commit
Before committing this repair doc, the current repository state was checked:

```bash
git status --short
git fetch origin master --quiet
git rev-list --left-right --count HEAD...origin/master
```

Observed:

```text
clean working tree
0 0
```

Secret-artifact metadata check showed only ignored runtime stores such as `.env`, `.vapid/`, `.vapid-new/`, and PEMs inside ignored venv/certifi locations. No tracked secret contents were printed.

## Manual cron validation
After this repair log is committed and pushed, the job is run once manually with Hermes cron. Expected clean result: the job completes with `last_status=ok`, `no_agent=false`, schedule remains `53 17 * * *`, and any local repair commit is already pushed before the audit runs.
