# LLM Strategy
**L0:** **Both hemispheres on Codex OAuth via cto@husband.llc ChatGPT Pro/Business-compatible account; active model path is `openai-codex/gpt-5.5` for primary, fallback, session search, and compression.** Embeddings need separate OPENAI_API_KEY (pennies). OpenRouter is retired, not a fallback (CTO-DECISION-014/015). **Expected quota pressure based on prior OpenRouter pattern** — Pro/Business seat management is the documented escape, not PAYG Codex seats. `model.thinking` is NOT a valid config key — use `thinkingDefault`.
**L1:** CTO-DECISION-013 moved the active OAuth account to `cto@husband.llc` ChatGPT Pro. CTO-DECISION-014 removed OpenRouter across both hemispheres. CTO-DECISION-015 pinned Hermes auxiliary session-search and compression to `openai-codex/gpt-5.5` with 60s timeout because `gpt-5-mini` is blocked under ChatGPT-account Codex. Rollback, if Codex quotas constrain operation, is to restore the saved john@husband.llc Business Codex OAuth profile — same provider mechanism, different account — not to add PAYG Codex seats.
**Last updated:** 2026-05-25
**Verification:** Current active model/provider state cross-checked against CTO-DECISION-013/014/015 and install scripts.
**Source:** See `logs/decisions/CTO-DECISION-013.json`, `CTO-DECISION-014.json`, `CTO-DECISION-015.json`, and `scripts/install-cto.sh`.

## Key Facts
- CTO is **not locked to any single provider** architecturally, but the active no-spend install path uses Codex OAuth only.
- OpenRouter is retired and must not appear as an active install/config assignment.
- `openai-codex/gpt-5.5` is the active model for main, fallback, session-search, and compression paths.
- OpenAI API key is optional for embeddings only; it is not the primary LLM path.
- Historical OpenRouter research below is retained as archive/context, not current operating guidance.

## Historical OpenRouter Lessons [archive — no longer current operating guidance]
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

### Current approach: Codex OAuth first; provider switching remains architectural, not active config
Both hemispheres currently use Codex OAuth. Provider switching remains possible at the architecture level, but active install scripts intentionally avoid OpenRouter. This means CTO can later:
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
