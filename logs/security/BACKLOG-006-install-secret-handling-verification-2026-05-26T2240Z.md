# BACKLOG-006 install secret-handling verification — 2026-05-26T22:40Z

Scope: Continuous OpenClaw work pump selected BACKLOG-006 because P0 security/credential hygiene outranks lower-priority clone and documentation work. Full live credential rotation and public history cleanup remain coordinated approval-window work; this tick advanced the safe no-spend install-secret-handling path.

Context inspected:
- Continuous work policy, HEARTBEAT.md, BACKLOG.md, FAILURE.md.
- Git status showed uncommitted `scripts/install.sh` changes that remove Hetzner bearer tokens from curl command arguments by routing Hetzner API calls through a small Python helper using process environment only.
- User service health showed no failed user units; A2A registry, Hermes A2A sidecar, and PWA backend were active.
- Recent verification logs showed BACKLOG-006 safe gates passing, but `scripts/validate-no-spend.sh` had drifted behind the install script's current candidate namespace variable names.

Repair performed:
- Updated `scripts/validate-no-spend.sh` so clone-readiness checks validate the current `CTO_INSTANCE_ID` candidate namespace and quoted candidate `CHAT_DB` assignment used by `scripts/install.sh`.
- Left the existing `scripts/install.sh` secret-handling repair intact: Hetzner API calls no longer put `Authorization: Bearer ...` in shell command arguments, candidate `.env` content is streamed over SSH without local disk persistence, and git clone uses a short-lived `GIT_ASKPASS` helper rather than embedding the GitHub token in clone URLs or persisted remotes.

Verification result:
- `bash scripts/validate-no-spend.sh` passed.
- `scripts/security/run-safe-security-gates.sh` passed.
  - Secret artifact guard scanned 258 source-visible files.
  - Operational redaction check scanned 125 files plus chat.db.
  - Redaction unit tests passed: 6 tests.
  - PWA auth/routing regression tests passed: 26 tests.

Result: BACKLOG-006 remains open for coordinated live credential rotation and history cleanup, but the no-spend clone/install verification gate now matches the current secret-handling implementation and passes. No secret values were recorded in this artifact.
