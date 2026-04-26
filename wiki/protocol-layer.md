# Protocol Layer — The New Standards Stack
**L0:** MCP (tools, 97M installs), A2A (agent-to-agent, 150+ orgs), AGENTS.md (context, 60K repos). All Linux Foundation governed.
**L1:** Three open standards form the foundational infrastructure. MCP is the universal agent-to-tool protocol (97M monthly SDK installs). A2A is the agent-to-agent communication protocol (JSON-RPC 2.0 over HTTP, supports Agent Cards for discovery). AGENTS.md gives agents project-specific context. All governed by AAIF (Agentic AI Foundation) under Linux Foundation, co-founded by Anthropic, OpenAI, Google, Microsoft, AWS — 170+ member orgs. Building on proprietary protocols is a dead end.
**Last updated:** 2026-04-26
**Source:** Live web research (April 2026), second research round

## Key Facts
- Three protocols now form the foundational infrastructure for all agent systems
- All three are governed by the **Agentic AI Foundation (AAIF)** under the Linux Foundation
- AAIF co-founded by Anthropic, OpenAI, Google, Microsoft, AWS, Block — 170+ member organizations
- Building on anything else is building on sand

## 1. MCP (Model Context Protocol) — Agent-to-Tool

**Status:** 97 million monthly SDK installs (March 2026). De facto universal standard.

- Every major AI provider ships MCP-compatible tooling (OpenAI, Google, Microsoft, Salesforce, Amazon)
- 10,000+ published MCP servers
- Originally Anthropic's, donated to Linux Foundation December 2025
- Gives agents "hands" — standardized way to interact with tools, APIs, databases, file systems

**April 2026 updates:**
- Microsoft shipped MCP servers for Fabric, SQL, Power Apps
- Google shipped MCP server for Colab
- Cloudflare Code Mode MCP Server: 99.9% token reduction (1.17M → ~1,000 tokens) across 2,500+ API endpoints
- Salesforce exposed entire platform as MCP tools via "Headless 360"

## 2. A2A (Agent-to-Agent Protocol) — Agent-to-Agent

**Status:** v1.0 stable specification. 150+ organizations. Linux Foundation governed. Production at Microsoft, AWS, Salesforce, SAP, ServiceNow.

- JSON-RPC 2.0 over HTTP(S)
- Agents discover each other via "Agent Cards" with capabilities and connection info
- Supports sync, streaming (SSE), and async push
- Agents collaborate WITHOUT sharing internal memory or proprietary logic
- Agent Payments Protocol (AP2) for agent-driven economic transactions — 60+ orgs in payments/fintech
- Native in Google ADK, LangGraph, CrewAI, LlamaIndex, Semantic Kernel, AutoGen

## 3. AGENTS.md — Agent Context Standard

**Status:** 60,000+ repositories contain AGENTS.md.

- Markdown file at repo root giving AI agents project-specific guidance
- Build commands, conventions, testing rules, constraints
- Like README but for agents
- Hierarchical — sub-directories can have their own AGENTS.md
- Keep under 150 lines
- ETH Zurich study: human-curated context files help; LLM-generated ones hurt

## Impact on CTO Architecture
- CTO should expose capabilities as MCP servers and consume tools via MCP clients
- A2A is how CTO communicates with future AI employees (CFO, CEO, CMO)
- AGENTS.md should be in the CTO repo root
- Custom inter-agent protocols are now a dead end

## Sources
- [A2A Protocol 150+ Organizations](https://www.prnewswire.com/news-releases/a2a-protocol-surpasses-150-organizations-302737641.html)
- [MCP vs A2A Complete Guide](https://dev.to/pockit_tools/mcp-vs-a2a-the-complete-guide-to-ai-agent-protocols-in-2026-30li)
- [Linux Foundation AAIF](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation)
- [AGENTS.md](https://agents.md/)
- [Cloudflare Code Mode MCP](https://www.infoq.com/news/2026/04/cloudflare-code-mode-mcp-server/)
