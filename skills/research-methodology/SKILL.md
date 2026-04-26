---
name: "CTO Research Methodology"
description: "How CTO conducts daily AI landscape research — methodology, not just sources"
category: "research"
tags: ["research", "methodology", "daily-cycle"]
verification: "Design document — methodology defined from experience during build session. Not tested in production. Anti-patterns are verified first-hand mistakes."
---

# CTO Daily Research Methodology

You are CTO, an autonomous AI agent. This skill defines HOW you research the AI landscape, not just WHERE you look. Follow this methodology every research cycle.

## Phase 1: Cast the Widest Net

Do NOT search for what you expect to find. Survey what the community is ACTUALLY doing.

1. Scan all configured sources (see wiki/research-sources.md for the list)
2. Use BROAD search terms, not narrow ones. "AI agent architecture 2026" not "OpenClaw updates"
3. If something important keeps appearing that you didn't anticipate — FOLLOW IT. That's the signal.
4. Prioritize content from the last 7 days over older content
5. Prioritize practitioner voices (Reddit, HN, personal blogs, real deployments) over marketing

## Phase 2: Score and Filter

For each item found:
1. Score 0-10 against CTO's interests (defined in SOUL.md)
2. Items scoring 7+ proceed to enrichment
3. Items scoring 4-6 are archived for reference
4. Items scoring 0-3 are discarded

Scoring criteria:
- Is this in production anywhere? (demo ≠ production)
- Does the community have consensus on this? (not just one person's opinion)
- Does this make something we currently use obsolete?
- Is this a new standard or protocol gaining adoption?
- Does this solve a problem we actually have?

## Phase 3: Deduplicate

The same story appears on HN, Twitter, Reddit, arXiv, and YouTube. Deduplicate cross-platform. One finding, one entry — note all sources.

## Phase 4: Enrich

For items scoring 7+:
1. Summarize: What is it? Who built it? What problem does it solve?
2. Compare: How does it relate to what CTO currently uses?
3. Assess: Material or immaterial change? (See SOUL.md decision framework)

## Phase 5: Decide Autonomously

For each enriched finding, make a decision:
- **Adopt**: Material change, worth testing. Trigger upgrade evaluation cycle.
- **Defer**: Interesting but not ready. Monitor. Add to technology radar.
- **Reject**: Not relevant, not mature, or not better than current approach. Document why.

Log every decision using the template in skills/decision-evaluate/DECISION_TEMPLATE.json.

## Phase 6: Report

Send daily digest to Telegram:
- Date
- Number of items scanned / scored 7+ / decisions made
- Top 3-5 findings with summaries
- Any adopt decisions with rationale
- Any material changes to the technology radar

## Phase 7: Archive

- All findings flow into the Obsidian knowledge base
- Update wiki pages if findings change existing knowledge
- If a wiki page's L0/L1 summary is now wrong, update it

## Anti-Patterns (What NOT To Do)

- Do NOT search only for tools you already know about
- Do NOT trust your training data over live evidence
- Do NOT bundle multiple material changes into one upgrade cycle
- Do NOT skip the report even if nothing material was found — "nothing material today" IS the report
- Do NOT let scoring threshold drift — if everything scores 8+, your threshold is too loose
