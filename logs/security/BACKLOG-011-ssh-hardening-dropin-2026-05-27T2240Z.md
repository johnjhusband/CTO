# BACKLOG-011 SSH hardening drop-in installer — 2026-05-27T22:40Z

## Required pre-checks
- A2A2H per-tick upstream-port check ran first from `wiki/A2A2H_LAST_SYNC.md`: no upstream-eligible CTO commits existed after `6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3`; no A2A2H port was required.
- Recent PWA chat was inspected. The latest standing instruction remains: no safe-gate-only ticks; ship substantive work from the highest unblocked item.
- Open/pending backlog scan found no safely closable P0/P1 item from disk evidence alone: credential/history work requires coordinated destructive/rotation windows, PWA visible items remain pending John/device verification, firewall/recovery items need approval/perimeter decisions, and email remains pending provider credentials.
- Hermes provider circuit is degraded/open (`agent_incomplete_provider_NoneType`), so no semantic Hermes delegation was attempted.

## Selected safe item
BACKLOG-011 — complete SSH/fail2ban hardening verification and produce real hardening config artifacts.

Applying SSH hardening live can lock out administration, so this tick did **not** mutate `/etc/ssh`, reload sshd, alter firewall rules, install packages, spend money, or touch infrastructure. The substantive safe step was to ship the guarded installer/config artifact that can be run during an approved rollback window.

## Shipped artifact
- Added `scripts/security/install-ssh-hardening-dropin.sh`.
  - Default mode is dry-run and writes nothing.
  - Real `/etc/ssh/sshd_config.d/99-cto-hardening.conf` writes require root plus `--apply --confirm I_HAVE_ROLLBACK_ACCESS`.
  - Refuses apply unless an active SSH session exists, unless console rollback is explicitly confirmed with `--allow-non-ssh`.
  - Backs up an existing target before replacement.
  - Validates `sshd -t` before optional reload.
  - Baseline: `PasswordAuthentication no`, `KbdInteractiveAuthentication no`, `ChallengeResponseAuthentication no`, `PubkeyAuthentication yes`, `PermitRootLogin no`, `X11Forwarding no`, `MaxAuthTries 4`, plus conservative session/client-alive limits.
- Added `tests/test_install_ssh_hardening_dropin.py`.

## Verification
- `/home/cto/.local/bin/pytest -q tests/test_install_ssh_hardening_dropin.py tests/test_ssh_fail2ban_hardening_check.py` → 8 passed.
- `scripts/security/install-ssh-hardening-dropin.sh --dry-run` printed the proposed config and confirmed no files/services/firewall/packages/infrastructure changed.

## Result
BACKLOG-011 now has both a repeatable verifier and an access-preserving hardening drop-in installer. It remains open until the installer is applied/reloaded in an approved rollback window after BACKLOG-007 confirms safe SSH perimeter/source conditions.
