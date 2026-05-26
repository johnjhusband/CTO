# BACKLOG-013 — PWA auth restore after blank token restart

Timestamp: 2026-05-26T21:32Z

## Selected item
BACKLOG-013 / BACKLOG-009 P0 PWA access control. The live PWA backend was observed running with `PWA_AUTH_TOKEN` unset after a recent token-rotation attempt, which put the backend in dev/no-auth mode.

## Action taken
- Restored the previous non-empty `PWA_AUTH_TOKEN` line from the local root-owned/operator backup in `/home/cto/.cto-secret-backups/` without printing or storing the token value.
- Wrote a new local pre-restore `.env` backup under `/home/cto/.cto-secret-backups/` with mode `0600`.
- Restarted `cto-pwa-backend.service`.

## Verification
- `/opt/cto/.env` contains a non-empty `PWA_AUTH_TOKEN` again; value length only was checked, not recorded.
- `cto-pwa-backend.service`: active after restart.
- No `PWA_AUTH_TOKEN not set` warning appeared after the restart window.
- Unauthenticated `GET /`: HTTP 401.
- Unauthenticated `GET /api/messages?since_id=0`: HTTP 401.
- Legacy query-token API access against `/api/messages` with a placeholder token parameter: HTTP 401.
- `GET /api/health`: returned `{"status":"ok","service":"pwa-backend"}`.
- `scripts/security/run-safe-security-gates.sh` passed: secret artifact guard, operational redaction check, 6/6 redaction unit tests, and 20/20 PWA auth/routing tests.

## Remaining
Live PWA token rotation is still blocked until there is a working secure out-of-band delivery path for the new token. The unsafe state was removed; no secret values were committed or written to this artifact.
