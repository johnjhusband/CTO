# Production Lessons — Hard-Won Wisdom
**Last updated:** 2026-04-26
**Source:** Case studies and practitioner accounts from second research round

## Real Production Results

| Company | Result | Caveat |
|---------|--------|--------|
| Axios | 300x speed improvement on well-defined projects | Applies to isolated projects, not complex enterprise work |
| Salesforce | 84% autonomous resolution, 9K→5K support staff | Pulling back — models omit directives beyond 8 instructions |
| Delivery Hero | AI = 130 senior engineers, 100+ merged PRs/day | 85% success rate — 15% still fail |
| Klarna | 700 human agents replaced | Customer service, not engineering |
| ServiceNow | 99% faster than human agents | L1 IT support, narrow scope |
| Cloudflare | 7 AI code reviewers, 131K review runs in 30 days | Specialized reviewers, not general-purpose |

## Success Rate Statistics

- **Single-task agents:** 54% success rate
- **Large-scale transformations:** 8% success rate
- **76% of 847 analyzed deployments failed** — not from model capability, but architectural foundations
- **86-89% of pilots never reach production** — root cause is orchestration failures, not model failures
- **The narrower the scope, the higher the success rate** — this is the single most reliable predictor

## The 10 Commandments of Production AI Agents

1. **"A 10-step workflow at 85% per-step accuracy succeeds only 20% of the time."** Error compounds exponentially. Need 98%+ per-step for 80% end-to-end.

2. **"Start with one agent that completes one cycle end-to-end. Then scale."** The #1 killer is deploying multiple agents before proving one works.

3. **"Context inconsistency — not architecture choice — is the primary reason multi-agent orchestration fails."**

4. **"Coordinators without termination conditions are the single largest source of runaway token spend."**

5. **"Systems without state persistence have 90% higher risk of total task failure on 4+ hour tasks."**

6. **"Multi-agent systems use 15x more tokens than standard chat."** Budget accordingly.

7. **"Running continuously does not equal working intelligently."** Optimize for meaningful action, not uptime.

8. **"Self-improvement only works in verifiable domains."** Code, math, optimization — yes. Creative, strategy — not reliably.

9. **"Knowledge retrieval quality is the differentiator, not storage."** Storage is solved; retrieval is not.

10. **"95% of AI initiatives fail to reach production — not because of model capability, but because of architectural robustness, governance, and integration."** (MIT)

## Practitioner Tips

- "Don't fix bugs yourself. Ask the AI to investigate, update docs explaining what went wrong, then fix." — knowledge compounds across sessions
- One team cut hallucination 60% by trimming system prompt from 2,400 to 380 tokens
- 80% of calls don't need the expensive model — route aggressively to cheap models
- Agents are "extremely bad at architecture" — use them for implementation, set architecture yourself
- "Do a retro at the end of each session. Ask 'What did you learn?' and persist to docs."
- Kill switches are not optional

## The 24/7 AI Myth
"People build elaborate architectures focused on uptime and responsiveness, optimizing for 'always on' while completely missing whether the agent is doing anything useful."

## Cost Reality

| Setup | Monthly Cost |
|-------|-------------|
| 7 agents (marketing, sales, research, content) | ~$200/mo |
| Hermes Agent personal use | $5-7/mo VPS + $2-15/mo API |
| Enterprise multi-agent | $3,200-13,000+/mo |
| Failed deployment average sunk cost | $150,000+ |

## Sources
- [847 AI Agent Deployments Analysis](https://medium.com/@neurominimal/i-analyzed-847-ai-agent-deployments-in-2026-76-failed-heres-why-0b69d962ec8b)
- [Axios CTO](https://www.axios.com/2026/02/15/ai-coding-tech-product-development)
- [CNBC Silent Failure at Scale](https://www.cnbc.com/2026/03/01/ai-artificial-intelligence-economy-business-risks.html)
- [Google 5 Lessons](https://developers.googleblog.com/production-ready-ai-agents-5-lessons-from-refactoring-a-monolith/)
- [Why AI Agents Keep Failing](https://www.roborhythms.com/why-ai-agents-keep-failing-2026/)
- [The 24/7 AI Myth](https://medium.com/@R.H_Rizvi/the-24-7-ai-myth-why-most-always-on-agents-are-just-expensive-chatbots-running-in-circles-584f67d104bb)
- [Cloudflare Internal Stack](https://blog.cloudflare.com/internal-ai-engineering-stack/)
