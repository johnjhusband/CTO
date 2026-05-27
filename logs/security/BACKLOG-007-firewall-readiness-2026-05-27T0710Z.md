# BACKLOG-007 firewall readiness audit — 2026-05-27T07:10Z

## Selection
OpenClaw continuous work pump selected BACKLOG-007 after the required A2A2H drift check was clean. Higher P0 items remain blocked or waiting on non-retrievable external confirmation:

- BACKLOG-005: runtime VAPID rotation and disposable history-scrub dry run are complete; final public history rewrite/force-push remains destructive and requires a coordinated John-approved window or risk acceptance.
- BACKLOG-006: recurring safe credential gates are ready, but live credential rotation/revocation still requires a coordinated rotation window.
- BACKLOG-004/BACKLOG-014/BACKLOG-016: visible PWA features are shipped/runtime-verified; final closure still requires John/device evidence for voice, phone notification display, and phone coordination-toggle visibility.

BACKLOG-007 is the highest-priority safe security item that can be advanced read-only without changing firewall rules, risking lockout, or mutating infrastructure.

## Required checks
- Continuous-work policy, HEARTBEAT, BACKLOG, A2A2H maintenance protocol, A2A2H_LAST_SYNC, recent PWA chat, git status, service health, and recent verification logs were inspected.
- A2A2H per-tick drift command used tracker SHA `2208320fa5761e5e8318133860fc64e840d79d89` over `services/pwa`, `services/hermes_a2a_sidecar`, `services/a2a_delegate`, `scripts/cache-keepalive.sh`, and `services/chat/db.py`.
- Result: no upstream-eligible CTO commits since the tracker SHA; no A2A2H port required this tick.

## Read-only perimeter inventory
Hetzner API read-only inventory showed:

| Server | ID | Status | Public IPv4 | Public IPv6 | Cloud firewalls |
|---|---:|---|---|---|---|
| `recrm` | `128886775` | running | `91.99.60.73` | `2a01:4f8:1c18:1956::/64` | none |
| `cto-v1` | `130627001` | running | `46.224.81.84` | `2a01:4f8:1c18:feb::/64` | none |

Hetzner firewall list returned `0` firewalls. Primary IP inventory returned 4 assigned primary IPs, all with delete protection disabled and no firewall attachment visible through server public_net.

Local listener snapshot on `cto-v1`:

- Public: SSH `0.0.0.0:22` and `[::]:22`, HTTP `*:80`, HTTPS `*:443`.
- Loopback-only: PWA backend `127.0.0.1:8088`, Hermes gateway `127.0.0.1:8642`, Hermes A2A sidecar `127.0.0.1:8643`, OpenClaw gateway `127.0.0.1:18789`, OpenClaw auxiliary `127.0.0.1:18791`, local service `127.0.0.1:9000`, Caddy admin `127.0.0.1:2019`, local DNS.

## Safe candidate firewall policy (not applied)
A lockout-safe Hetzner cloud firewall candidate for CTO production should be staged on a disposable/candidate host first, then production only after console rollback is confirmed:

1. Inbound allow TCP `80` from `0.0.0.0/0` and `::/0` for HTTP/ACME/Caddy redirects.
2. Inbound allow TCP `443` from `0.0.0.0/0` and `::/0` for the PWA.
3. Inbound allow TCP `22` only from explicitly approved John/admin source CIDRs or a tailnet/bastion range. If no stable admin CIDR exists, do not apply yet; use a separate John decision to choose SSH access strategy.
4. Deny all other inbound by omission.
5. Keep outbound unrestricted unless a later egress policy is designed and tested.
6. Apply by explicit server ID for the first staged test; do not apply broad labels until clone/production labeling is audited.

## Verification run this tick
- `scripts/security/run-safe-security-gates.sh` passed end-to-end: secret artifact guard, operational redaction over logs plus chat.db, install secret-handling guard, credential preflight/smoke syntax, names-only credential preflight, local service smoke, 8 redaction tests, 32 PWA auth/routing tests, and 1 voice UI test.
- Git status before this artifact was clean and tracking `origin/master`.

## Result
BACKLOG-007 advanced from the original finding to a current read-only firewall readiness inventory and an explicit staged deny-by-default candidate policy. No firewall was created, changed, or applied because applying network policy can lock out access and requires a staged window/approved SSH source strategy.
