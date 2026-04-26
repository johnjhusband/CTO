# Memory Architecture
**L0:** Obsidian vault + SQLite coordination + tiered loading (L0/L1/L2). Memory is the moat — models are swappable, knowledge compounds.
**L1:** Three-tier memory (hot/warm/cold) following community consensus. Obsidian vault for human-readable knowledge with wikilinks and graph. SQLite underneath for concurrent access and structured queries. Tiered context loading per OpenViking pattern: L0 summaries for discovery, L1 overviews for planning, L2 full content on demand (83% token reduction). SOUL.md for persistent identity. Graph memory (Mem0) as future enhancement. Leading frameworks: Mem0 (26% accuracy gain), Zep (temporal graph), Letta (OS-inspired), OpenViking (tiered loading, 15K stars).
**Last updated:** 2026-04-26
**Source:** Live web research (April 2026), second research round

## Key Facts
- Memory is the #1 reason agent projects fail (Gartner predicts 40% die by 2027 from this)
- "A frontier model with no memory is a genius with amnesia"
- Flat markdown wiki is already outdated — community converged on graph + vector hybrid with tiered loading
- Memory is the moat — models and frameworks are swappable; memory compounds

## The Tiered Memory Model (Near-Universal Consensus)

| Tier | Analogy | Behavior |
|------|---------|----------|
| **Hot Memory** | CPU registers/L1 cache | Immediate context in prompt window. Zero latency. |
| **Warm Memory** | RAM | Structured facts/preferences in high-speed database for RAG |
| **Cold Archive** | Disk | Compressed logs of old sessions for compliance/debugging |

Implemented as dual-layer: **Hot Path** (recent messages + summarized state) and **Cold Path** (retrieval from external stores via semantic search). A Memory Node synthesizes what to save after each turn.

## Memory Types (CoALA Cognitive Architecture)

- **Episodic Memory** — What happened. Specific past experiences with temporal details. Stored in vector databases.
- **Semantic Memory** — What I know. Factual knowledge independent of specific experiences.
- **Procedural Memory** — How to do it. Learned skills and workflows that improve with practice.

## Graph Memory (Production-Ready in 2026)

Vector memory retrieves semantically similar facts. Graph memory retrieves facts connected through relationships.

Vector store says: "this user mentioned Python."
Graph store says: "this user works with Python, specifically for data pipelines, using pandas, at a company that uses dbt."

Trend is toward **hybrid vector + graph** approaches.

## Leading Frameworks

| Framework | Approach | Key Strength |
|-----------|----------|-------------|
| **Mem0** | Hybrid Postgres storage | 26% accuracy gains over plain vector; widely adopted |
| **Zep** | Temporal Knowledge Graph | Relational accuracy, evolving facts and entity relationships |
| **Letta** | OS-inspired virtual context | Tiered memory mimicking OS hierarchy; agents control own memory |
| **LinkedIn CMA** | Shared memory infrastructure | Stateful context across application agents |
| **OpenViking** (ByteDance) | Context Database with tiered loading | 49% improvement, 83% token reduction, 15K+ GitHub stars |

## OpenViking — The Leapfrog Option

NOT another vector database. A "Context Database" using virtual filesystem paradigm.

**Tiered Context Loading (L0/L1/L2):**
- **L0** = one-sentence summary (<100 tokens) — for discovery
- **L1** = README-level overview (<2,000 tokens) — for planning
- **L2** = full content loaded on demand — for deep work

Every piece of context auto-processed into 3 detail levels on write. Agent only loads what it needs.

**Our current wiki = all L2 (full detail, always loaded).** OpenViking would give us tiered loading that dramatically cuts tokens.

## Obsidian-Compatible Knowledge Layer

**Critical finding: Obsidian desktop app requires a GUI. It cannot run on a headless VPS.**

The correct architecture for a headless VPS:
- Vault is a **plain directory of .md files** with `[[wikilinks]]`
- A **filesystem MCP server** (MCPVault or obsidian-mcp) gives the agent read/write/search
- Wikilinks are parseable with regex `\[\[([^\]]+)\]\]` — MCP servers resolve them
- **John uses Obsidian on his desktop** for graph view and visual editing, synced to VPS via git
- VPS agent operates on raw files through MCP — no Obsidian app needed

MCP server options for headless VPS:
| Server | Install | Features |
|--------|---------|----------|
| **MCPVault** | `npm install -g @bitbonsai/mcpvault` | Zero deps, 14 tools, tag scanning, soft-delete |
| **obsidian-mcp** | `pip install obsidian-mcp` | SQLite indexing, regex search, 90% less memory |

**Obsidian alone isn't enough for multi-agent anyway:**
- No concurrent writes (silent corruption)
- No structured queries
- **Hybrid required:** markdown for storage + SQLite for search/coordination
- memweave, EchoVault, Google Memory Agent pattern all use this

## PostgreSQL as Unified Store

Strong trend: consolidate agent memory into single PostgreSQL database combining:
- Hypertables for time-series conversation history
- pgvectorscale for semantic search
- Standard SQL for structured state

