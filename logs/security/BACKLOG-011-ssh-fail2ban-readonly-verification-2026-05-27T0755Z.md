# BACKLOG-011 SSH/fail2ban read-only verification — 2026-05-27T07:55Z

## Required pre-checks
- A2A2H per-tick drift check: no upstream-eligible CTO commits since `27abb1203d2a13253e8c1b7e9658518d77794236`; no port required. `/opt/a2a2h` was clean at `abe5e3a`.
- Recent PWA chat: latest human-visible item was the 06:15Z daily digest; Hermes work-pump degraded events continued afterward.
- Hermes provider circuit: open at 7 consecutive provider-side `agent_incomplete_provider_NoneType` failures, so no Hermes semantic delegation was attempted.
- Backlog completion scan: P0 credential/history work remains coordinated-window blocked; P0 PWA voice/background/audit items remain pending John/device evidence; no open or pending item was safely closable from disk evidence.

## Scope
Selected BACKLOG-011 (`Complete privileged SSH/fail2ban hardening verification`) as the highest safe item after blocked P0/P1 items. This tick was read-only: no SSH, firewall, service, package, credential, or infrastructure settings were changed.

## Read-only findings
- Host: Ubuntu 24.04.4 LTS on `cto-v1`, public IPv4 `46.224.81.84`.
- Current user: unprivileged `cto` (`uid=1000`); privileged checks that require root were not forced.
- SSH service: `ssh.service` active and socket-triggered; TCP 22 listens on both `0.0.0.0:22` and `[::]:22`.
- SSH config visible to the unprivileged user contains only base defaults plus `KbdInteractiveAuthentication no`, `UsePAM yes`, `X11Forwarding yes`, `PrintMotd no`, and `AcceptEnv LANG LC_*`.
- Effective SSH config could not be fully verified without root because `sshd -T` as `cto` exits with `sshd: no hostkeys available -- exiting` even though host keys exist and are root-readable only.
- Fail2ban service: active, but jail status requires root; unprivileged `fail2ban-client status` returns `Permission denied to socket: /var/run/fail2ban/fail2ban.sock`.
- Firewall tool state: `ufw` is not installed; host-level nft output was not visible from this unprivileged read-only pass. Earlier cloud-firewall audit already found no Hetzner cloud firewall attached to `cto-v1`.
- Automatic security updates: `unattended-upgrades` is enabled and active.
- Pending apt upgrades include `vim`/`vim-runtime`/`vim-common`/`vim-tiny`/`xxd` security/update packages and `snapd`.
- OpenClaw security audit: `0 critical · 1 warn · 1 info`; warning is `gateway.trusted_proxies_missing` for reverse-proxy local-client checks if the Control UI is ever exposed through a reverse proxy. Gateway itself is loopback-bound.
- OpenClaw update status: stable channel has npm update `2026.5.22` available; not applied because this tick selected SSH/fail2ban verification and updates are a separate BACKLOG-012 track.

## Gaps vs VPS-hardened posture
1. Public SSH remains reachable from the internet and is not yet constrained by a confirmed host/cloud firewall strategy.
2. Key SSH hardening assertions (`PasswordAuthentication`, `PermitRootLogin`, `MaxAuthTries`, `AllowUsers`/`AllowGroups`) are not conclusively verified from the unprivileged account.
3. Fail2ban is active, but the sshd jail status, ban counters, and backend health still need a privileged read-only check.
4. OS security updates are available and should be handled through the BACKLOG-012 patch/update track.

## Safe next privileged verification command
When John approves a privileged read-only check, run:

```bash
sudo /usr/sbin/sshd -T | egrep '^(passwordauthentication|permitrootlogin|pubkeyauthentication|kbdinteractiveauthentication|challengeresponseauthentication|maxauthtries|x11forwarding|allowusers|allowgroups|authenticationmethods|port) '
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

## Result
BACKLOG-011 advanced from an unstarted item to a concrete read-only baseline with explicit privileged verification gaps. No remote-access settings were changed, avoiding lockout risk.
