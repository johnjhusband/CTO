# OpenClaw Installation & Configuration
**L0:** Install via npm, onboard via CLI (non-interactive mode over SSH), skip bootstrap to keep our files, workspace at /opt/cto, wiki indexed via extraPaths.
**L1:** `npm install -g openclaw@latest` then `openclaw onboard --non-interactive` with flags for provider, API key, gateway bind/port/auth, daemon install. Skip bootstrap (--skip-bootstrap) to prevent overwriting our SOUL.md/AGENTS.md. Point workspace at /opt/cto. Wiki indexed for semantic search via memorySearch.extraPaths. Skills lazy-loaded from workspace/skills/. OpenClaw auto-loads SOUL.md, AGENTS.md, IDENTITY.md, USER.md, MEMORY.md into system prompt every session.
**Last updated:** 2026-04-26
**Source:** Verified research on OpenClaw onboard wizard and workspace mechanics

## Installation

```bash
# Node.js 22 already on VPS
npm install -g openclaw@latest
```

## Onboard (Non-Interactive for SSH)

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice custom-api-key \
  --gateway-port 18789 \
  --gateway-bind loopback \
  --install-daemon \
  --daemon-runtime node \
  --skip-bootstrap \
  --workspace /opt/cto
```

Note: `--skip-bootstrap` is critical — prevents OpenClaw from generating its own SOUL.md, AGENTS.md, etc. that would overwrite ours.

Provider setup for OpenRouter requires "Custom" provider (OpenAI-compatible endpoint) with base URL, model ID, and API key.

## The 10 Onboard Steps (Interactive Mode Reference)

1. **Name your assistant** — "CTO"
2. **Select AI provider** — Custom Provider (OpenAI-compatible) for OpenRouter
3. **Authenticate** — OpenRouter API key
4. **Choose default model** — via OpenRouter model ID
5. **Web search provider** — configure for research capability
6. **Gateway config** — port 18789, bind loopback, token auth
7. **Channels** — skip during onboard, configure Telegram after
8. **Daemon installation** — systemd user unit on Linux
9. **Workspace bootstrap** — SKIP (we have our own files)
10. **Health check** — verify gateway reachable

## Non-Interactive Onboard with OpenRouter (Verified)

**Known bug ([Issue #17191](https://github.com/openclaw/openclaw/issues/17191)):** `--token-provider openrouter` is ignored when using `--auth-choice apiKey`. Use the pre-remapped auth choice instead:

```bash
# Step 1: Onboard with workaround for auth bug
openclaw onboard --non-interactive \
  --install-daemon \
  --auth-choice "openrouter-api-key" \
  --openrouter-api-key "$OPENROUTER_API_KEY" \
  --workspace /opt/cto \
  --skip-bootstrap \
  --skip-health \
  --gateway-bind loopback \
  --gateway-auth token

# Step 2: Set model explicitly (onboard bug #33290 may not set it)
openclaw models set "openrouter/anthropic/claude-sonnet-4-6"

