# Agent Framework & Tool Research
**Last updated:** 2026-04-26
**Source:** Live web research (April 2026) — 13 research agents, all data verified

## Landscape Summary (April 2026)

The autonomous agent space has exploded since late 2025. This page covers every significant tool evaluated for the CTO project, organized by category.

---

## Category 1: Self-Improving Autonomous Agents (VPS-Ready)

### Hermes Agent (Nous Research) — 95.6K stars
- **Released:** Feb 25, 2026 | **License:** MIT | **Language:** Python
- **What:** Persistent 24/7 background agent with self-improving learning loop
- Runs as systemd/Docker service, built-in cron scheduler
- Auto-creates reusable "skills" from successful tasks (40% speedup on repeats)
- Self-evolution repo using DSPy + GEPA (ICLR 2026 paper)
- 16 messaging platforms (Telegram, WhatsApp, Discord, Slack, etc.)
- MCP support (client + server), 6 terminal backends
- Multi-model: 200+ via OpenRouter, Ollama, any provider
- Cost: ~$7-22/month total
- **Risks:** 2 months old. Security audit found 4 critical + 9 high issues. Default ALLOW-ALL. GODMODE skill.
- [GitHub](https://github.com/NousResearch/hermes-agent) | [Docs](https://hermes-agent.nousresearch.com/docs/)

### OpenHands (formerly OpenDevin) — 68-70K stars
- **Version:** v1.6.0 (Mar 30, 2026) | **License:** MIT | **Language:** Python
- **What:** Leading open-source autonomous software engineer
- Full agentic loop: code, terminal, web browsing, PR creation
- Sandboxed Docker containers for safe execution
- "Ouroboros" self-improvement research project
- Planning Mode (beta), long-horizon work (30+ hour runs documented)
- Multi-model: 100+ via LiteLLM
- SWE-bench: up to 77.6% with Claude 3.5 Sonnet
- 490+ contributors, $18.8M Series A
- VPS-ready: $10-20/mo Hetzner is sufficient
- [GitHub](https://github.com/OpenHands/OpenHands) | [Website](https://openhands.dev/)

### Agent Zero — 17.3K stars
- **Version:** v1.9 (Apr 13, 2026) | **License:** MIT | **Language:** Python
- **What:** Docker-native autonomous agent that creates its own tools
- Runs in own Docker container with full Linux environment
- Dynamic tool creation, persistent memory, self-correction
- Hierarchical multi-agent spawning in isolated containers
- Multi-model via LiteLLM, private search (SearXNG)
- [GitHub](https://github.com/agent0ai/agent-zero) | [Website](https://www.agent-zero.ai/)

### OpenClaw (formerly Clawdbot) — 364K stars
- **License:** MIT | **Language:** Node.js
- **What:** General-purpose event-driven autonomous agent
- Fastest-growing GitHub repo in history
- 5,700+ skills on ClawHub, 16 messaging platforms, cron, multi-agent
- Creator joined OpenAI Feb 2026; non-profit foundation took over
- **SERIOUS SECURITY:** 512 vulns in audit, 8 critical. Zero-click WebSocket hijack. 1,467 malicious ClawHub skills. 42K exposed instances on Shodan.
- **Verdict:** Reference architecture and cautionary tale. Learn from its patterns, don't deploy it.
- [GitHub](https://github.com/openclaw/openclaw)

---

## Category 2: Headless Coding Agents (VPS-Ready)

### Cline CLI 2.0 — 58K stars
- **License:** Apache 2.0 | **Language:** TypeScript
- **What:** Top open-source coding agent, now with headless CLI
- `cline -y` for YOLO mode (full autonomy, no prompts)
- JSON output for programmatic consumption
- Multi-model: 10+ providers + Ollama + OpenRouter
- MCP integration, native subagents (v3.58+)
- Parallel instances via tmux
- Enterprise: Salesforce, Samsung, SAP, Oracle
- [GitHub](https://github.com/cline/cline) | [CLI Docs](https://cline.ghost.io/introducing-cline-cli-2-0/)

### Aider — 43.9K stars
- **Version:** v0.86.0 (Aug 2025) | **License:** Apache 2.0 | **Language:** Python
- **What:** Terminal AI pair programmer with best-in-class git integration
- Auto-commits every change, architect mode (reasoning + cheap editor)
- Multi-model: 100+ LLMs
- `--yes-always` for basic autonomy (but no shell command auto-confirm)
- No persistent memory, single-threaded, no sub-agents
- Writes 70-88% of its own code each release
- **Best used as:** Callable coding tool, not the agent itself
- [GitHub](https://github.com/Aider-AI/aider) | [Website](https://aider.chat/)

### OpenAI Codex CLI — 77.9K stars
- **Version:** v0.125.0 (Apr 24, 2026) | **License:** Apache 2.0 | **Language:** Rust
- Full-auto mode with kernel-level sandboxing
- OpenAI models only (GPT-5.5, GPT-5.4, o3, o4-mini)
- Works with ChatGPT Plus/Pro subscription
- Sandbox restricts filesystem — conflicts with self-upgrading needs
- [GitHub](https://github.com/openai/codex)

### Claude Agent SDK — 6.5K stars
- **Version:** v0.2.119 (Apr 24, 2026) | **License:** MIT | **Language:** Python/TS
- Full autonomous agent loop with shell/file/web access
- Claude only. Pay-per-token ($3/$15 per M for Sonnet)
- SWE-bench: 87.6% (highest)
- [GitHub](https://github.com/anthropics/claude-agent-sdk-python)

---

## Category 3: Agent Frameworks (Build Your Own)

### AutoGPT Platform — 184K stars
- **Version:** v0.6.57 (Apr 22, 2026) | **License:** Polyform Shield / MIT
- Visual workflow builder, continuous cloud agents, marketplace
- Graphiti temporal knowledge graph memory
- Docker Compose self-hostable, multi-model
- **Note:** Polyform Shield license restricts competing products
- [GitHub](https://github.com/Significant-Gravitas/AutoGPT)

### CrewAI — 49.9K stars
- **Version:** v1.14.3 (Apr 24, 2026) | **License:** MIT | **Language:** Python
- Role-based multi-agent collaboration
- 4-layer memory (short/long/entity/contextual)
- Not designed for self-modification
- [GitHub](https://github.com/crewAIInc/crewAI)

### Mastra — 22.3K stars
- **Version:** 1.0 (Jan 2026) | **License:** Apache 2.0 | **Language:** TypeScript
- By Gatsby.js team, YC W25, $36M funded
- 3,300+ models from 94 providers via Model Router
- Built-in memory, workflows, RAG, MCP
- TypeScript only — won't fit Python stacks
- [GitHub](https://github.com/mastra-ai/mastra)

### Google ADK — 15.6K stars
- **License:** Apache 2.0 | **Languages:** Python/TS/Go/Java
- A2A protocol (150+ orgs in production)
- Multi-model (Gemini-optimized, supports others via LiteLLM)
- Best for inter-agent communication
- [GitHub](https://github.com/google/adk-python)

### Microsoft Agent Framework — 9.8K stars
- **Version:** v1.2.0 (Apr 24, 2026) | **License:** MIT
- Replaced AutoGen (now maintenance mode)
- Enterprise focus, Azure-centric
- [GitHub](https://github.com/microsoft/agent-framework)

---

## Category 4: Memory Systems

### Letta (MemGPT) — 22.3K stars
- **Version:** v0.16.7 (Mar 31, 2026) | **License:** Apache 2.0
- Most sophisticated persistent memory: 3-tier self-editing (core/recall/archival)
- Agent decides what to remember/forget via tool calls
- Context Repositories with git-based versioning (Feb 2026)
- Self-hostable (Docker + PostgreSQL)
- **Caveat:** Full agent runtime, not pluggable memory layer. High lock-in.
- [GitHub](https://github.com/letta-ai/letta)

### Obsidian / LLM Wiki Pattern
- Karpathy's approach: compile knowledge into interlinked markdown wiki
- Obsidian Skills (13.9K stars) by Steph Ango (Obsidian CEO)
- Obsidian CLI (Feb 2026) for programmatic vault access
- Low lock-in, markdown-native, works with any agent
- See [karpathy-patterns.md](karpathy-patterns.md)

---

## Category 5: Orchestration (Future Multi-Agent)

### Paperclip — 53-58K stars
- **License:** MIT | **Language:** TypeScript
- Agent orchestration platform: org charts, budgets, goals, audit trails
- Bring-your-own agents (Claude Code, Codex, Hermes, etc.)
- Not needed for single agent — becomes critical for CFO/CEO/CMO phase
- [GitHub](https://github.com/paperclipai/paperclip)

---

## Category 6: Cloud-Only (Not VPS-Viable)

| Tool | Stars | Why Not |
|------|-------|---------|
| Devin 3.0 | N/A (closed) | Cloud-only, proprietary, $8-9/hr. SWE-bench 51.5% |
| Manus AI | N/A (closed) | Meta-owned, invite-only, 500K waitlist |
| Cursor 3 | N/A (closed) | GUI-required, cloud agents locked to Cursor infrastructure |

---

## Category 7: Research / Conceptual

### Darwin Godel Machine (Sakana AI) — ~1.5K stars
- Self-rewriting agent via evolutionary search. SWE-bench 20% → 50%
- **$22,000 per evolutionary run** — research system, not practical
- Key pattern: evolutionary archive (maintain diverse variants, not just best)
- [GitHub](https://github.com/jennyzzt/dgm) | [Paper](https://arxiv.org/abs/2505.22954)

### OpenManus — 72K stars
- Open-source Manus alternative, 79-94% of Manus performance at 12% cost
- Self-hostable, MCP integration
- [GitHub](https://github.com/FoundationAgents/OpenManus)

---

## Category 8: Deprecated / Stalled

| Tool | Stars | Status |
|------|-------|--------|
| Open Interpreter | 63.3K | No releases since Oct 2024. Team pivoted. AGPL. |
| AutoGen | 57.4K | Maintenance mode. Replaced by MS Agent Framework. |
| SuperAGI OSS | 17.5K | Last release Jan 2024. Company pivoted to CRM SaaS. |

---

## Master Comparison (VPS-Ready Candidates)

| Tool | Stars | License | Multi-Model | Self-Improve | Headless | Messaging | Memory | VPS Cost |
|------|-------|---------|-------------|-------------|----------|-----------|--------|----------|
| Hermes Agent | 95.6K | MIT | 200+ | Learning loop | Yes | 16 platforms | Skills + FTS5 | ~$7-22/mo |
| OpenHands | 68-70K | MIT | 100+ | Ouroboros | Yes | No | Session | ~$10-20/mo |
| Cline CLI | 58K | Apache-2.0 | 10+ | No | Yes (YOLO) | No | No | API only |
| Agent Zero | 17.3K | MIT | LiteLLM | Tool creation | Yes | No | Persistent | API only |
| Letta | 22.3K | Apache-2.0 | Any | Self-editing memory | Yes | No | 3-tier | ~$5-10/mo |

## Open Questions
- Hermes Agent vs OpenHands head-to-head for self-upgrading use case
- Can Cline CLI serve as the coding execution layer inside Hermes Agent?
- Letta's memory model vs Karpathy's LLM Wiki pattern — which gives more value for CTO?
- A2A protocol (Google ADK) relevance when building CFO/CEO later
