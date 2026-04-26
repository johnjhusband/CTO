# Research Pipeline — How CTO Monitors the AI Landscape
**Last updated:** 2026-04-26
**Source:** Live web research (April 2026), second research round

## Key Facts
- Purpose-built tools already exist for AI landscape monitoring
- The pipeline that works in production: Ingest → Score → Deduplicate → Enrich → Human Curation → Distribute → Archive
- Every production system includes a human curation checkpoint — full autonomy produces too many false positives
- "5 minutes of morning review replaces hours of manual tracking" (MINT Lab)

## The Canonical Pipeline

```
Multi-source ingestion → LLM relevance scoring → Cross-platform deduplication →
Enrichment (summaries, context) → Human curation checkpoint (5 min/day) →
Distribution (Telegram digest) → Archive (knowledge base)
```

## Existing Open-Source Tools

### Horizon (Most Complete)
- AI-powered news radar with LLM scoring (0-10 scale, configurable threshold)
- Cross-platform deduplication
- Web-researched context enrichment
- Collects HN/Reddit comments on stories
- Delivers via email, Slack, Discord, or GitHub Pages
- **Exposes pipeline steps as MCP tools** — agents can invoke fetch, score, filter, enrich, summarize individually
- [GitHub](https://github.com/Thysrael/Horizon)

### agents-radar (Lightest Weight)
- Daily AI ecosystem digest from 10 sources
- Runs entirely on **GitHub Actions** — zero server infrastructure
- GitHub Trending, ArXiv, HuggingFace, Product Hunt, Dev.to, Lobste.rs, HN, anthropic.com, openai.com
- Publishes as GitHub Issues tagged by type
- Telegram and Feishu notifications
- [GitHub](https://github.com/duanyytop/agents-radar)

### auto-news
- Personal news aggregator: Tweets, RSS, YouTube, Reddit, journal notes
- LLM filtering removes 80%+ noise
- Weekly top-k recaps
- Stores everything in Notion
- Docker with hourly pulls
- [GitHub](https://github.com/finaldie/auto-news)

### AI Release Tracker
- Monitors GitHub changelogs for AI coding tools
- Checks every 30 minutes via GitHub Actions
- Bilingual Telegram notifications
- [GitHub](https://github.com/Femoon/ai-release-tracker)

## Sources That Matter Most

Ranked by frequency across all production systems surveyed:

| Source | Signal Quality | Method |
|--------|---------------|--------|
| **arXiv** | Highest for research | API |
| **GitHub Trending** | Highest for tools/code | Scraping/API |
| **Hacker News** | High — community pre-filters | Algolia API |
| **Twitter/X** | High for breaking, noisy overall | API |
| **HuggingFace** | High for models/papers | API |
| **Reddit** (r/MachineLearning) | Medium | API |
| **YouTube** (AI channels) | Medium — good for deep dives | Browser-based for v1 |
| **Product Hunt** | Low-medium | API |
| **Bluesky** | Growing — researchers migrating | API |

## Signal Filtering (What Works)

1. **LLM Relevance Scoring** — Most common. Score each item 0-10 against defined interests, apply threshold.
2. **Community Pre-Filtering** — HN upvotes, GitHub stars, Reddit upvotes already act as pre-filters.
3. **Human-in-the-Loop** — Automated ingestion + scoring, human final call. This is what survives contact with reality.

## Evaluation Pipeline (How to Decide What to Adopt)

1. **Awareness** — Automated agents surface the tool
2. **Triage** — LLM summary: What is it? What problem? How mature? Who built it?
3. **Comparative Analysis** — Track against peer projects
4. **Hands-On Evaluation** — This is where automation currently breaks down. Closest: Karpathy AutoResearch pattern for measurable metrics.
5. **Adoption Decision** — Remains human for now. CTO reports recommendation, John decides on spending.

## Cross-Model Review
ARIS pattern: use Claude for execution, GPT for critical review. Avoids local minima of one model reviewing its own work. Different models catch different errors.

## Recommendation for CTO v1

1. Start with **agents-radar** pattern (GitHub Actions, zero infrastructure) or **Horizon** (more complete, MCP-native)
2. Browser-based YouTube for v1, transcript APIs for later
3. LLM scoring against CTO's defined interests
4. Daily digest to Telegram with top 5-10 items
5. John reviews in 5 minutes, thumbs-up/thumbs-down
6. Accepted items flow into Obsidian knowledge base
7. Evaluation pipeline for items marked "evaluate"

## Sources
- [MINT Lab guide](https://mintresearch.org/guide/)
- [Horizon GitHub](https://github.com/Thysrael/Horizon)
- [agents-radar GitHub](https://github.com/duanyytop/agents-radar)
- [auto-news GitHub](https://github.com/finaldie/auto-news)
- [AI Release Tracker GitHub](https://github.com/Femoon/ai-release-tracker)
- [Karpathy AutoResearch](https://github.com/karpathy/autoresearch)
