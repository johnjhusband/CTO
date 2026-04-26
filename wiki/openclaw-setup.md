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

## Sources
- [OpenClaw Install Docs](https://docs.openclaw.ai/install)
- [OpenClaw Onboard Wizard](https://docs.openclaw.ai/start/wizard)
- [OpenClaw Workspace Architecture](https://docs.openclaw.ai/concepts/agent-workspace)
- [OpenClaw System Prompt](https://docs.openclaw.ai/concepts/system-prompt)
- [OpenClaw Memory Config](https://docs.openclaw.ai/reference/memory-config)
- [OpenClaw Skills Docs](https://docs.openclaw.ai/tools/creating-skills)
- [OpenClaw Onboard CLI Reference](https://docs.openclaw.ai/cli/onboard)
