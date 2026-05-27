#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET="/etc/ssh/sshd_config.d/99-cto-hardening.conf"
APPLY=0
RELOAD=0
CONFIRM=""
ALLOW_NON_SSH=0

usage() {
  cat <<'USAGE'
Usage: scripts/security/install-ssh-hardening-dropin.sh [--dry-run] [--apply --confirm I_HAVE_ROLLBACK_ACCESS] [--reload] [--target PATH] [--allow-non-ssh]

Installs the CTO SSH hardening drop-in only during an approved rollback window.
Default mode is dry-run: print the proposed sshd_config.d content and perform no writes.

Safety requirements for real /etc/ssh writes:
  - run as root
  - pass --apply --confirm I_HAVE_ROLLBACK_ACCESS
  - run from an active SSH session unless --allow-non-ssh is explicitly passed
  - validate sshd syntax before optional reload
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) APPLY=0; shift ;;
    --apply) APPLY=1; shift ;;
    --reload) RELOAD=1; shift ;;
    --target) TARGET="${2:?missing --target value}"; shift 2 ;;
    --confirm) CONFIRM="${2:?missing --confirm value}"; shift 2 ;;
    --allow-non-ssh) ALLOW_NON_SSH=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

render_config() {
  cat <<'CONFIG'
# CTO SSH hardening baseline.
# Managed by scripts/security/install-ssh-hardening-dropin.sh.
# Apply only with active rollback/console access.
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
X11Forwarding no
MaxAuthTries 4
MaxSessions 4
ClientAliveInterval 300
ClientAliveCountMax 2
CONFIG
}

is_real_etc_target() {
  [[ "$TARGET" == /etc/ssh/sshd_config.d/* ]]
}

if [[ "$APPLY" -ne 1 ]]; then
  echo "DRY RUN: would write ${TARGET} with:"
  render_config
  echo "DRY RUN: no files, services, firewall rules, packages, or infrastructure changed."
  exit 0
fi

if [[ "$CONFIRM" != "I_HAVE_ROLLBACK_ACCESS" ]]; then
  echo "Refusing apply: pass --confirm I_HAVE_ROLLBACK_ACCESS after opening rollback/console access and a second SSH session." >&2
  exit 3
fi

if is_real_etc_target && [[ "${EUID}" -ne 0 ]]; then
  echo "Refusing apply to ${TARGET}: must run as root during the approved hardening window." >&2
  exit 4
fi

if [[ -z "${SSH_TTY:-}" && "$ALLOW_NON_SSH" -ne 1 ]]; then
  echo "Refusing apply: SSH_TTY is empty. Use an active SSH session or pass --allow-non-ssh only when console rollback is confirmed." >&2
  exit 5
fi

mkdir -p "$(dirname "$TARGET")"
if [[ -e "$TARGET" ]]; then
  cp -p "$TARGET" "${TARGET}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
fi
TMP="${TARGET}.tmp.$$"
render_config > "$TMP"
chmod 0644 "$TMP"
mv "$TMP" "$TARGET"

echo "Installed SSH hardening drop-in at ${TARGET}."

if is_real_etc_target; then
  if command -v /usr/sbin/sshd >/dev/null 2>&1; then
    if /usr/sbin/sshd -t; then
      echo "sshd syntax validation passed."
    else
      echo "sshd syntax validation failed; restore backup before closing current session." >&2
      exit 6
    fi
  else
    echo "WARN: /usr/sbin/sshd not found; syntax validation skipped." >&2
  fi
else
  echo "Non-/etc target; sshd syntax validation skipped for test/staging path."
fi

if [[ "$RELOAD" -eq 1 ]]; then
  if command -v systemctl >/dev/null 2>&1; then
    systemctl reload ssh || systemctl reload sshd
    echo "SSH service reload requested. Keep current session open and verify a second login before exiting."
  else
    echo "WARN: systemctl not found; reload skipped." >&2
  fi
else
  echo "Reload skipped. Re-run with --reload during the approved window to activate after validation."
fi
