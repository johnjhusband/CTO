# LLM Strategy
**L0:** OpenRouter Auto model picks best model per-request. $10/month key limit. Heartbeat costs add up (48 calls/day). `model.thinking` is NOT a valid config key — use `thinkingDefault` only.
**L1:** CTO uses OpenRouter for multi-model routing — single API key, 200+ models. GPT-5.4 nano ($0.10/$0.40/M) for routine research scoring, GPT-5.4 mini ($0.75/$4.50/M) for evaluation, o4-mini ($1.10/$4.40/M) for complex decisions. Estimated $5-30/month. ChatGPT Pro ($200/mo) is UI-only, no API access. CTO can evaluate and switch its own LLM backend as part of macro evolution. Prompt caching (90% discount) and batch processing (50% discount) for cost optimization.
**Last updated:** 2026-04-26
**Verification:** OpenRouter verified (API works, prepaid billing, model format). Pricing claims from OpenRouter website. Cost estimates are projections.
**Source:** Live web research (April 2026) — all data verified via web search

## Key Facts
- CTO is **not locked to any single provider**
- Budget: $10/month OpenRouter key limit, $200/month ceiling acceptable [set by John]
- Using `openrouter/openrouter/auto` — OpenRouter picks best model per-request based on complexity [verified working]
- Fallback: `openrouter/google/gemini-2.5-flash` [verified]
- ChatGPT Pro ($200/mo) is UI-only, does NOT include API access
- OpenAI API is separate, pay-per-token

## Lessons Learned from Installation [verified — all happened]
- **$1 free credit is insufficient** — Claude Sonnet burns through it in ~10 messages
- **Heartbeat costs add up** — 48 calls/day at 30-min intervals. Use cheapest model for heartbeat.
- **`model.thinking` is NOT a valid config key** — crashes the gateway. Use `thinkingDefault: "adaptive"` at the agent defaults level instead.
- **OpenRouter model IDs must be exact** — `google/gemini-2.0-flash` doesn't exist, it's `google/gemini-2.0-flash-001`
- **OpenRouter Auto** (`openrouter/openrouter/auto`) routes to cheapest effective model automatically
- **Key limit vs account balance are different** — key can have $1 limit even with $10 in account. Set at openrouter.ai/settings/keys.

## ChatGPT Pro ($200/mo) — What It Actually Includes
- Access to GPT-5.5, GPT-5.5 Pro, o1 Pro mode via web/mobile/desktop UI
- 20x higher rate limits than Plus
- 250 Deep Research runs/month
- Expanded Codex agent access (20x Plus usage)
- **Does NOT include API access** — API is separate billing
- **Cannot be used programmatically by an autonomous agent**
- OpenAI Codex (included) has `codex exec --json` for programmatic use — potential path

## OpenAI API Pricing (April 2026)

| Model | Input/1M tokens | Output/1M tokens | Notes |
|-------|-----------------|-------------------|-------|
| GPT-5.5 | $5.00 | $30.00 | Frontier, just released |
| GPT-5.4 | $2.50 ($0.25 cached) | $15.00 | 1.05M context |
| GPT-5.4 mini | $0.75 | $4.50 | Best cost/performance |
| GPT-5.4 nano | ~$0.10 | ~$0.40 | Cheapest |
| o3 | $2.00 | $8.00 | Reasoning |
| o4-mini | $1.10 | $4.40 | Cost-effective reasoning |
| GPT-4.1 | $2.00 | $8.00 | 1M context |

**Cost-saving options:** Prompt caching (up to 90% off input), Batch API (50% off), Flex processing (50% off). Combined 70-85% savings achievable.

## Anthropic API Pricing (April 2026)
| Model | Input/1M tokens | Output/1M tokens |
|-------|-----------------|-------------------|
| Haiku 4.5 | $1.00 | $5.00 |
| Sonnet 4.6 | $3.00 | $15.00 |
| Opus 4.6 | $5.00 | $25.00 |

## Provider Strategy for CTO

### Approach: Multi-model via OpenRouter or LiteLLM
Both Hermes Agent and Agent Zero support routing to any provider. This means CTO can:
1. Use cheap models (GPT-5.4 nano, o4-mini) for routine daily research
2. Escalate to stronger models (GPT-5.4, Claude Sonnet) for complex decisions
3. Switch providers without code changes
4. Stay within budget by routing 90% of work through cheap models

### Cost Estimate (daily CTO operation)
- Daily research cycle: ~50K-200K tokens → $0.05-$0.90 (GPT-5.4 mini)
- Decision evaluation: ~10K-50K tokens → $0.01-$0.25
- Communication formatting: minimal
- **Estimated monthly: $5-30 for LLM API costs** (varies with model choice and volume)

## Relationships
- [Architecture](architecture.md) — LLM is the brain of each component
- [Research Sources](research-sources.md) — Gemini for YouTube summarization

## Sources
- [OpenAI API Pricing](https://openai.com/api/pricing/)
- [ChatGPT Plans](https://chatgpt.com/pricing/)
- [Anthropic Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- [OpenRouter](https://openrouter.ai/)
