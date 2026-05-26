# OpenClaw Daily Sync-Audit Scheduler — 2026-05-26

## Trigger
John requested OpenClaw add a daily self-audit for `/opt/cto` covering uncommitted changes, HEAD vs `origin/master` divergence, and new untracked secret-looking files (`.env`, `.vapid*`, `*.pem`, `*.key`).

## Change
- Added `scripts/openclaw-sync-audit.sh` to perform the deterministic repo audit without printing secret contents.
- Added an OpenClaw cron job named `CTO OpenClaw daily sync audit` to run the audit as an agent turn daily at an off-minute.
- The cron agent is instructed to fix dirty state by committing focused changes, pushing to origin, writing repair documentation under `logs/repairs/`, and reporting concise chat status.

## Validation
- Ran `scripts/openclaw-sync-audit.sh` manually before scheduler creation; it correctly detected current uncommitted files and no origin divergence.
- Manual scheduler run is recorded separately once the cron job exists.

## Rollback
- Remove the OpenClaw cron job with `openclaw cron rm <job-id>`.
- Revert the commit adding `scripts/openclaw-sync-audit.sh` and this repair document if the workflow is replaced.
