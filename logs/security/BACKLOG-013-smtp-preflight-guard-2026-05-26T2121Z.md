# BACKLOG-013 PWA token rotation SMTP preflight guard — 2026-05-26T21:21Z

## Selected item
BACKLOG-013 / BACKLOG-009 P0 security/access-control: PWA access-token rotation is still needed, but the previous rotation attempt was blocked because the secure out-of-band SMTP delivery path rejected authentication.

## Safe action
Added an explicit `--check-credentials` mode to `/opt/cto/scripts/send-status-email.py`. It authenticates to the configured SMTP server and exits before sending any message. This gives future rotation attempts a safe preflight: do not generate or install a new PWA token unless the out-of-band delivery channel passes first.

## Evidence collected without secret values
- Recent PWA chat showed John explicitly requested rotation at 21:13Z and OpenClaw reported the token rotation attempt was restored/blocked rather than completed.
- `/opt/cto/logs/security/BACKLOG-013-pwa-token-rotation-blocked-2026-05-26T2114Z.md` records that SMTP authentication rejection blocked secure token delivery.
- Current SMTP preflight result against the configured runtime environment: `SMTPAuthenticationError code=535`; no message sent.
- No SMTP usernames, passwords, tokens, or generated replacement PWA token values were written to this artifact.

## Verification
- `python3 -m unittest tests.test_send_status_email tests.test_redact_operational_secrets tests.test_pwa_routing` passed: 28 tests.
- `scripts/security/run-safe-security-gates.sh` passed: secret artifact guard, operational redaction check, redaction unit tests, and PWA auth/routing regression tests.

## Result
The next rotation attempt now has a no-send SMTP credential preflight guard, and the live blocker is verified as SMTP authentication failure rather than missing code path.

## Remaining blockers
- PWA access-token rotation remains blocked until SMTP credentials are corrected or John is in an interactive secure handoff window.
- Public history cleanup/secret scrubbing remains coordinated approval-window work and was not attempted in this unattended pump tick.
