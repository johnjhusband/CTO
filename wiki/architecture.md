# CTO Architecture
**Last updated:** 2026-04-26
**Source:** Live web research (April 2026) + PRD requirements

## Key Facts
- CTO is a fully autonomous AI agent running on a Hetzner VPS
- Self-improving through a clone-test-replace cycle using Docker
- Not locked to any LLM provider — multi-model via OpenRouter/LiteLLM
- Daily research cadence with automated upgrade evaluation
- Every version archived for rollback (git tags + Docker images)
- Only restriction: cannot spend money without user approval
- Budget-constrained: ~$7-30/month total (VPS + LLM API)

## Framework Decision (Pending Final Selection)

Based on live research (April 2026), the top candidates are:

### Hermes Agent (Nous Research) — Leading Candidate
- 95.6K GitHub stars, MIT license, released Feb 2026
- Self-improving learning loop (auto-creates skills, 40% speedup on repeat tasks)
- 24/7 background service, built-in cron, 16 messaging platforms
- Multi-model (200+ via OpenRouter), MCP support
- ~$7-22/month total cost
- Risk: 2 months old, security defaults need hardening

### Agent Zero — Strong Alternative
- 17.3K stars, MIT license, Docker-native
- Self-modifying, creates own tools, persistent memory
- Hierarchical multi-agent spawning in isolated containers
- Multi-model via LiteLLM
- Risk: Smaller community

### OpenClaw — Reference Architecture Only
- 364K stars but serious security issues (512 vulnerabilities, malicious skills)
- Good patterns to learn from, not recommended as primary framework

## Components
1. **Research Engine** — youtube-transcript-api + Gemini Flash for YouTube; GitHub/HN/web scrapers
2. **Decision Engine** — evaluates findings against current capabilities, filters signal
3. **Test Sandbox** — Docker-based clone environment for testing upgrades
4. **Upgrade Manager** — handles clone → test → archive → promote cycle
5. **Version Archive** — git tags, Docker images, decision logs for every version
6. **Communication Module** — Telegram Bot (primary), Gmail SMTP (fallback)
7. **Scheduler** — cron/systemd triggers daily research cycle
8. **LLM Router** — multi-model via OpenRouter/LiteLLM, cheap models for routine work

## Upgrade Cycle Flow
```
Research → Evaluate → Clone CTO into Docker → Apply upgrade to clone →
Run test suite → Pass? → Archive current → Promote clone → Report
                  Fail? → Iterate or abandon → Document reason → Report
```

## Infrastructure
- **VPS:** Hetzner (116.203.68.119, shared with DFU Mortgages currently)
- **Communication:** Telegram Bot API (primary), Gmail SMTP (fallback)
- **LLM:** OpenAI API via OpenRouter (GPT-5.4 mini for routine, escalate as needed)
- **YouTube:** youtube-transcript-api → Gemini Flash summarization
- **Orchestration (future):** Paperclip when building additional AI employees

## Relationships
- [Research Sources](research-sources.md) — where CTO looks for new tech
- [Upgrade Cycle](upgrade-cycle.md) — detailed clone-test-replace process
- [Decision Log Format](decision-log-format.md) — how decisions are recorded
- [LLM Strategy](llm-strategy.md) — provider evaluation and routing
- [Communication](communication.md) — notification channels

## Open Questions
- Final framework selection: Hermes Agent vs Agent Zero (need head-to-head evaluation)
- Hetzner VPS: use existing 116.203.68.119 or provision dedicated CTO instance?
- Security hardening plan for chosen framework
