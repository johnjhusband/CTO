# BACKLOG-003 read-only exposure baseline — 2026-05-27T08:40Z

## Selection
OpenClaw selected BACKLOG-003 (public repo/live deployment security audit) after the required per-tick A2A2H check and backlog completion scan. Higher P0 security items BACKLOG-005/BACKLOG-006 remain blocked on a coordinated credential-rotation/history-scrub window; P0 PWA items remain implemented/runtime-verified but pending John/device evidence.

## Required pre-checks
- A2A2H upstream-port check: `git log 27abb1203d2a13253e8c1b7e9658518d77794236..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no commits; no port required this tick.
- `/opt/cto` and `/opt/a2a2h` were clean before selection.
- Hermes provider circuit: open after repeated provider-side `agent_incomplete_provider_NoneType`; no semantic Hermes delegation was attempted.
- User services: no failed user units; OpenClaw gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers were listening/active.
- Backlog completion scan: no open/pending item was safely closable from disk evidence. BACKLOG-004, BACKLOG-014, and BACKLOG-016 still need John/device evidence before closure.

## Read-only checks performed
- Host context: Ubuntu 24.04.4 LTS on `cto-v1`.
- OpenClaw model self-check: current model is `openai-codex/gpt-5.5`, suitable for this pass.
- OpenClaw security audit: `openclaw security audit --deep` reported 0 critical, 1 warning, 1 info.
- OpenClaw update status: stable install has update available `2026.5.22`; no update was run.
- Local exposure snapshot: public listeners are SSH 22 and HTTP/HTTPS 80/443; OpenClaw/Hermes/PWA services are loopback-bound.
- OS updates: `unattended-upgrades.service` is enabled and active.
- Hetzner read-only inventory: two running servers in the project (`recrm`, `cto-v1`); no Hetzner Cloud firewalls; no volumes; no floating IPs.

## Findings advanced
1. **Cloud firewall gap remains real (BACKLOG-007 tie-in):** Hetzner reports zero cloud firewalls and `cto-v1` has no firewall attached. This confirms deny-by-default perimeter work is still outstanding and should be staged carefully to avoid SSH lockout.
2. **Backup/protection gap remains real (BACKLOG-010 tie-in):** `cto-v1` has `backup_window: null`, no attached volumes, and delete/rebuild protection is false. Enabling backups or protection would be a billable/state-changing action, so it was not performed without John approval.
3. **OpenClaw proxy warning remains:** `gateway.trusted_proxies_missing` is the only OpenClaw audit warning. Because the gateway bind is loopback, this is not immediately critical, but it should be reconciled with the reverse-proxy deployment before exposing any Control UI path.
4. **Update available:** OpenClaw `2026.5.22` is available. Updating is state-changing and should be handled under the upgrade/clone-test policy, not in this read-only security tick.

## Safe next actions queued
- Draft a deny-by-default firewall plan for `cto-v1` that preserves SSH plus 80/443 and leaves loopback services unexposed; require explicit approval before applying.
- Draft a backup/deletion-protection plan with cost/operational impact for John before enabling backups or protections.
- Validate whether `gateway.trustedProxies` should include only the local reverse proxy address, using the first-class gateway config path rather than direct config edits.

## Verification
- `python3 -m json.tool logs/backlog/BACKLOG-003.json` passed after appending the tracker note.
- `scripts/security/run-safe-security-gates.sh` passed after writing this artifact and tracker update.

## Result
Produced a current read-only security baseline for BACKLOG-003 without spending money, changing firewall/SSH, modifying credentials, restarting services, or delegating to degraded Hermes. No secrets, raw headers, environment values, or raw provider traces were recorded.
