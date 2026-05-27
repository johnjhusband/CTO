# BACKLOG-005 history marker rescan — 2026-05-27T09:25Z

## Scope
OpenClaw continuous work-pump tick selected the highest-priority safe P0 security item that could be advanced without a coordinated credential/history-rewrite window: BACKLOG-005 VAPID/Web Push private-key history exposure.

No secrets were printed or stored, no credential was rotated/revoked, no history rewrite was attempted, no infrastructure was changed, and no semantic work was delegated to Hermes because the Hermes provider circuit is open.

## Required pre-selection checks
- A2A2H upstream-port check: clean. `git log 27abb1203d2a13253e8c1b7e9658518d77794236..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no upstream-eligible commits, so no port was required.
- Recent PWA/John messages inspected: latest John-facing status still asks for phone-side confirmation of voice/background/toggle behavior.
- Service health inspected: no failed user units; OpenClaw Gateway active.
- Hermes circuit: open/degraded with `agent_incomplete_provider_NoneType`; OpenClaw handled this tick directly.
- Backlog completion scan: no open/pending item was safely closable from disk evidence. P0 credential/history work remains blocked on coordinated rotation/scrub; PWA P0 items remain pending phone/device evidence where their backlog entries require it.

## Verification result
Ran `scripts/security/check-git-history-secret-markers.sh` non-destructively.

Result: failed as expected while BACKLOG-005 remains unresolved. The scanner found 18 private-key-block markers across 327 revisions, all at the historical path `.vapid/private.pem`. The scan output prints only revision prefixes, marker names, and paths; it does not print secret values.

## Current blocker
BACKLOG-005 remains in `dry_run_verified_pending_coordinated_history_scrub` until John approves a coordinated history scrub/rewrite and any required downstream clone/remote coordination. This tick refreshed the evidence and confirmed the known leak is still confined to the VAPID private-key history marker path detected by the safe scanner.
