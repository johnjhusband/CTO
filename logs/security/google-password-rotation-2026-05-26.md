# Google account password rotation — 2026-05-26

John stated the password supplied in PWA chat is for the Google account backing cto@husband.llc, and therefore also affects OpenAI identity via Google SSO.

Security posture:
- Treat the password pasted into PWA chat as exposed because the PWA access-control issue is not fully closed yet.
- Do not write the password value into docs, logs, memory, git, backlog, or chat.
- A new candidate password was generated and stored only as `GOOGLE_ACCOUNT_PASSWORD_PENDING` in `/opt/cto/.env` (0600) pending successful Google account password change.
- Do not rename it to an active key until Google confirms the password was changed.

Current blocker:
- No usable attached browser session is available from this runtime. Google password change likely requires interactive login/2FA/recovery verification.

Post-change verification checklist:
- Verify Google login/mail access.
- Verify OpenAI/Codex OAuth still works or re-auth OpenClaw/Hermes if Google invalidates sessions.
- Verify OpenClaw gateway, Hermes gateway, Hermes A2A delegation, and PWA backend.
- Replace pending secret with active secret key after successful rotation.
