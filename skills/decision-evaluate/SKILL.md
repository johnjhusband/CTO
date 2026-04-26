---
name: "CTO Decision Evaluation"
description: "How CTO evaluates research findings and makes adopt/reject/defer decisions"
category: "evaluation"
tags: ["decision", "evaluation", "upgrade"]
verification: "Design document — five-question framework defined during build session. Template verified (4 entries created). Not tested in autonomous operation."
---

# CTO Decision Evaluation

You are CTO. When a research finding scores 7+ in the daily research cycle, evaluate it using this framework.

## The Five Questions

Answer each before making a decision:

### 1. What is the community actually saying?
Not the vendor — the practitioners. Search Reddit, HN, personal blogs for real opinions. If only the vendor is talking about it, that's a red flag.

### 2. Is it in production anywhere?
Demo ≠ production. Look for:
- Real case studies with numbers (not "up to X% improvement")
- Practitioners reporting actual usage duration (weeks/months, not "I tried it")
- Known companies using it
- Failure stories (they reveal more than success stories)

### 3. What does it make obsolete?
If the answer is "nothing CTO currently uses," it might not be material. Material changes make a current component obsolete or significantly inferior. Map the finding to CTO's five-layer architecture — which layer does it affect?

### 4. What's the cost of switching vs. staying?
Include:
- Migration effort (not just the new tool's features)
- Risk of the switch failing
- What we lose from the current approach
- Ongoing cost difference

### 5. Can I test it on real infrastructure?
If it can't be deployed to a fresh Hetzner VPS and validated with the test suite, it's not ready for adoption. Theoretical benefits don't count.

## Decision Categories

### ADOPT
- Material change with production evidence
- Makes a current component obsolete or significantly worse
- Can be tested on real infrastructure
- Cost of switching is justified by the improvement
- **Action:** Log decision, provision test VPS, begin clone-test-replace cycle

### DEFER
- Interesting but one or more of:
  - Too new (no production evidence yet)
  - Not clearly better than current approach
  - Would require changes we're not ready for
- **Action:** Log decision, add to technology radar, re-evaluate in 7-30 days

### REJECT
- Not relevant to CTO's mission
- Not mature enough for production
- Not better than current approach
- Hype without substance
- **Action:** Log decision with rationale. Don't re-evaluate unless landscape changes.

## Decision Log

Write every decision to `logs/decisions/CTO-DECISION-{NNN}.json` using the template in this directory.
Update `logs/decisions/INDEX.md` with a one-line summary.
Report the decision in the daily Telegram digest.
