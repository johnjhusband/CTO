# Architecture Validation Questions — Exhaustive List
**Last updated:** 2026-04-26
**Purpose:** Every architectural assumption posed as a question for community validation

## Framework Choice: OpenClaw
1. Is OpenClaw actually the right framework for an autonomous self-improving agent in April 2026?
2. What are practitioners who USE OpenClaw in production complaining about?
3. What are practitioners switching AWAY from OpenClaw to, and why?
4. Are there new frameworks in the last 30 days that weren't in our research?
5. Is OpenClaw's security posture improving or getting worse?
6. Has the OpenClaw Foundation (non-profit governance) been effective since Steinberger left for OpenAI?
7. Is OpenClaw's plugin/skill architecture actually loosely coupled in practice, or does it create hidden dependencies?

## Five-Layer Architecture Model
8. Is the "five-layer" model (Brain/Hands/Memory/Spine/Guardrails) actually community consensus, or did a few blog posts coin it?
9. Are there competing architectural models that practitioners prefer?
10. What architectural patterns are people using for autonomous agents that DON'T follow this model?
11. Is the layered model the right abstraction, or is something else (graph-based, event-driven, pipeline) better?

## Memory Layer
12. Is Obsidian-compatible vault + SQLite actually what production agents use for memory?
13. Is memweave the right SQLite coordination tool, or are there better alternatives?
14. Is tiered loading (L0/L1/L2) actually adopted in practice, or is it theoretical?
15. Does the OpenViking pattern work in real deployments?
16. Are people using graph memory (Mem0, Zep) in production, or is it still experimental?
17. What memory architecture are the most successful production agents using RIGHT NOW?
18. Is the "markdown source of truth + SQLite derived index" pattern actually better than just using a database?

## Tools Layer: MCP
19. Is MCP actually universal, or is it primarily an Anthropic ecosystem tool?
20. Are people having integration problems with MCP servers in production?
21. What are the criticisms of MCP that practitioners voice?
22. Are there alternatives to MCP gaining traction?

## Communication: Telegram
23. Is Telegram the right choice for agent-to-human notifications, or are people using something else?
24. What are the downsides of Telegram that practitioners have found?
25. Are there better notification patterns than "send a Telegram message"?

## LLM Provider: OpenRouter
26. Is OpenRouter reliable in production for autonomous agents?
27. What are the criticisms of OpenRouter?
28. Are people having issues with OpenRouter's multi-model routing?
29. Is the "route 80% to cheap models" strategy actually working in practice?

## Upgrade Cycle: VPS-Based Testing
30. Is VPS-based clone-test-replace actually better than Docker for self-upgrading agents?
31. Are there agents that successfully self-upgrade, and what approach do they use?
32. Is Hetzner the right VPS provider for this use case?
33. Is the cost of VPS-based testing justified vs Docker?

## Research Pipeline
34. Is SearXNG the right web search approach for an AI research agent?
35. Is the daily research cycle the right cadence, or should it be more/less frequent?
36. Are Horizon and agents-radar actually good tools, or are there better ones?
37. How do the most effective AI research agents actually monitor the landscape?

## Autonomy Model
38. Is full autonomy with post-hoc review actually workable, or do all production agents need guardrails?
39. What are the failure modes specific to fully autonomous agents?
40. How do others balance autonomy vs oversight for agents with system access?

## Self-Improvement
41. Is self-improvement (the CTO upgrading itself) actually working anywhere in production?
42. What are the risks of self-improving agents that practitioners have discovered?
43. Is the Karpathy Loop / AutoResearch pattern the right model for self-improvement?

## Overall Approach
44. Is building a single "AI CTO" agent the right approach, or are people finding that specialized agents work better?
45. Are there fundamentally different approaches to "keeping up with AI" that we haven't considered?
46. What are people saying about the "AI employee" concept — hype or reality?
47. Is OpenClaw + OpenRouter + Telegram + Hetzner a stack anyone else is running, or are we assembling something novel and untested?

## Integration Concerns
48. Has anyone integrated OpenClaw with MCPVault successfully?
49. Has anyone integrated OpenClaw with memweave or similar SQLite memory?
50. Has anyone run OpenClaw with SearXNG for research?
51. Does the OpenClaw + OpenRouter integration actually work smoothly in practice?
52. Are there known incompatibilities between any of our chosen components?