# Step 3: Verify
openclaw doctor
```

**Alternative: Skip onboard entirely, write config manually:**
OpenClaw reads `~/.openclaw/openclaw.json`. Write it by hand, set API key via `openclaw models auth paste-token --provider openrouter`, then start gateway with `openclaw gateway run` or install daemon separately.

**Warning:** OpenClaw enforces strict schema validation. Unknown keys cause gateway to refuse to start. Run `openclaw doctor` to validate.

## Post-Onboard Verification

```bash
openclaw status
openclaw gateway status
openclaw doctor
openclaw security audit
```

## Security Hardening (Immediately After Onboard)

Edit `~/.openclaw/openclaw.json`:

```json5
{
  gateway: {
    bind: "loopback",
    auth: { mode: "token" },
    port: 18789
  },
  skills: {
    autoInstall: false
  }
}
```

Generate gateway token: `openclaw doctor --generate-gateway-token`

## How OpenClaw Consumes Our Files

### Auto-Loaded Every Session (System Prompt)

| File | Purpose | Notes |
|------|---------|-------|
| **SOUL.md** | Personality, values, boundaries | Loaded FIRST. Our research methodology lives here. |
| **AGENTS.md** | Operating instructions, rules, SOPs | Our safety rules and project context. |
| **IDENTITY.md** | Agent name, vibe | We need to create this — not in our repo yet. |
| **USER.md** | Who the user is | We need to create this — not in our repo yet. |
| **TOOLS.md** | Notes about local tools/conventions | We need to create this — not in our repo yet. |
| **MEMORY.md** | Curated long-term memory | ~100 lines max recommended. We need to create this. |
| **HEARTBEAT.md** | Scheduled tasks in plain English | Read every 30 minutes. We need to create this. |

### Missing Files We Need to Create
- **IDENTITY.md** — agent name, persona
- **USER.md** — who John is, how to communicate with him
- **TOOLS.md** — local tools and conventions
- **MEMORY.md** — curated top-level memory (~100 lines)
- **HEARTBEAT.md** — daily research schedule in plain English

### Memory Tiers

| Tier | What | How Loaded |
|------|------|------------|
| **Tier 1** | MEMORY.md | Always loaded (~100 lines) |
| **Tier 2** | `memory/YYYY-MM-DD.md` daily files | Today + yesterday auto-loaded |
| **Tier 3** | `memory/topics/`, `memory/projects/`, wiki/ | Semantic search, loaded on demand |

### Connecting Our Wiki to OpenClaw

Add to `~/.openclaw/openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "extraPaths": ["/opt/cto/wiki"]
      }
    }
  }
}
```

Wiki pages are indexed for semantic/hybrid search and retrieved when relevant — NOT loaded into every session (saves tokens). The L0/L1 headers on each wiki page help the search engine surface the right pages.

### How Skills Load

Skills in `workspace/skills/` are lazy-loaded:
- System prompt lists available skills with file paths
- Model reads SKILL.md on demand when needed
- Not loaded into every session (saves tokens)

Precedence order:
1. `<workspace>/skills` (highest — our custom skills)
2. Bundled skills (53 built-in)
3. `skills.load.extraDirs` in config (lowest)

### Important: Rules Are Advisory

SOUL.md, AGENTS.md, GUARDRAILS.md rules are followed because the LLM is asked to follow them — NOT enforced by the system. For hard constraints, use tool policy or sandboxing. Treat `~/.openclaw/` like a password vault.

## Telegram Configuration

### Create the Bot
1. Open Telegram, search for @BotFather (blue checkmark)
2. Send `/newbot`
3. Choose display name (e.g., "CTO Agent")
4. Choose username ending in `bot` (e.g., `cto_agent_bot`)
5. Copy the bot token (format: `123456789:ABCdefGHI...`)

### Find Your Numeric User ID
- Message @userinfobot on Telegram, send `/start`, record the numeric ID

### openclaw.json Config
```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "YOUR_BOT_TOKEN",
      "dmPolicy": "allowlist",
      "allowFrom": [YOUR_NUMERIC_USER_ID],
      "textChunkLimit": 4000,
      "chunkMode": "newline",
      "linkPreview": false
    }
  }
}
```

Bot token can also be set via `TELEGRAM_BOT_TOKEN` environment variable.

### Proactive Messages (CTO sending to John)
```bash
openclaw message send --channel telegram --target YOUR_NUMERIC_ID --message "Daily digest..."
```
**Known bug:** First message must come FROM user TO bot before bot can send proactively. John needs to message the bot once after setup.

## OpenRouter Configuration

OpenRouter is a **bundled provider** in OpenClaw — no custom provider entry needed.

### openclaw.json Config
```json
{
  "env": {
    "OPENROUTER_API_KEY": "sk-or-v1-..."
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/anthropic/claude-sonnet-4",
        "fallbacks": ["openrouter/google/gemini-2.0-flash"]
      },
      "thinkingDefault": "adaptive",
      "heartbeat": {
        "every": "30m",
        "model": "openrouter/google/gemini-2.5-flash",
        "lightContext": true,
        "isolatedSession": true
      }
    }
  }
}
```

Model ID format: `openrouter/<provider>/<model>`. Examples:
- `openrouter/anthropic/claude-sonnet-4` (primary work)
- `openrouter/google/gemini-2.5-flash` (cheap heartbeats)
- `openrouter/google/gemini-2.0-flash` (fallback)
- `openrouter/openai/gpt-4.1` (alternative)
- `openrouter/auto` (OpenRouter picks best model)

Fallbacks escalate in order with exponential backoff (1 min, 5 min, 25 min, cap 1 hour).

Heartbeat uses cheap model with `lightContext: true` (only HEARTBEAT.md loaded) and `isolatedSession: true` (fresh context each time).

**On-the-fly model switching** (no restart): `/model openrouter/anthropic/claude-opus-4-6`

### OpenRouter Base URL
`https://openrouter.ai/api/v1` (OpenAI-compatible)

## MCP Server Configuration

MCP servers go under `mcpServers` in openclaw.json.

