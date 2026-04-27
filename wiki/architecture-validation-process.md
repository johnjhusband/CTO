# Architecture Validation Process
**L0:** Community-driven architecture validation — inventory community sentiment, categorize findings, hypothesize architecture, validate via research agents, iterate. Must run before every upgrade.
**L1:** CTO must not rely on training data or existing documentation to validate architecture. Every validation cycle starts fresh from community evidence. Process: (1) inventory what people are saying about autonomous AI in the last month, (2) categorize new features/technologies, (3) consider if they improve existing components, (4) hypothesize an updated architecture, (5) propose the architecture as questions to research agents to confirm/deny community sentiment, (6) iterate until validated, (7) only then clone-test-replace.
**Last updated:** 2026-04-26
**Verification:** Process design from build session experience. Not yet tested in production.

## Why This Exists

During the CTO build, factual verification caught wrong numbers (star counts, package names, config keys). But it missed a deeper problem: the architectural decisions themselves were never validated against community sentiment. The architecture was based on what research agents reported, which was based on training data supplemented by web search. Nobody asked: "Do practitioners who actually run these systems agree with these choices?"

Further, left to its own devices, CTO (like Claude before it) will heavily lean toward:
- Using whatever data it was trained on instead of the latest information
- Prioritizing components already mentioned in its own documentation
- Confirming its existing assumptions rather than challenging them

This process forces a pure community-driven analysis every time.

## The Process

### Step 1: Fresh Community Inventory
Do NOT start from existing documentation. Start from scratch:
- "What are people saying about autonomous AI agents in the last 30 days?"
- "What new tools, frameworks, or approaches appeared this month?"
- "What are practitioners complaining about?"
- "What are practitioners excited about?"
- "What did someone switch FROM and TO, and why?"

### Step 2: Categorize Findings
For each finding from Step 1:
- Is this a new technology/tool/approach?
- Is this an improvement to something we already use?
- Is this a criticism of something we depend on?
- Is this a failure report from a production deployment?
- Is this a paradigm shift that changes fundamental assumptions?

### Step 3: Hypothesize Updated Architecture
Based on Steps 1-2, draft what the architecture SHOULD look like if we were starting from scratch today. Do not anchor on the existing architecture. Ask: "If I had no existing system, what would I build based on what the community is doing right now?"

### Step 4: Validate via Research Agents
For each component of the hypothesized architecture, pose it as a question:
- "Is [component X] the right choice for [use case Y]? What does the community say?"
- "What are the criticisms of [component X]?"
- "What alternatives to [component X] are practitioners actually using?"
- "Has anyone reported problems with [component X] in production?"

Run these as parallel research agents. Require source URLs.

### Step 5: Iterate
If validation reveals problems:
- Revise the hypothesis
- Re-validate the changed components
- Repeat until the architecture is confirmed by community sentiment

### Step 6: Compare to Current
Only now compare the validated architecture to what's currently running:
- What changed?
- Is the change material? (Per SOUL.md decision framework)
- If material: trigger clone-test-replace cycle
- If not material: document the validation and move on

### Step 7: Clone-Test-Replace (if needed)
Only after the new architecture is validated by community sentiment should CTO provision a test VPS and attempt the upgrade.

## Integration with Upgrade Cycle

This process IS the "Research the Target" step in the upgrade cycle, expanded. The upgrade cycle Step 2 now references this document:

```
Step 2: Validate architecture against community sentiment
(See wiki/architecture-validation-process.md)
```

## Anti-Patterns
- Starting from existing documentation instead of fresh community evidence
- Confirming existing choices instead of challenging them
- Using training data as the primary source
- Skipping the hypothesis step (going straight from research to implementation)
- Validating only the components you're changing instead of the whole architecture
- Running validation only when you think something needs changing (run it regularly)

## Relationships
- [Upgrade Cycle](upgrade-cycle.md) — this process is Step 2 expanded
- [Research Pipeline](research-pipeline.md) — daily research feeds into this
- [SOUL.md](../SOUL.md) — metacognition principles govern this process
