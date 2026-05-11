# LLM Strategy
**L0:** **Both hemispheres on ChatGPT Pro $200/mo via Codex OAuth — single subscription, flat rate, no per-token billing.** Embeddings need separate OPENAI_API_KEY (pennies). OpenRouter retained as fallback. `model.thinking` is NOT a valid config key — use `thinkingDefault` only.
**L1:** As of CTO-DECISION-005 (2026-05-11), both OpenClaw (left hemisphere) and Hermes (right hemisphere) authenticate via the `openai-codex` provider against the same ChatGPT Pro $200/mo subscription. Verified at primary sources: docs.openclaw.ai/providers/openai (OpenClaw side, `openclaw models auth login --provider openai-codex --device-code` for headless VPS) and hermes-agent.nousresearch.com/docs/integrations/providers (Hermes side, device-code flow with `~/.hermes/auth.json` credential store, can import existing `~/.codex/auth.json` if present). Specialisation reduces per-token cost (orchestrator-worker 40-60% cheaper, tiered intelligence 87.4% cheaper, hierarchical 97.7% accuracy at 61% cost) — and with both hemispheres on a flat-rate subscription, per-token billing doesn't apply on the model side at all. Rate limits real but managed: Pro $200 = 20× Plus (25× promo through 2026-05-31). OpenRouter remains available as fallback if Codex OAuth is throttled or unavailable. CTO can evaluate and switch its own LLM backend as part of macro evolution.
**Last updated:** 2026-05-11
**Verification:** OpenRouter verified (API works, prepaid billing, model format). Codex OAuth verified at primary sources for both halves on 2026-05-11. Pricing claims from primary docs. Cost estimates are projections.
**Source:** Live web research 2026-05-11. See `hemisphere.md` Provider Strategy section and `wiki/codex-oauth-setup.md` for the full setup playbook.

## Key Facts
- CTO is **not locked to any single provider**
- Budget: $10/month OpenRouter key limit, $200/month ceiling acceptable [set by John]
- Using `openrouter/openrouter/auto` — OpenRouter picks best model per-request based on complexity [verified working]
- Fallback: `openrouter/google/gemini-2.5-flash` [verified]
- ~~ChatGPT Pro ($200/mo) is UI-only~~ WRONG — OpenAI explicitly allows subscription access through OpenClaw via Codex OAuth. $200/mo flat rate for CTO. [verified — OpenClaw docs, OpenRouter integration guide]
- OpenAI API is also available as separate pay-per-token (not needed — subscription works via OpenClaw)

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
- ~~Does NOT include API access~~ WRONG for OpenClaw — subscription works via Codex OAuth
- ~~Cannot be used programmatically~~ WRONG for OpenClaw — OpenAI explicitly allows this exception
- OpenClaw uses `openai-codex` provider to route through ChatGPT subscription [verified]

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
