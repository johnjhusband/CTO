# Engram — SQLite Memory for CTO
**L0:** Go binary, zero deps, MCP-native, 17 tools, FTS5 keyword search. No API keys. Install: download binary + add MCP config. Stores agent-learned memories (does NOT index files — MCPVault does that).
**L1:** Engram is a persistent memory system for AI agents. Single Go binary, zero runtime dependencies, MCP stdio server with 17 tools. FTS5 keyword search (not semantic/vector). Agent calls mem_save to store observations, mem_search to retrieve. SQLite at ~/.engram/engram.db. Does NOT crawl files from disk — complements MCPVault (file search) rather than replacing it. v1.14.1, 2.9K stars, MIT license, 5 releases in last 3 days. [All verified against GitHub repo and docs.]
**Last updated:** 2026-04-27
**Verification:** All claims verified against github.com/Gentleman-Programming/engram, docs, and releases page.

## Installation on VPS (Ubuntu 24.04)

```bash
# Download latest binary [verified — linux_amd64 binary exists in releases]
curl -sL https://github.com/Gentleman-Programming/engram/releases/latest/download/engram_linux_amd64.tar.gz -o /tmp/engram.tar.gz
# Note: filename may include version (e.g., engram_1.14.1_linux_amd64.tar.gz) — check releases page
tar -xzf /tmp/engram.tar.gz -C /tmp/
sudo mv /tmp/engram /usr/local/bin/
engram version
```

## Prerequisites
- **NONE** for prebuilt binary [verified — pure Go, embedded SQLite, no CGO]
- No Node.js, no Python, no Docker, no API keys
- Go 1.24+ only needed if building from source

## MCP Configuration for OpenClaw

Add to OpenClaw's `~/.openclaw/openclaw.json` under `mcp.servers` [verified config key]:

```json
{
  "mcp": {
    "servers": {
      "engram": {
        "command": "engram",
        "args": ["mcp"]
      }
    }
  }
}
```

## What Engram Does (17 MCP Tools) [verified against docs]

**Save:** mem_save, mem_update, mem_delete, mem_suggest_topic_key
**Search:** mem_search (FTS5), mem_context, mem_timeline, mem_get_observation
**Sessions:** mem_session_start, mem_session_end, mem_session_summary
**Conflict:** mem_judge (detect contradictory memories)
**Utilities:** mem_save_prompt, mem_stats, mem_capture_passive, mem_merge_projects, mem_current_project

## What Engram Does NOT Do
- Does NOT index files from disk (MCPVault does that)
- Does NOT do semantic/vector search (FTS5 keyword only)
- Does NOT have temporal decay (recent memories don't automatically rank higher)
- Does NOT export to Obsidian format automatically (there's an obsidian-export command but it exports OUT, doesn't import IN)

## How It Complements MCPVault

| Need | Tool |
|------|------|
| Search wiki files by content | MCPVault [verified working] |
| Store agent-learned memories | engram (mem_save) |
| Retrieve agent memories by keyword | engram (mem_search) |
| Read/write wiki pages | MCPVault (read_note, write_note) |
| Detect contradictory memories | engram (mem_judge) |
| Session continuity | engram (mem_context after compaction) |

## Storage
- Database: `~/.engram/engram.db` [verified]
- Override: `ENGRAM_DATA_DIR` environment variable
- WAL mode, 5000ms busy timeout [verified]
- FTS5 indexes: title, content, tool_name, type, project, topic_key

## Known Limitations [verified against GitHub issues]
1. FTS5 is keyword-only — different words for same concept won't match
2. Ambiguous project detection if CWD is parent of multiple git repos (#248)
3. Agent must be instructed to call mem_save — no automatic capture
4. If SQLite corrupts, data is gone (unless cloud sync)
5. 85 open issues (mostly feature requests, not bugs)

## Sources
- [GitHub](https://github.com/Gentleman-Programming/engram)
- [Installation Docs](https://github.com/Gentleman-Programming/engram/blob/main/docs/INSTALLATION.md)
- [Agent Setup](https://github.com/Gentleman-Programming/engram/blob/main/docs/AGENT-SETUP.md)
- [Technical Reference](https://github.com/Gentleman-Programming/engram/blob/main/DOCS.md)
- [Releases](https://github.com/Gentleman-Programming/engram/releases)
