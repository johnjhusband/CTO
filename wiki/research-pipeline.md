# Research Pipeline — How CTO Monitors the AI Landscape
**L0:** Multi-source ingestion → LLM scoring → dedup → autonomous decisions → Telegram digest → knowledge archive. Existing tools: Horizon, agents-radar.
**L1:** CTO autonomously monitors GitHub, HN, arXiv, YouTube, changelogs. Each item scored 0-10 by LLM against defined interests. Cross-platform deduplication. CTO acts on findings autonomously (adopt/reject/defer). Daily digest sent to Telegram. John reviews after the fact — corrections calibrate scoring. Open-source starting points: Horizon (MCP-native, most complete), agents-radar (GitHub Actions, zero infrastructure). Research methodology defined in SOUL.md. Evaluation framework: community consensus → production evidence → material vs immaterial → test on real infrastructure.
**Last updated:** 2026-04-26
**Verification:** Tool descriptions (Horizon, agents-radar, MINT Lab) from web research. Existence of repos not independently verified. Pipeline design is our own.
**Source:** Live web research (April 2026), second research round

## Key Facts
- Purpose-built tools already exist for AI landscape monitoring
- The pipeline that works in production: Ingest → Score → Deduplicate → Enrich → Human Curation → Distribute → Archive
- Most production systems use human curation checkpoints, but CTO operates fully autonomously with post-hoc review
- John reviews daily digest and corrects; corrections calibrate future scoring

## The Canonical Pipeline

```
Multi-source ingestion → LLM relevance scoring → Cross-platform deduplication →
Enrichment (summaries, context) → Autonomous decision (adopt/reject/defer) →
Distribution (Telegram daily digest) → Archive (knowledge base)
→ John reviews after the fact, corrections feed back into scoring calibration
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
3. **Post-hoc Correction** — CTO acts autonomously on its scoring. John reviews the daily digest and corrects bad calls. Corrections feed back into scoring calibration over time. Note: many production systems use human-in-the-loop, but our requirements demand full autonomy with after-the-fact review.

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
4. CTO autonomously acts on findings (adopt/reject/defer)
5. Daily digest to Telegram with decisions made and rationale
6. All findings flow into Obsidian knowledge base
7. John reviews digest, corrections calibrate future scoring

## Sources
- [MINT Lab guide](https://mintresearch.org/guide/)
- [Horizon GitHub](https://github.com/Thysrael/Horizon)
- [agents-radar GitHub](https://github.com/duanyytop/agents-radar)
- [auto-news GitHub](https://github.com/finaldie/auto-news)
- [AI Release Tracker GitHub](https://github.com/Femoon/ai-release-tracker)
- [Karpathy AutoResearch](https://github.com/karpathy/autoresearch)