Eliminates multi-database complexity.

## SOUL.md Pattern — Agent Identity Persistence

Every time an agent wakes up, SOUL.md is loaded. Defines identity, values, voice — not capabilities.
- **SOUL.md** — Who the agent is (identity, values, voice). Agent can self-edit.
- **HEARTBEAT.md** — How the agent behaves (recurring patterns, self-checks)
- **MEMORY.md** — Curated stable info loaded at every session start

Research on 41,300 AI agent posts showed +72 percentage point improvement in safety compliance from adding identity/persona. Persona is structural, not cosmetic.

## CTO Memory Architecture (Agreed Design)

1. **Obsidian vault** as human-readable knowledge layer (wiki pages, decisions, research)
2. **SQLite coordination layer** underneath for concurrent access and structured queries
3. **Tiered loading** (L0/L1/L2 per OpenViking pattern) to minimize token costs
4. **SOUL.md** for CTO's persistent identity
5. **Graph memory** (Mem0 or similar) as CTO matures — evaluate as macro evolution decision
6. Consider **OpenViking** for the context database if the scale warrants it

This is the agreed architecture. It must not be downgraded for implementation convenience.

## How This Maps onto OpenClaw's Native Memory

OpenClaw has its own three-tier memory system. It is a component within our architecture, not a replacement:

| Our Architecture | OpenClaw Native | Gap |
|-----------------|----------------|-----|
| Obsidian vault with wikilinks + graph | wiki/ indexed via memorySearch.extraPaths | OpenClaw searches but doesn't provide wikilinks or graph view. Obsidian adds this as the human-facing layer. |
| SQLite coordination layer | OpenClaw uses SQLite internally for memory search index | Partial overlap. May need additional SQLite tables for structured queries OpenClaw doesn't support. |
| Tiered loading (L0/L1/L2) | OpenClaw loads MEMORY.md (Tier 1) + daily files (Tier 2) + searches Tier 3 | Our L0/L1 headers on wiki pages help when retrieved but OpenClaw doesn't natively understand the L0/L1/L2 convention. The agent must be taught this in AGENTS.md. |
| SOUL.md identity | OpenClaw auto-loads SOUL.md every session | Direct match. |
| Graph memory (Mem0) | Not in OpenClaw | Future enhancement. Must be added as a skill or integration. |
| OpenViking context database | Not in OpenClaw | Future enhancement. Evaluate as macro evolution decision. |

## Implementation Priority

**v1:** Use OpenClaw's native memory as the foundation. Add Obsidian as the human-facing knowledge layer on top. Teach CTO the L0/L1/L2 convention via AGENTS.md so it loads summaries first and full content on demand.

**v1.1+:** Evaluate whether to add SQLite coordination tables beyond what OpenClaw provides natively. Evaluate Mem0 for graph memory. Evaluate OpenViking for context database.

These are macro evolution decisions CTO should make for itself based on community research — exactly the kind of upgrade the system is designed to perform.

## Backup Strategy

Memory is the moat. If it's lost, it can't be rebuilt. Three layers of protection:

**Layer 1: Git (continuous)**
- All wiki pages, skills, decision logs, SOUL.md, MEMORY.md are in git
- Every commit pushes to GitHub (offsite backup)
- Git history preserves every version of every file

**Layer 2: Hetzner VPS Snapshots (before every upgrade)**
- Full disk snapshot before any clone-test-replace promotion
- Captures everything including runtime state, daily memory files, SQLite indexes
- Snapshots stored on Hetzner infrastructure (EUR 0.012/GB/month)

**Layer 3: Daily memory export (automated)**
- CTO exports `memory/` directory contents to git daily
- Includes daily context files (`memory/YYYY-MM-DD.md`) that aren't in the main repo
- SQLite index is rebuildable from markdown (memweave pattern) — losing the DB is not data loss, losing the markdown IS

**What's NOT backed up (acceptable losses):**
- OpenClaw session history (ephemeral, summarized into MEMORY.md)
- LLM conversation transcripts (key decisions extracted into decision logs)
- Cached embeddings (rebuildable from source files)

## Sources
- [Mem0 State of AI Agent Memory 2026](https://mem0.ai/blog/state-of-ai-agent-memory-2026)
- [OpenViking GitHub](https://github.com/volcengine/OpenViking)
- [LinkedIn CMA](https://www.infoq.com/news/2026/04/linkedin-cognitive-memory-agent/)
- [SOUL.md Pattern](https://moto-westai.github.io/blog/2026/02/21/the-soul-md-pattern/)
- [Stop Calling It Memory](https://limitededitionjonathan.substack.com/p/stop-calling-it-memory-the-problem)
- [memweave](https://towardsdatascience.com/memweave-zero-infra-ai-agent-memory-with-markdown-and-sqlite/)
- [Obsidian CLI for agents](https://prokopov.me/posts/obsidian-cli-changes-everything-for-ai-agents/)
- [Tiger Data unified DB](https://www.tigerdata.com/learn/building-ai-agents-with-persistent-memory-a-unified-database-approach)
