# BACKLOG-006 — install config permissions hardening

Timestamp: 2026-05-26T22:53Z

## Selected item
P0 credential hygiene / BACKLOG-006.

## Why selected
Full live credential rotation remains unsafe in an unattended work-pump tick. The safe highest-priority substep was to harden installer-created local config files and systemd drop-ins that carry runtime credentials or auth settings, so a fresh clone does not create secret-bearing files with default world/group-readable permissions.

## Repair
- `scripts/install-cto.sh` now sets `~/.openclaw` to `0700` before writing `openclaw.json`.
- `~/.openclaw/openclaw.json` is explicitly set to `0600` after generation.
- Hermes gateway, Hermes sidecar, and PWA backend user-systemd drop-in directories are explicitly set to `0700`.
- Generated user-systemd drop-ins from this installer section are explicitly set to `0600` after writing.

## Verification
Completed in this tick:
- `bash -n scripts/install-cto.sh` passed.
- `scripts/security/run-safe-security-gates.sh` passed: secret artifact guard scanned 261 source-visible files; operational redaction check scanned 128 files plus chat.db; 6/6 redaction tests passed; 26/26 PWA auth/routing tests passed.
- `bash scripts/validate-no-spend.sh` passed; TypeScript builds were skipped because dependency directories are absent in this runtime.
- Git clean/divergence verification will be recorded after commit and push.

## Remaining
BACKLOG-006 remains open for coordinated live credential rotation, public/log history cleanup, and any additional installer/runtime secret-handling hardening discovered by later audits.
