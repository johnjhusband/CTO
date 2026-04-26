# Karpathy Patterns & Technologies
**L0:** LLM Wiki (compile knowledge), AutoResearch (constrained loop), Agentic Engineering (orchestrate agents), LLM OS (agent=kernel), idea files, ghost awareness.
**L1:** Karpathy defined key patterns for autonomous agents: LLM Wiki (compile knowledge into interlinked markdown, don't RAG every session — 16M views), AutoResearch/Karpathy Loop (constrained agent + metric + iterate — 66K stars, 700 experiments in 2 days), Agentic Engineering (orchestrate fleets of agents, you own architecture), LLM OS (agent=kernel, tools=syscalls), idea files over code (share markdown instructions), three-file contract (immutable eval + modifiable code + human direction), ghost awareness (design for pattern-matching, add verifiable checkpoints).
**Last updated:** 2026-04-26
**Verification:** Claims about Karpathy's work from web research. GitHub star counts and release dates not independently verified. Patterns are widely cited across multiple sources.
**Source:** Live web research (April 2026) — Karpathy's posts, talks, repos, interviews

## Why This Matters
Andrej Karpathy is defining the patterns that shape how autonomous AI agents should be built. His frameworks (LLM Wiki, AutoResearch, Agentic Engineering, LLM OS) are not theoretical — they're battle-tested with open-source implementations and massive community adoption.

## 1. LLM Wiki — Knowledge That Compounds (April 2026)

**Core concept:** Don't use LLMs with RAG (re-discover knowledge every query). Instead, "compile" raw sources into a structured, interlinked wiki of markdown files. The wiki compounds over time.

**Three-layer architecture:**
1. **Sources Layer (raw/):** Immutable raw inputs — papers, transcripts, articles. Never modified by LLM.
2. **Wiki Layer:** Plain markdown files with `[[wiki-links]]`. LLM reads, writes, maintains these.
3. **Lint/Maintenance:** LLM periodically audits — finds contradictions, orphan pages, missing concepts.

**Quote:** "Obsidian is the IDE; the LLM is the programmer; the wiki is the codebase."

**Scale:** Karpathy's own wiki reached ~100 articles, 400,000 words. Faster and more accurate than RAG.

**CTO application:** This IS the memory architecture. CTO's wiki/ directory already follows this pattern. Needs to be formalized with the three-layer approach.

**Sources:** [Karpathy's LLM Wiki Gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) | 16M+ views, 5K+ stars

## 2. AutoResearch — The Karpathy Loop (March 2026)

**Core concept:** A 630-line Python script for autonomous ML experimentation. 66,000+ GitHub stars. Fortune named it "The Karpathy Loop."

**How it works:**
- Agent gets a `program.md` (human-authored direction)
- Loops indefinitely: read code → propose change → run 5-min experiment → measure → commit if improved, revert if not
- Fixed time budget per experiment (~12/hour, ~100 overnight)

**Three-file contract:**
1. `prepare.py` — Immutable evaluator. Agent cannot touch it.
2. `train.py` — Single file the agent edits.
3. `program.md` — Human-authored instruction/constraints.

**Results:** 700 experiments in 2 days. 20 additive improvements. 11% gain on a project Karpathy thought was optimized.

**Key insight:** "Constraint is the innovation." AutoGPT failed trying to be general. AutoResearch works because it's narrow, bounded, measurable.

**CTO application:** The clone-test-replace cycle should follow this pattern. Define measurable metrics, constrain the action space, let the agent loop. The three-file contract (immutable evaluator + modifiable implementation + human direction) maps directly to CTO's test suite + code + PRD.

**Sources:** [AutoResearch GitHub](https://github.com/karpathy/autoresearch) | [Fortune: The Karpathy Loop](https://fortune.com/2026/03/17/andrej-karpathy-loop-autonomous-ai-agents-future/)

## 3. Agentic Engineering (February 2026)

**Core concept:** The successor to "vibe coding" (which Karpathy coined Feb 2025). You're not writing code — you're orchestrating agents who do.

**Quote:** "In December [2025] something flipped where I went from 80-20 of writing code myself versus delegating to agents to like 20-80."

**Five disciplines:**
1. Plan before prompting
2. Direct with precision
3. Review rigorously
4. Test systematically
5. Own the architecture

**Key metric:** Token throughput. Idle tokens = you're the bottleneck. Run more agents in parallel.

**CTO application:** CTO should orchestrate sub-agents for research, evaluation, testing — not try to do everything in one context. Strategic planning + delegation + review.

**Sources:** [The New Stack: Vibe Coding is Passe](https://thenewstack.io/vibe-coding-is-passe/) | [The AI Corner: Karpathy Workflow Shift](https://www.the-ai-corner.com/p/andrej-karpathy-ai-workflow-shift-agentic-era-2026)

## 4. LLM OS — LLMs as Operating Systems (2023, still influential)

**Core concept:** View LLMs not as chatbots but as kernel processes of a new OS.

**Mapping:**
- LLM = CPU + shell (processes instructions)
- Context window = RAM
- Retrieval systems = filesystem
- Agents = long-running apps
- Tool/API calls = system calls

**CTO application:** CTO IS an LLM OS. It orchestrates tools, memory, I/O, and sub-agents through natural language — exactly like a kernel manages hardware and software through system calls.

**Sources:** [Karpathy's original tweet](https://x.com/karpathy/status/1707437820045062561) | [Hugging Face: Illustrated LLM OS](https://huggingface.co/blog/shivance/illustrated-llm-os)

## 5. Idea Files Over Code (April 2026)

**Core concept:** In the LLM agent era, share "idea files" (markdown instructions) instead of code. The recipient's agent customizes implementation for their needs.

**Quote:** "In this era of LLM agents, there is less of a point/need of sharing the specific code/app, you just share the idea."

**Examples:** CLAUDE.md, program.md, idea file gists.

**CTO application:** CTO's wiki, PRD, and beads are already idea files. CTO should consume and produce idea files as its primary interface with the knowledge landscape.

**Sources:** [Karpathy's idea file tweet](https://x.com/karpathy/status/2040470801506541998)

## 6. Ghost Awareness (December 2025)

**Core concept:** "We're not evolving/growing animals, we are summoning ghosts." LLMs are imperfect replicas — statistical distillations of humanity's documents.

**Implications:**
- Brilliant at pattern-matching known solutions
- Bad at novel reasoning outside training distribution
- "Jagged" intelligence — genius polymath AND confused grade schooler simultaneously
- Don't expect animal-like learning from experience; expect ghost-like pattern retrieval

**CTO application:** Design for pattern-matching strength. Add verifiable checkpoints. Expect jagged capability. The agent will excel at applying known patterns to the CTO workflow but needs guardrails for truly novel territory.

**Sources:** [Animals vs Ghosts](https://karpathy.bearblog.dev/animals-vs-ghosts/) | [2025 Year in Review](https://karpathy.bearblog.dev/year-in-review-2025/)

## 7. LLM Coding Pitfalls (January 2026)

Three recurring failure modes Karpathy identified after going 80% agent-driven:

1. **Silent wrong assumptions** — Models assume on your behalf without checking
2. **Over-complication** — Bloated abstractions, dead code accumulation
3. **Lack of verifiable goals** — "Don't tell it what to do, give it success criteria and watch it go"

Community response: `andrej-karpathy-skills` repo (71,500+ stars) distilled these into a CLAUDE.md plugin.

**CTO application:** Build assumption checking, simplicity bias, surgical changes, and measurable success criteria into CTO's decision engine.

**Sources:** [Karpathy-Skills CLAUDE.md](https://github.com/mulica-ai/andrej-karpathy-skills)

## 8. Software 3.0 (June 2025)

**Evolution:**
- **Software 1.0:** Humans write explicit code
- **Software 2.0:** Developers curate data, train neural nets; logic is in weights
- **Software 3.0:** Prompts are programs written in English

**Quote:** "The hottest new programming language is English."

**Sources:** [YouTube: Software Is Changing (Again)](https://www.youtube.com/watch?v=LCEmiRjPEtQ)

## Karpathy's Tool Preferences (2026)
- **Claude Code** — most-used AI coding tool (~4% of all public GitHub commits)
- **Cursor** — market leader for professional devs
- **SuperWhisper** — voice-to-text for prompting agents
- **tmux grids** — multiple agents in parallel terminals
- **Obsidian** — viewing LLM Wiki output
- **Git** — version control for both human instructions and agent-modified code

## Summary: 10 Karpathy Principles for CTO

1. **LLM Wiki for memory** — compile knowledge, don't re-search
2. **The Karpathy Loop** — constrained agent + metric + time budget + iterate
3. **Agentic Engineering** — orchestrate fleets of agents, don't code yourself
4. **Idea files over code** — share markdown instructions, not implementations
5. **Three-file contract** — immutable eval + modifiable code + human direction
6. **Constraint is innovation** — narrow and measurable beats general and ambitious
7. **LLM OS architecture** — agent = kernel; tools = syscalls; context = RAM
8. **Ghost awareness** — design for pattern-matching, add verifiable checkpoints
9. **Success criteria over instructions** — tell it WHAT to achieve, not HOW
10. **The decade timeline** — build infrastructure that compounds

## Relationships
- [Architecture](architecture.md) — Karpathy patterns shape the CTO architecture
- [Upgrade Cycle](upgrade-cycle.md) — The Karpathy Loop maps to clone-test-replace
- [Research Sources](research-sources.md) — Karpathy's YouTube channel is a Tier 1 source
- [v1 Recommendation](v1-recommendation.md) — Patterns inform framework selection
