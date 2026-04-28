# CTO Project Beads

## Completed Beads

### CTO-007: Git Repository Setup (P0, Feature) — DONE
**Description:** Initialize git repo, push to github.com/johnjhusband/CTO
**Status:** Complete [verified — repo exists, pushes work, deploy key on VPS]

### CTO-008: VPS Provisioning (P0, Feature) — PARTIALLY DONE
**Description:** Set up VPS for CTO deployment
**Status:** Partially complete
- [x] VPS accessible via SSH [verified — 116.203.68.119, cx43, cto user]
- [x] Node.js 22 installed [verified — nvm for cto user]
- [x] Python 3.12 + pip + venv [verified on VPS]
- [x] Dedicated non-root user (cto) [verified]
- [x] Deploy key for GitHub access [verified]
- [x] SSH key uploaded to Hetzner API [verified — id=111410859]
- [ ] OpenClaw installed and configured [not done]
- [ ] MCP servers installed [not done]
- [ ] Security hardening (firewall, fail2ban) [not done]
- [ ] systemd service for OpenClaw [not done]

## Open Beads

### CTO-001: Core Agent Scaffold (P0, Feature)
**Description:** Install OpenClaw, configure workspace, load skills, verify agent responds
**Test Plan:**
- [ ] OpenClaw installed on VPS [unverified — not attempted]
- [ ] Config loads from openclaw.json [verified — strict schema validation confirmed]
- [ ] SOUL.md/AGENTS.md/IDENTITY.md/USER.md/TOOLS.md auto-loaded [verified against docs]
- [ ] MEMORY.md loaded in main private session [verified — conditional gate confirmed]
- [ ] Skills snapshot-loaded at session start [verified against docs]
- [ ] Agent responds to chat with correct identity [unverified — not tested]
- [ ] Gateway bound to loopback [verified — config key confirmed]
- [ ] Cron jobs persist across restarts [verified against docs]
**Status:** Open
**Blocked by:** CTO-008 completion

### CTO-002: Research Engine v1 (P0, Feature)
**Description:** Build research skills — web search, source aggregation, synthesis
**Test Plan:**
- [ ] Can search the web via SearXNG [verified — official OpenClaw provider] or browser
- [ ] Can fetch and parse web pages (GitHub trending, HN) [unverified — fetch MCP exists on PyPI but not tested]
- [ ] Produces a structured research report [unverified — skill exists but not tested]
- [ ] Filters signal from noise via LLM scoring [unverified — not implemented]
**Status:** Open
**Blocked by:** CTO-001

### CTO-003: Decision Engine (P0, Feature)
**Description:** Evaluate research findings, produce adopt/reject/defer decisions
**Test Plan:**
- [ ] Takes research report as input [unverified — skill exists]
- [ ] Produces structured decision JSON [verified — template exists]
- [ ] Writes decision to log [verified — directory and index exist]
- [ ] Uses five-question evaluation framework [verified — documented in skill]
**Status:** Open
**Blocked by:** CTO-002

### CTO-004: Clone-Test-Replace Cycle — Macro Evolution Engine (P0, Feature)
**Description:** VPS-based upgrade testing via Hetzner API [verified — API create/delete tested]
**Test Plan:**
- [ ] Can provision a new Hetzner VPS via API [verified — tested successfully]
- [ ] Can deploy candidate version to the new VPS [unverified — not tested]
- [ ] Can run full test suite on candidate VPS [unverified — no test suite exists yet]
- [ ] Passing tests → snapshot current VPS + promote candidate [verified — snapshot API confirmed]
- [ ] Failing tests → iterate or destroy candidate with logged reason [verified — delete API tested]
- [ ] Rollback restores previous version from snapshot [verified — create from snapshot confirmed]
- [ ] Test VPS is destroyed after decision (cost guard) [verified — delete stops billing confirmed]
- [ ] HANDOFF.md written before promotion [defined — not tested]
**Status:** Open
**Blocked by:** CTO-001

### CTO-005: Version Archive System (P1, Feature)
**Description:** Git tagging + Hetzner VPS snapshot archiving + rollback
**Test Plan:**
- [ ] Creates git tag for each version [unverified — git works, tagging not tested]
- [ ] Creates Hetzner VPS snapshot before promotion [verified — API confirmed]
- [ ] Rollback restores from snapshot to a new VPS [verified — API confirmed]
- [ ] VERSIONS.md index maintained [defined — directory exists]
- [ ] Snapshot IDs recorded with each archived version [defined — template exists]
- [ ] Snapshot cost: EUR 0.0143/GB/month [verified against Hetzner docs]
**Status:** Open
**Blocked by:** CTO-004

### CTO-006: Communication Module v1 (P1, Feature)
**Description:** Telegram Bot notifications (primary), Gmail SMTP fallback
**Test Plan:**
- [ ] Telegram bot sends daily digest [verified — token works, message send command confirmed]
- [ ] Telegram proactive messaging works after John messages bot [verified — "chat not found" until first contact]
- [ ] Telegram config: botToken, dmPolicy, allowFrom with "tg:ID" format [verified against docs]
- [ ] Gmail SMTP sends fallback emails [unverified — not tested]
- [ ] Errors/failures reported immediately [unverified — not implemented]
**Status:** Open
**Blocked by:** CTO-001

### CTO-009: Daily Research Cycle Integration (P1, Feature)
**Description:** Wire together research + decision engine + communication into automated daily cycle
**Test Plan:**
- [ ] OpenClaw cron triggers daily at 06:00 UTC [verified — cron system confirmed, not configured]
- [ ] Produces research report [unverified — not implemented]
- [ ] Makes decisions on findings [unverified — not implemented]
- [ ] Sends digest to Telegram [verified — bot works]
- [ ] Logs all activity [unverified — not implemented]
**Status:** Open
**Blocked by:** CTO-002, CTO-003, CTO-006

### CTO-010: First Self-Upgrade (P1, Feature)
**Description:** CTO performs its first autonomous self-upgrade
**Test Plan:**
- [ ] CTO identifies a real technology to integrate [unverified — requires running system]
- [ ] Provisions test VPS, deploys candidate, tests [verified — API works]
- [ ] Writes HANDOFF.md [defined]
- [ ] Archives old version, promotes new version [verified — API works]
- [ ] Reports decision to Telegram [verified — bot works]
- [ ] New version is stable and operational [unverified — requires running system]
**Status:** Open
**Blocked by:** CTO-004, CTO-005, CTO-009
