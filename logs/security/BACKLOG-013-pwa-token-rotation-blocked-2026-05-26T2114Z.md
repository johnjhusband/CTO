# BACKLOG-013 PWA Token Rotation Blocked

Timestamp: 2026-05-26T21:14Z

Result: rotation was not completed.

Reason: SMTP out-of-band delivery failed with provider authentication rejection before the PWA backend was restarted. To avoid locking John out without a secure delivery path, `/opt/cto/.env` was restored from the pre-rotation backup, then the backup was moved outside the git workspace under `/home/cto/.cto-secret-backups/` and the PWA backend was not restarted with the undelivered token.

Secret handling: no token values were printed, committed, or written to this evidence file.

Next safe step: establish a working secure out-of-band delivery path or use an interactive session where John can receive the new token directly without storing it in PWA chat history.
