# Candidate Clone Handoff — 2026-05-25

Candidate: cto-candidate-202605250519
Hetzner server id: 132825157
Public IPv4: 46.225.228.40
Role: parity clone candidate, TEST MODE only
Status: running for John morning testing

## Authority and constraints
- John authorized Hetzner spend after both hemispheres agreed.
- John authorized credential sharing with the clone for parity testing.
- John authorized automatic destruction of failed candidate VPSs, but this candidate has not been destroyed because it reached the testable state.
- The original CTO remains authoritative and must not be deleted by either hemisphere.
- This candidate is parity-only, not an improvement successor.
- Candidate promotion/deletion of original requires John’s explicit later decision after morning testing.

## Isolation / test mode
- `/opt/cto/.env` has `CTO_INSTANCE_ID=candidate-cto-candidate-202605250519`.
- `/opt/cto/.env` has `CTO_TEST_MODE=1`.
- Candidate chat DB is `/opt/cto/.candidate/candidate-cto-candidate-202605250519/chat.db`.
- PWA/OpenClaw/Hermes sessions are candidate-scoped.
- Hetzner labels include `purpose=cto`, `role=clone-candidate`, `test_mode=true`, `version=v2`.
- `scripts/install.sh` refuses self-cloning from a test-mode host unless `ALLOW_TEST_MODE_SELF_CLONE=1` is explicitly set for operator debugging.

## Credential handling
- Copied required Codex/Hermes/OpenClaw credential state from the original to the candidate using SSH/SCP.
- Secret values were not written into this handoff.
- Install logs on the candidate were redacted for the Hermes API server key after an early installer command printed it.

## Install issues repaired during candidate build
1. OpenClaw 2026.5.22 no longer accepts `openclaw onboard --skip-auth`; patched installer to use `--auth-choice skip`.
2. `hermes gateway install` prompted interactively; answered prompts during this run. Installer should be hardened later if fully unattended installs are required.
3. `install-cto.sh` attempted to copy `/opt/cto/scripts/cache-keepalive.sh` onto itself and failed; patched to chmod when source and destination are identical.
4. Candidate chat DB parent directory did not exist; patched `services/chat/db.py` to create parent directories before SQLite connect.
5. Hermes API server was not listening on 8642 until `API_SERVER_ENABLED=1`, `API_SERVER_HOST=127.0.0.1`, and `API_SERVER_PORT=8642` were added to the Hermes gateway systemd drop-in.
6. Hermes needed `~/.hermes/auth.json` in addition to `~/.codex/auth.json`; OpenClaw needed its auth profiles and gateway token copied for parity.

## Verification passed
- `bash scripts/validate-no-spend.sh` on original: PASS.
- Candidate `python3 tests/test_pwa_routing.py`: PASS, 7 tests.
- Candidate core services active: `openclaw-gateway`, `hermes-gateway`, `cto-a2a-registry`, `cto-hermes-a2a-sidecar`, `cto-pwa-backend`.
- Candidate ports bound to loopback: 18789, 8642, 8643, 9000, 8088.
- Health checks passed: Hermes API `/health`, Hermes A2A sidecar `/health`, A2A registry `/health`, PWA `/api/health`.
- PWA rejects unauthenticated `/api/messages` with HTTP 401.
- Candidate chat append writes to candidate chat DB, not production chat DB.
- Hermes A2A smoke returned `OK` through the sidecar.
- OpenClaw agent smoke returned `openclaw-ok`.
- PWA `@hermes reply exactly OK` returned `OK`.
- PWA coordinated `@both` smoke produced OpenClaw before Hermes; order check passed.
- `scripts/cache-keepalive.sh` exited 0 on candidate.

## Known caveats
- The candidate installer’s internal `git push` failed because origin advanced; not promotion-blocking for parity test, but repo changes should be reconciled on original before any final promotion.
- Candidate install was completed with targeted repairs after `install-cto.sh` failed its first verification pass; not a pristine one-shot install yet.
- Gmail MCP credentials were absent on the original source host, so Gmail MCP remains uncredentialed on the candidate.
- Caddy is installed and configured for `cto.husband.llc`; DNS still points at production, so John should test candidate by SSH/local port forwarding or direct IP plus token only if intentionally configured.

## Suggested John morning test
1. SSH to candidate if needed: `ssh -i ~/.ssh/cto-deploy cto@46.225.228.40` from the original host context.
2. Verify `CTO_TEST_MODE=1` and `CHAT_DB=/opt/cto/.candidate/.../chat.db` in `/opt/cto/.env`.
3. Exercise PWA through a safe tunnel or direct backend health checks without changing DNS.
4. Confirm no production PWA chat contamination.
5. Decide whether this parity clone is acceptable as a clone-test-replace baseline. Do not approve deletion of the original unless a later explicit promotion plan is reviewed.

## Rollback / destroy path
If John rejects this candidate, destroy only the candidate VPS id 132825157 after preserving any desired logs. Do not touch the production/original CTO VPS.
