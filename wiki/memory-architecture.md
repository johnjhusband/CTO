# Memory Architecture
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

## Obsidian as Knowledge Layer

Community converged on Obsidian for the human-readable layer:
- `[[Wikilinks]]` with bidirectional backlinks — relational data without a database
- Graph view — visual map of knowledge connections
- Official CLI (60x faster than grep, 70,000x fewer tokens than MCP file reads)
- Official Agent Skills (14.9K stars) by Obsidian CEO
- 24+ MCP servers targeting Obsidian

**But Obsidian alone isn't enough for multi-agent:**
- No concurrent writes (silent corruption)
- No structured queries
- **Emerging hybrid:** markdown for storage + SQLite for search/coordination
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

## Recommendation for CTO

1. **Obsidian vault** as human-readable knowledge layer (wiki pages, decisions, research)
2. **SQLite coordination layer** underneath for concurrent access and structured queries
3. **Tiered loading** (L0/L1/L2 per OpenViking pattern) to minimize token costs
4. **SOUL.md** for CTO's persistent identity
5. **Graph memory** (Mem0 or similar) as CTO matures — evaluate as macro evolution decision
6. Consider **OpenViking** for the context database if the scale warrants it

## Sources
- [Mem0 State of AI Agent Memory 2026](https://mem0.ai/blog/state-of-ai-agent-memory-2026)
- [OpenViking GitHub](https://github.com/volcengine/OpenViking)
- [LinkedIn CMA](https://www.infoq.com/news/2026/04/linkedin-cognitive-memory-agent/)
- [SOUL.md Pattern](https://moto-westai.github.io/blog/2026/02/21/the-soul-md-pattern/)
- [Stop Calling It Memory](https://limitededitionjonathan.substack.com/p/stop-calling-it-memory-the-problem)
- [memweave](https://towardsdatascience.com/memweave-zero-infra-ai-agent-memory-with-markdown-and-sqlite/)
- [Obsidian CLI for agents](https://prokopov.me/posts/obsidian-cli-changes-everything-for-ai-agents/)
- [Tiger Data unified DB](https://www.tigerdata.com/learn/building-ai-agents-with-persistent-memory-a-unified-database-approach)
