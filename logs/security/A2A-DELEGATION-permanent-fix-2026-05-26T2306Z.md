# A2A delegation permanent repair — 2026-05-26T23:06Z

Scope: Continue repair after MCP command fixes. The OpenClaw → Hermes `a2a-delegate` path still timed out.

Findings:
- OpenClaw/Hermes services were active after the earlier reload.
- The previous MCP command failures for OpenClaw `engram` and `github` stopped after config reload.
- A2A delegation still timed out.
- Direct sidecar test initially returned HTTP 502. Hermes logs showed Codex rejected an overlong `prompt_cache_key` (>64 chars).
- Root cause: the sidecar attempted to isolate agent delegations by appending the task UUID to the existing persistent Hermes A2A session id/key. That fixed context growth conceptually, but produced cache/session identifiers above the Codex limit.
- Deeper root cause: agent-to-agent delegations were previously all sharing one persistent Hermes API session (`a2a-openclaw-hermes-20260525-repair1`), causing transcript growth to ~250k tokens and repeated Hermes compression/summary timeouts even for small health checks.

Fixes applied:
- Patched `/opt/cto/services/hermes_a2a_sidecar/server.py` so non-human OpenClaw→Hermes delegations use compact per-task session identity:
  - session id: `a2a-<uuid-without-hyphens>`
  - session key: `a2a:<uuid-without-hyphens>`
- This keeps task isolation while staying below Codex's 64-character prompt-cache identifier limit.
- Kept human-addressed Hermes PWA sessions persistent; only agent delegation sessions are isolated.
- Added `DELEGATE_TIMEOUT_S=600` to OpenClaw's `a2a-delegate` MCP environment so the client-side delegate timeout matches the sidecar's 600s Hermes timeout.
- Restarted `cto-hermes-a2a-sidecar.service` and `openclaw-gateway.service` to apply code/config.

Verification:
- `python3 -m py_compile /opt/cto/services/hermes_a2a_sidecar/server.py` passed.
- Direct HTTP POST to `127.0.0.1:8643/a2a/` returned status `ok` with session id `a2a-...`.
- OpenClaw MCP tool `a2a-delegate__a2a_delegate` returned status `ok` through the full OpenClaw → MCP → sidecar → Hermes path.
- Services active after final reload: `openclaw-gateway.service`, `hermes-gateway.service`, `cto-hermes-a2a-sidecar.service`.

Rollback:
- Revert `/opt/cto/services/hermes_a2a_sidecar/server.py` to the previous version from git/backup if needed.
- Restore `/home/cto/.openclaw/openclaw.json.bak-a2a-timeout-20260526T230326Z` if the delegate timeout env must be removed, then restart OpenClaw gateway.

Operational note:
- OpenClaw update remains available but was not applied because self-update requires John's explicit request.
