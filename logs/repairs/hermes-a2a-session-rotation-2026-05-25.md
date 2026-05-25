# Hermes A2A session-rotation repair — 2026-05-25

Problem: Hermes was alive at the process/API level but timed out on delegated A2A work, making the right hemisphere broken for its actual job.

Evidence:
- `hermes-gateway.service`, `cto-hermes-a2a-sidecar.service`, and PWA backend were active.
- Hermes `/v1/models` responded.
- A2A delegation timed out.
- Hermes logs repeatedly showed: `Failed to generate context summary: Codex auxiliary Responses stream exceeded 60.0s total timeout`.
- `/home/cto/.hermes/sessions/session_a2a-openclaw-hermes-main.json` had grown to ~1.29 MB / 415 messages.
- A fresh direct Hermes API session returned `OK`.

Repair:
- Added `/home/cto/.config/systemd/user/cto-hermes-a2a-sidecar.service.d/30-session-rotate.conf` with fresh human and agent session IDs/keys.
- Restarted only `cto-hermes-a2a-sidecar.service`.
- Verified sidecar health.
- Verified A2A delegation returned `OK` with session `a2a-openclaw-hermes-20260525-repair1`.

Follow-up:
- Add durable session hygiene/rotation so long-lived Hermes API sessions cannot silently grow into compression-timeout failure again.
- Health checks must include an actual delegated work ping, not only process/HTTP checks.
