# CTO Architecture
**Last updated:** 2026-04-26
**Source:** Live web research (April 2026) + requirements analysis + architectural corrections

## Key Facts
- CTO is a fully autonomous AI agent running on a dedicated Hetzner VPS
- Self-improving through macro evolution (research-driven) and micro evolution (experience-driven)
- Macro evolution tests on a **fresh VPS**, not Docker containers — full system access requires full system testing
- Not locked to any LLM provider — multi-model via OpenRouter/LiteLLM
- Every version archived via Hetzner snapshots + git tags for rollback
- Only restriction: cannot spend money without user approval
- Budget-constrained

## Framework: OpenClaw
Selected after requirements-based evaluation prioritizing macro evolution. See [v1-evaluation.md](v1-evaluation.md) for full rationale.

## Components
1. **Research Engine** — YouTube transcript extraction (browser-based via skills/MCPs), GitHub/HN/web scrapers
2. **Decision Engine** — evaluates findings against current capabilities, filters signal
3. **Test Environment** — fresh Hetzner VPS provisioned via API for testing upgrades (not Docker)
4. **Upgrade Manager** — handles provision → deploy → test → archive → promote cycle
5. **Version Archive** — Hetzner snapshots, git tags, decision logs for every version
6. **Communication Module** — WhatsApp (primary via OpenClaw built-in), Telegram/Gmail fallback
7. **Scheduler** — OpenClaw built-in cron triggers daily research cycle
8. **LLM Router** — multi-model via OpenRouter, cheap models for routine, escalate for complex

## Upgrade Cycle Flow
```
Research → Evaluate → Provision candidate VPS ��� Deploy candidate →
Run test suite on candidate → Pass? → Snapshot current → Promote candidate → Destroy old → Report
                               Fail? → Iterate or destroy candidate → Document reason → Report
```

## Infrastructure
- **Primary VPS:** Hetzner 178.104.213.9 (8 vCPU, 16 GB RAM, 150 GB disk)
- **Test VPS:** Provisioned on-demand via Hetzner API, destroyed after testing
- **Communication:** WhatsApp (primary), Telegram (fallback), Gmail SMTP (fallback)
- **LLM:** OpenRouter for multi-model access
- **YouTube:** Browser-based interaction via skills/MCPs for v1

## Relationships
- [Research Sources](research-sources.md) — where CTO looks for new tech
- [Upgrade Cycle](upgrade-cycle.md) — detailed VPS-based clone-test-replace process
- [Decision Log Format](decision-log-format.md) — how decisions are recorded
- [LLM Strategy](llm-strategy.md) — provider evaluation and routing
- [Communication](communication.md) — notification channels
- [Karpathy Patterns](karpathy-patterns.md) — design principles

## Open Questions
- Hetzner API token for programmatic VPS provisioning
- State migration between VPS instances during promotion
- IP address strategy (static IP vs DNS update)
