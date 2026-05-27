# BACKLOG-007 firewall approval packet — 2026-05-27T11:28Z

## Required pre-checks
- A2A2H per-tick upstream-port check ran first: `git log 27abb1203d2a13253e8c1b7e9658518d77794236..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no commits, so no port was required.
- Recent PWA chat was inspected. Latest John-facing message remains the 08:18Z PWA feature-status note; no newer John instruction was present in the durable chat log.
- Open/pending backlog scan found no safe P0 closure from disk evidence: BACKLOG-004/BACKLOG-014 still need phone/device behavior evidence; BACKLOG-005/BACKLOG-006 require coordinated credential/history windows; BACKLOG-015 remains credential-blocked.
- Hermes provider circuit is open via `.cache/hermes-work-pump-provider-failure.json` (`agent_incomplete_provider_NoneType`), so no semantic Hermes delegation was attempted.

## Selected safe item
BACKLOG-007 — add deny-by-default host/cloud firewall policy for CTO servers and clone candidates.

This tick did **not** create, attach, or change any firewall. Applying perimeter rules can lock out SSH or break production, so this artifact advances the item by converting the read-only exposure baseline into an approval-ready change packet.

## Current evidence
- Hetzner cloud firewalls: `0`.
- Servers with public networking and no attached cloud firewall:
  - `cto-v1` (`130627001`), labels `purpose=cto, version=v1`, public IPv4/IPv6 present.
  - `recrm` (`128886775`), no labels, public IPv4/IPv6 present.
- Public listeners observed on `cto-v1`: SSH `22`, HTTP `80`, HTTPS `443`.
- CTO internals remain loopback-only: OpenClaw `18789/18791`, PWA backend `8088`, Hermes `8642/8643`, A2A registry `9000`, Caddy admin `2019`.
- `ufw`, `nft`, and `iptables` were not available to this user, so host-firewall posture is not enforceable from the current OpenClaw runtime.

## Recommended staged Hetzner policy
Create one cloud firewall, but attach it only after John confirms an SSH source/rollback window.

Proposed firewall name: `cto-deny-default-public-edge`

Inbound allow rules:
1. TCP `80` from `0.0.0.0/0` and `::/0` — public HTTP for ACME/redirects.
2. TCP `443` from `0.0.0.0/0` and `::/0` — public HTTPS for `cto.husband.llc`.
3. TCP `22` only from John/admin CIDR(s) or a confirmed tailnet/bastion egress range — **placeholder pending John confirmation**.

Implicit/default behavior: deny all other inbound traffic. No outbound restrictions in the first stage.

## Approval boundary
Do not apply until John confirms one of:
- exact admin source CIDR(s) for SSH, or
- a working tailnet/bastion path to use for SSH, or
- an approved maintenance window with console/noVNC rollback ready.

## Staged execution plan after approval
1. Create firewall with the three allow classes above.
2. Attach to a non-production/candidate server first, if one is safe to test.
3. Verify SSH from the approved source and HTTP/HTTPS from public internet.
4. Attach to `cto-v1` only with an active SSH session plus Hetzner console rollback path ready.
5. Confirm internal services remain loopback-only and public web still returns expected auth-gated responses.

## Rollback plan
- Remove the firewall from affected server(s), or loosen the SSH rule to the approved emergency source CIDR.
- Use Hetzner console/noVNC if SSH is lost.
- Do not delete the firewall until after a successful rollback verification, so the rule set remains inspectable.

## Result
BACKLOG-007 is now ready for an explicit approval/maintenance-window decision. No infrastructure was changed and no new external risk was created.