### Config Syntax (stdio transport)
```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@package/name", "optional-arg"],
      "env": {
        "API_KEY": "${ENV_VAR_NAME}"
      }
    }
  }
}
```

### CLI Management
```bash
openclaw mcp list                    # List configured servers
openclaw mcp set name '{"command":"npx","args":[...]}'  # Add/update
openclaw mcp test name               # Test a server
openclaw mcp restart name            # Restart
openclaw logs --mcp --server name    # View logs
```

### MCP Servers for CTO

**IMPORTANT: Several commonly referenced packages are deprecated or don't exist. Verified correct packages below.**

```json
{
  "mcpServers": {
    "vault": {
      "command": "npx",
      "args": ["-y", "@bitbonsai/mcpvault@latest", "/opt/cto/wiki"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/opt/cto"]
    },
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@brave/brave-search-mcp-server"],
      "env": {
        "BRAVE_API_KEY": "${BRAVE_API_KEY}"
      }
    },
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    },
    "hetzner": {
      "command": "npx",
      "args": ["-y", "@lazyants/hetzner-mcp-server"],
      "env": {
        "HETZNER_API_TOKEN": "${HETZNER_API_TOKEN}"
      }
    }
  }
}
```

**NOTE on GitHub MCP:** The official server is now a Go binary (`github/github-mcp-server`), not an npm package. Install separately:
```bash
# Download from GitHub releases
curl -sSL https://github.com/github/github-mcp-server/releases/latest/download/github-mcp-server-linux-amd64 -o /usr/local/bin/github-mcp-server
chmod +x /usr/local/bin/github-mcp-server
```
Then in openclaw.json:
```json
"github": {
  "command": "/usr/local/bin/github-mcp-server",
  "args": [],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
  }
}
```
PAT scopes needed: minimum `repo` (private) or `public_repo` (public only).

Key servers:
| Server | Package | Auth | Notes |
|--------|---------|------|-------|
| **vault** | `@bitbonsai/mcpvault` (npm) | None | 15 tools, Obsidian-compatible |
| **filesystem** | `@modelcontextprotocol/server-filesystem` (npm) | None | Verified v2026.1.14 |
| **brave-search** | `@brave/brave-search-mcp-server` (npm) | Brave API key | $5/mo free credit, 1 req/sec |
| **fetch** | `mcp-server-fetch` (PyPI, via uvx) | None | Needs Python. No API key. |
| **hetzner** | `@lazyants/hetzner-mcp-server` (npm) | Hetzner API token | 104 tools across 13 domains |
| **github** | `github-mcp-server` (Go binary) | GitHub PAT | Not npm — download binary |

## Hetzner Cloud API (for Upgrade Cycle)

### Getting a Token
1. Log in at console.hetzner.cloud
2. Select project → Security → API Tokens → Generate (Read & Write)
3. Copy immediately — not shown again

### API Base URL
`https://api.hetzner.cloud/v1` with `Authorization: Bearer $TOKEN`

### Key Operations
```bash
# Install hcloud CLI
curl -sSLO https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz
sudo tar -C /usr/local/bin --no-same-owner -xzf hcloud-linux-amd64.tar.gz hcloud

# Authenticate
hcloud context create cto-project  # paste token when prompted

# Create test VPS
hcloud server create --name cto-test --type cx23 --image ubuntu-24.04 \
  --location nbg1 --ssh-key cto-agent-key --label purpose=upgrade-test

# Snapshot before promotion
hcloud server create-image --type snapshot --description "pre-upgrade-$(date +%Y%m%d)" SERVER_ID

# Delete test VPS (stops billing)
hcloud server delete SERVER_ID

# List snapshots
hcloud image list --type snapshot
```

### Cost per Upgrade Test Cycle
- CX23 for 4 hours: EUR 0.026
- IPv4: EUR 0.003
- 40GB snapshot for 1 day: EUR 0.019
- **Total: ~EUR 0.05**

Billing stops on DELETE, not power-off.

## SQLite Coordination Layer (memweave)

### Install
```bash
pip install memweave
```

### How It Works
Markdown files are source of truth. SQLite is a derived, rebuildable index. Losing the database is not data loss. Losing the files IS.

### Usage
```python
import asyncio
from pathlib import Path
from memweave import MemWeave, MemoryConfig

async def main():
    async with MemWeave(MemoryConfig(workspace_dir="/opt/cto")) as mem:
        await mem.add(Path("wiki/architecture.md"))
        results = await mem.search("memory architecture", min_score=0.0)
        for r in results:
            print(f"[{r.score:.2f}] {r.snippet}")

asyncio.run(main())
```

