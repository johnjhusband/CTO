# Decision Log Index

| ID | Date | Technology | Action | Summary |
|----|------|-----------|--------|---------|
| CTO-DECISION-001 | 2026-04-26 | OpenClaw | Adopted | Selected over Hermes — macro evolution > micro evolution |
| CTO-DECISION-002 | 2026-04-26 | VPS-based testing | Adopted | Fresh Hetzner VPS, not Docker — system-level changes need real infrastructure |
| CTO-DECISION-003 | 2026-04-26 | Telegram Bot | Adopted | Primary comms — free, no phone, zero ban risk. WhatsApp deferred. |
| CTO-DECISION-004 | 2026-04-26 | Memory architecture | Adopted | Obsidian-compatible vault + SQLite (memweave) + tiered loading + filesystem MCP |
| CTO-DECISION-005 | 2026-05-11 | Two-hemisphere brain (OpenClaw + Hermes + A2A) | Adopted | Hermes added as right hemisphere alongside OpenClaw (left). A2A corpus callosum. Both halves on Codex OAuth via single ChatGPT Pro. Supersedes the framework-substitution scope of DECISION-001 but preserves OpenClaw as left hemisphere. |
| CTO-DECISION-006 | 2026-05-11 | Telegram removed; A2A is the comms layer | Adopted | Telegram removed entirely. A2A protocol carries hemisphere-to-hemisphere AND CTO-to-John traffic. Human interface built/exposed on top of A2A in a subsequent phase. Supersedes CTO-DECISION-003. |
| CTO-DECISION-008 | 2026-05-11 | LLM provider: ChatGPT Business (existing) via Codex OAuth | Adopted | Use John's existing $30/seat Business subscription via Codex OAuth on both hemispheres. Pro on a separate email is the documented escape if observed quotas constrain operation. Supersedes the Pro $200/mo scope of architecture-decisions-john.md #2. |
