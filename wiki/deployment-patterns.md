# Deployment Patterns & Production Lessons
**L0:** Five-layer architecture. VPS+systemd for 1-3 agents. Level 2-3 autonomy is production sweet spot. Memory is the #1 failure cause. Model routing saves 40-60%.
**L1:** Community converged on five layers: Brain (model+context), Hands (MCP tools), Memory (the moat), Spine (orchestration+A2A), Guardrails (safety). VPS+systemd/Docker dominant for small teams ($5-20/mo). Autonomy Level 2-3 (routers+tool use) works; Level 4 (multi-agent) is painful. Critical failures: OOM at 12-48hrs, infinite loops, stale memory, silent failures. Cost: model routing gives 40-60% savings, prompt caching 90% discount. 76% of 847 analyzed deployments failed from architectural issues. Single-task agents succeed 54%, large-scale 8%.
**Last updated:** 2026-04-26
**Source:** Live web research (April 2026), second research round

## The Five-Layer Architecture (Community Consensus)

1. **Brain** — Model selection, context management. Route 80% to cheap models for 60-80% cost reduction.
2. **Hands** — Tool use via MCP. 10,000+ MCP servers available.
3. **Memory** — The moat. Four layers: conversation, working, long-term (vector), shared (multi-agent). See [memory-architecture.md](memory-architecture.md).
4. **Spine** — Orchestration, routing, multi-agent coordination via A2A. See [protocol-layer.md](protocol-layer.md).
5. **Guardrails** — Observability, evals, cost controls, circuit breakers, human-in-the-loop escalation.

Most teams build layers 1-2, guess at 3, and skip 4-5. That's exactly where production breaks.

## Deployment Tiers

| Pattern | Best For | Cost |
|---------|----------|------|
| **VPS + systemd/Docker** | 1-3 agents, solo/small team | $5-20/mo |
| **Docker Compose on VPS** | Multi-agent, need isolation | $10-30/mo |
| **Kubernetes + Agent Sandbox** | 10+ agents, enterprise | $50+/mo |
| **klaw** (no K8s needed) | 5-15 agents | Varies |

Hetzner at ~$5-7/mo is the most-cited value pick. 2 vCPU / 4 GB RAM handles external-LLM agents comfortably.

## The Autonomy Spectrum — Where Production Lives

- **Level 1 (Chains):** Linear, deterministic. "Boring is good in production."
- **Level 2 (Routers):** Conditional logic, all paths predefined.
- **Level 3 (Tool Use):** LLM decides which tools to call.
- **Level 4 (Multi-Agent):** Multiple specialized agents collaborating.

**Consensus: Level 2-3 is the sweet spot. Level 4 is painful for production.**

Princeton NLP: single agent matched or outperformed multi-agent on 64% of benchmarked tasks.

## Critical Failure Modes

1. **OOM after 12-48 hours** — Memory consumption grows without GC. OpenClaw climbed to 28 GB by day 3.
2. **Infinite loops** — 27M tokens burned in 4.6 hours from ambiguous tool feedback.
3. **Cascading errors** — One agent's bad output becomes another's bad input.
4. **Silent failures** — Agent doesn't crash, just returns wrong/incomplete output.
5. **Stale memory** — Agent keeps regenerating already-sent reports.
6. **External dependency failures** — Browser tasks fail ~30%, rate limits hit 20-25% of API calls.

## Error Compounding Math

A 10-step workflow at 85% per-step accuracy succeeds **only 20%** of the time end-to-end. Need 98%+ per-step for 80% end-to-end success. This is why narrow scope wins.

## Recovery Patterns That Work

- Circuit breaker + exponential backoff on every external call
- State checkpointing to persistent storage
- Hard budget caps on steps, cost, and runtime
- FAILURE.md-style graduated intervention (slowdown → throttle → escalation → shutdown)
- GUARDRAILS.md — file-based safety constraints that survive context resets

## Cost Optimization (Ranked by Impact)

1. **Model routing** — Route simple to cheap, complex to frontier. 40-60% savings alone.
2. **Prompt caching** — 90% discount on cached input tokens (Anthropic).
3. **Batch processing** — 50% reduction for non-interactive tasks.
4. **Prompt compression** — Up to 20x compression on verbose prompts.
5. **Semantic caching** — Eliminates LLM call entirely on cache hits.
6. **Hard budget caps** — Daily spend limit, max steps per run, token counting before calls.

## Monitoring

Production minimum: health checks, alerts, log rotation. Unmonitored agents fail silently.

Mature teams use: Splunk AI Agent Monitoring, Grafana, AWS DevOps Agent, Langfuse/Traceloop (open source).

## Security

- 88% of organizations reported confirmed or suspected AI agent security incidents
- Only 14.4% have full security approval for their agent fleet
- More than half of agents operate without any security oversight
- **"Forget controlling the agents — control their tools instead."** MCP servers enable what agents can do.
- MicroVM sandboxing (SmolVM) for code execution, not Docker
- Docker's position: "An LLM deciding its own security boundaries is not a security model"

## Harness Engineering (The New Paradigm)

> "Agent = Model + Harness. The harness matters more than the model." — Harrison Chase, LangChain CEO

Evolution: Prompt Engineering → Context Engineering → **Harness Engineering**

The harness = instructions + tools + approvals + tracing + memory + resume bookkeeping. The model is increasingly a commodity.

## Production Statistics

| Metric | Value |
|--------|-------|
| Agents reaching production | 11% |
| Full operational scale | 2% of enterprises |
| Agent failure rate per run | 5-15% |
| AI projects cancelled by 2027 | 40%+ (Gartner) |
| Single-task agent success | 54% |
| Large-scale transformation success | 8% |
| Multi-agent token usage vs chat | 15x |

## Key Production Wisdom

- "Specialized agents with narrow tasks run more reliably than a single LLM executing a massive multi-step prompt" (Google)
- "Don't fix bugs yourself. Ask the AI to investigate, update docs, then fix." — knowledge compounds
- One team cut hallucination 60% by trimming system prompt from 2,400 to 380 tokens
- Agents are "extremely bad at architecture" — use them for implementation, you set architecture
- "Start with the simplest architecture that could work"
- The narrower the scope, the higher the success rate

## Sources
- [Databricks State of AI Agents](https://www.databricks.com/resources/ebook/state-of-ai-agents)
- [HyperTrends Production Patterns](https://www.hypertrends.com/2026/04/production-ai-agent-architecture-patterns/)
- [47Billion Production Guide](https://47billion.com/blog/ai-agents-in-production-frameworks-protocols-and-what-actually-works-in-2026/)
- [GUARDRAILS.md](https://guardrails.md/)
- [FAILURE.md](https://failure.md/)
- [Cloudflare Internal AI Stack](https://blog.cloudflare.com/internal-ai-engineering-stack/)
- [SmolVM](https://github.com/CelestoAI/SmolVM)
