# Email status adapter — 2026-05-26

## Problem
John requested regular status updates by email to john@husband.llc. BACKLOG-015 tracks this as P1, but no SMTP/send credentials are configured on the host.

## Change
Added `scripts/send-status-email.py`, a credential-safe SMTP sender for CTO status updates. It reads secrets only from environment variables, supports `--dry-run`, defaults to the newest `/opt/cto/logs/digest/digest-*.md`, and otherwise reads stdin. No credentials are stored in git.

## Verification
- `python3 -m py_compile scripts/send-status-email.py`
- `printf 'status body' | scripts/send-status-email.py --dry-run --subject 'CTO dry run'`

## Blocker
Actual email delivery remains blocked until SMTP credentials/provider settings are supplied through environment variables: `CTO_EMAIL_SMTP_HOST`, `CTO_EMAIL_SMTP_USER`, `CTO_EMAIL_SMTP_PASSWORD`, and optionally `CTO_EMAIL_SMTP_PORT`, `CTO_EMAIL_FROM`, `CTO_EMAIL_TO`.
