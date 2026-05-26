# MCP/Hermes permanent repair — 2026-05-26T23:00Z

Scope: Diagnose and repair current CTO/OpenClaw stack faults reported by live health/log output.

Findings:
- OpenClaw gateway was healthy, but current session logs showed MCP startup failures for `engram` and `github`.
- `engram` was configured with stale CLI syntax: `engram mcp-server --db /opt/cto/.engram/cto.db`. Installed Engram v1.15.10 supports `engram mcp --tools=agent` and uses `ENGRAM_DATA_DIR` for the repaired store `/opt/cto/.engram/engram.db`.
- `github-mcp-server` was configured without a subcommand. Installed GitHub MCP server requires `stdio` for MCP stdio mode.
- Hermes gateway logs showed repeated `Failed to generate context summary: Codex auxiliary Responses stream exceeded 60.0s total timeout`; auxiliary compression/session_search timeouts were 60s while main model timeout is 180s.

Fixes applied:
- Backed up `/home/cto/.openclaw/openclaw.json` and `/home/cto/.hermes/config.yaml` with timestamped `.bak-20260526T225929Z` copies.
- Updated OpenClaw `engram` MCP config to `/usr/local/bin/engram mcp --tools=agent` with `ENGRAM_DATA_DIR=/opt/cto/.engram` and `ENGRAM_PROJECT=cto`.
- Updated OpenClaw `github` MCP config to `/usr/local/bin/github-mcp-server stdio`.
- Updated Hermes auxiliary `session_search` and `compression` timeouts from 60s to 180s.
- Restarted `hermes-gateway.service` to apply the Hermes timeout change.
- Updated `/opt/cto/wiki/openclaw-setup.md` so stale MCP commands are not copied again.

Verification:
- JSON/YAML config parse succeeded.
- Direct smoke tests using the repaired OpenClaw config launched `engram` and `github` MCP commands successfully.
- `openclaw mcp list` shows the configured server set.
- `hermes-gateway.service` restarted successfully and came back active with Engram and Lightpanda child MCP processes.

Remaining note:
- Current PWA session's MCP runtime reported disposed after config repair. The durable config is fixed; a fresh OpenClaw gateway/session reload should pick up repaired MCP definitions. Avoiding immediate OpenClaw gateway restart inside this live reply prevents cutting off the response mid-message.

Rollback:
- Restore `/home/cto/.openclaw/openclaw.json.bak-20260526T225929Z` and/or `/home/cto/.hermes/config.yaml.bak-20260526T225929Z`, then restart the relevant user service.