### Hybrid Search Scoring
`merged_score = 0.7 * vector_score + 0.3 * bm25_score` (tunable)

### SQLite Tables Created
| Table | Purpose |
|-------|---------|
| `chunks` | Text content + metadata |
| `chunks_fts` | FTS5 for BM25 keyword search |
| `chunks_vec` | sqlite-vec for cosine similarity |
| `embedding_cache` | SHA-256 hash → embedding (compute once) |
| `files` | File hashes for incremental change detection |

## Complete openclaw.json Reference

```json
{
  "env": {
    "OPENROUTER_API_KEY": "sk-or-v1-...",
    "GITHUB_TOKEN": "ghp_...",
    "BRAVE_API_KEY": "BSA...",
    "HETZNER_API_TOKEN": "..."
  },
  "gateway": {
    "bind": "loopback",
    "auth": { "mode": "token" },
    "port": 18789
  },
  "skills": {
    "autoInstall": false
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "...",
      "dmPolicy": "allowlist",
      "allowFrom": [JOHN_TELEGRAM_ID]
    }
  },
  "agents": {
    "defaults": {
      "workspace": "/opt/cto",
      "model": {
        "primary": "openrouter/anthropic/claude-sonnet-4",
        "fallbacks": ["openrouter/google/gemini-2.0-flash"]
      },
      "thinkingDefault": "adaptive",
      "heartbeat": {
        "every": "30m",
        "model": "openrouter/google/gemini-2.5-flash",
        "lightContext": true,
        "isolatedSession": true
      },
      "memorySearch": {
        "extraPaths": ["/opt/cto/wiki", "/opt/cto/logs/decisions"]
      }
    }
  },
  "mcpServers": {
    "vault": {
      "command": "npx",
      "args": ["-y", "@bitbonsai/mcpvault@latest", "/opt/cto/wiki"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/opt/cto"]
    },
    "github": {
      "command": "/usr/local/bin/github-mcp-server",
      "args": [],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}" }
    },
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@brave/brave-search-mcp-server"],
      "env": { "BRAVE_API_KEY": "${BRAVE_API_KEY}" }
    },
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    },
    "hetzner": {
      "command": "npx",
      "args": ["-y", "@lazyants/hetzner-mcp-server"],
      "env": { "HETZNER_API_TOKEN": "${HETZNER_API_TOKEN}" }
    }
  }
}
```

## Sources
- [OpenClaw Install Docs](https://docs.openclaw.ai/install)
- [OpenClaw Onboard Wizard](https://docs.openclaw.ai/start/wizard)
- [OpenClaw Workspace Architecture](https://docs.openclaw.ai/concepts/agent-workspace)
- [OpenClaw System Prompt](https://docs.openclaw.ai/concepts/system-prompt)
- [OpenClaw Memory Config](https://docs.openclaw.ai/reference/memory-config)
- [OpenClaw Skills Docs](https://docs.openclaw.ai/tools/creating-skills)
- [OpenClaw Onboard CLI Reference](https://docs.openclaw.ai/cli/onboard)
- [OpenClaw Telegram Docs](https://docs.openclaw.ai/channels/telegram)
- [OpenClaw OpenRouter Docs](https://docs.openclaw.ai/providers/openrouter)
- [OpenRouter Integration Guide](https://openrouter.ai/docs/guides/coding-agents/openclaw-integration)
- [OpenClaw MCP Docs](https://docs.openclaw.ai/cli/mcp)
- [Hetzner Cloud API](https://docs.hetzner.cloud/)
- [hcloud CLI](https://github.com/hetznercloud/cli)
- [MCPVault](https://github.com/bitbonsai/mcpvault)
- [memweave](https://github.com/sachinsharma9780/memweave)
- [Brave Search MCP](https://brave.com/search/api/guides/use-with-openclaw/)
- [Hetzner Cloud MCP](https://glama.ai/mcp/servers/wbf-solutions/hetzner-cloud-mcp)
- [OpenClaw Install Docs](https://docs.openclaw.ai/install)
- [OpenClaw Onboard Wizard](https://docs.openclaw.ai/start/wizard)
- [OpenClaw Workspace Architecture](https://docs.openclaw.ai/concepts/agent-workspace)
- [OpenClaw System Prompt](https://docs.openclaw.ai/concepts/system-prompt)
- [OpenClaw Memory Config](https://docs.openclaw.ai/reference/memory-config)
- [OpenClaw Skills Docs](https://docs.openclaw.ai/tools/creating-skills)
- [OpenClaw Onboard CLI Reference](https://docs.openclaw.ai/cli/onboard)
