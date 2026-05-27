# BACKLOG-007 read-only firewall/exposure snapshot — 2026-05-27T11:10Z

## Required pre-checks
- A2A2H per-tick upstream-port check ran first from `wiki/A2A2H_LAST_SYNC.md`: no upstream-eligible CTO commits existed after `27abb1203d2a13253e8c1b7e9658518d77794236`, so no A2A2H port was required.
- Hermes provider circuit is open (`agent_incomplete_provider_NoneType`), so no semantic Hermes delegation was attempted.
- Recent PWA chat was inspected; latest John-facing status remains the 08:18Z PWA feature status note.
- Open/pending backlog scan found no safe closure from disk evidence: BACKLOG-004 and BACKLOG-014 still need John/device behavior evidence; BACKLOG-005 and BACKLOG-006 require coordinated credential/history windows; BACKLOG-015 remains credential-blocked.

## Selected item
BACKLOG-007 — add deny-by-default host/cloud firewall policy for CTO servers and clone candidates.

This tick stayed read-only. No firewall rules, cloud resources, SSH settings, packages, services, or access paths were changed.

## Verification result
- Host: Ubuntu 24.04.4 LTS on `cto-v1`.
- OpenClaw security audit: 0 critical, 1 warning (`gateway.trusted_proxies_missing` for possible reverse-proxy header trust), 1 informational attack-surface summary.
- OpenClaw update status: stable channel, update available (`npm update 2026.5.22`); not applied in this unattended security tick.
- Local listener posture: public TCP listeners are SSH `22` and Caddy/public web `80`/`443`; OpenClaw gateway `18789`, browser/debug `18791`, PWA backend `8088`, Hermes gateway `8642`, Hermes A2A sidecar `8643`, A2A registry `9000`, and Caddy admin `2019` are loopback-only.
- Host firewall tooling: `ufw` and `nft` commands are not installed/available, so no host-level deny-by-default policy is currently observable from this account.
- Automatic security updates: `unattended-upgrades` is enabled and active.
- Hetzner Cloud firewall inventory: no firewalls exist in the project.
- Hetzner server attachment check: both visible servers (`cto-v1` and `recrm`) have no attached Hetzner firewalls. `cto-v1` has public IPv4/IPv6 addresses and no backup window/delete protection observed in the same read-only server listing; those remain relevant to BACKLOG-010, not changed here.

## Result
BACKLOG-007 has a current read-only exposure baseline: CTO is relying on service bind addresses and Caddy/app auth rather than a host/cloud deny-by-default firewall. The safe next step is a staged firewall plan for John approval, preserving SSH plus public 80/443 and keeping all OpenClaw/Hermes/PWA internals loopback-only. Do not apply firewall changes unattended because a mistake could lock out the server.
