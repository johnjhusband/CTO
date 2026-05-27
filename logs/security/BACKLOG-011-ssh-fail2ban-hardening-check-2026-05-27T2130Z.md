# BACKLOG-011 SSH/fail2ban hardening verifier — 2026-05-27T21:30Z

## Required pre-checks
- A2A2H per-tick upstream-port check ran first from `wiki/A2A2H_LAST_SYNC.md`: no upstream-eligible CTO commits existed after `6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3`; no A2A2H port was required.
- Recent PWA chat was inspected. John explicitly asked to stop safe-gate-only loops and ship a substantive artifact per tick.
- Open/pending backlog scan found no safe P0/P1 closure from disk evidence: BACKLOG-004/014/016/017 still carry John/device visible-verification commitments, BACKLOG-005/006 require coordinated credential/history windows, BACKLOG-007/010 require approval before infrastructure changes, and BACKLOG-015 remains pending a provider API key.
- Hermes provider circuit is degraded/open (`agent_incomplete_provider_NoneType`), so this tick did not delegate semantic work to Hermes.

## Selected safe item
BACKLOG-011 — complete privileged SSH/fail2ban hardening verification.

This tick did not mutate SSH, firewall, packages, services, credentials, or infrastructure. Because applying SSH hardening can lock out administration and BACKLOG-007 has not yet confirmed a safe SSH source/perimeter, the safe substantive step was to add a reusable verifier that can run now unprivileged and later under sudo during an approved rollback window.

## Shipped artifact
- Added `scripts/security/ssh-fail2ban-hardening-check.py`.
  - Prefers effective `sshd -T` when available.
  - Falls back to readable `/etc/ssh/sshd_config*` snippets without claiming effective state.
  - Checks key-only/root-login/X11/max-auth-trial posture and fail2ban sshd status when permitted.
  - Emits bounded sanitized JSON with `production_mutated_by_this_check=false`, `spend_or_infrastructure_change=false`, and `secret_values_printed=false`.
- Added regression coverage in `tests/test_ssh_fail2ban_hardening_check.py`.
- Wrote latest local verifier output to `logs/security/ssh-fail2ban-hardening-check-latest.json`.

## Verification
- `python3 -m pytest -q tests/test_ssh_fail2ban_hardening_check.py` → 4 passed.
- Live unprivileged verifier run completed without mutation and reported `status=hardening_required` from visible config evidence:
  - `X11Forwarding yes` is visible and does not meet the desired hardening baseline.
  - effective `sshd -T` still requires privileged host-key access (`sshd: no hostkeys available -- exiting`).
  - fail2ban status still requires root (`Permission denied to socket`).

## Result
BACKLOG-011 is now advanced from a one-off read-only note to a repeatable, test-covered, non-mutating verifier. The next safe step is an approved privileged run of the same checker and then an access-preserving sshd drop-in only after SSH rollback/perimeter conditions are confirmed.
