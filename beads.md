# CTO Project Beads

## Open Beads

### CTO-001: Core Agent Scaffold (P0, Feature)
**Description:** Build the base CTO agent — scheduler, config, logging, Docker-based self-test infrastructure
**Test Plan:**
- [ ] Agent starts and reaches healthy state
- [ ] Config loads from file
- [ ] Logger writes to persistent log
- [ ] Daily scheduler triggers at configured time
- [ ] Docker is accessible from agent
**Status:** Open

### CTO-002: Research Engine v1 (P0, Feature)
**Description:** Build the research module — YouTube transcript extraction, web scraping, source aggregation
**Test Plan:**
- [ ] Can extract transcript from a YouTube video
- [ ] Can fetch and parse a web page (GitHub trending, HN)
- [ ] Produces a structured research report
- [ ] Filters signal from noise (basic heuristics)
**Status:** Open
**Blocked by:** CTO-001

### CTO-003: Decision Engine (P0, Feature)
**Description:** Evaluate research findings against current capabilities, produce adopt/reject/defer decisions
**Test Plan:**
- [ ] Takes research report as input
- [ ] Produces structured decision JSON
- [ ] Writes decision to log
- [ ] Correctly identifies relevant vs irrelevant findings
**Status:** Open
**Blocked by:** CTO-002

### CTO-004: Clone-Test-Replace Cycle — Macro Evolution Engine (P0, Feature)
**Description:** Implement the self-upgrade cycle using Docker — clone CTO, apply upgrade (which may be revolutionary architectural change), test, promote or discard. This is the macro evolution engine: research-driven changes that can replace core components (framework, LLM, memory system, comms stack).
**Test Plan:**
- [ ] Can clone current CTO into Docker container
- [ ] Can apply a code change to the clone (including major component swaps)
- [ ] Can run test suite inside clone
- [ ] Passing tests → archive current + promote clone
- [ ] Failing tests → iterate or abandon with logged reason
- [ ] Rollback restores previous version
**Status:** Open
**Blocked by:** CTO-001

### CTO-005: Version Archive System (P1, Feature)
**Description:** Git tagging, Docker image archiving, rollback capability
**Test Plan:**
- [ ] Creates git tag for each version
- [ ] Saves Docker image for each version
- [ ] Rollback command restores any archived version
- [ ] Version index is maintained and accurate
**Status:** Open
**Blocked by:** CTO-004

### CTO-006: Communication Module v1 (P1, Feature)
**Description:** Email notifications via Gmail SMTP (phase 1), then WhatsApp (phase 2)
**Test Plan:**
- [ ] Sends email to johnjhusband@gmail.com via SMTP
- [ ] Email contains daily research digest
- [ ] Email contains upgrade decision details
- [ ] Errors/failures are reported immediately
**Status:** Open
**Blocked by:** CTO-001

### CTO-007: Git Repository Setup (P0, Feature)
**Description:** Initialize git repo, push to github.com/johnjhusband/CTO, set up CI basics
**Test Plan:**
- [ ] Repo exists on GitHub
- [ ] Code pushes successfully
- [ ] README describes project purpose
**Status:** Open

### CTO-008: VPS Provisioning (P0, Feature)
**Description:** Set up VPS for CTO deployment — Docker, Python/Node, system access
**Test Plan:**
- [ ] VPS accessible via SSH
- [ ] Docker installed and running
- [ ] CTO agent deploys and starts
- [ ] Cron/systemd triggers daily research cycle
**Status:** Open

### CTO-009: Daily Research Cycle Integration (P1, Feature)
**Description:** Wire together research engine + decision engine + communication into automated daily cycle
**Test Plan:**
- [ ] Runs automatically every 24 hours
- [ ] Produces research report
- [ ] Makes decisions on findings
- [ ] Sends summary to user
- [ ] Logs all activity
**Status:** Open
**Blocked by:** CTO-002, CTO-003, CTO-006

### CTO-010: First Self-Upgrade (P1, Feature)
**Description:** CTO performs its first autonomous self-upgrade — end-to-end validation of the entire system
**Test Plan:**
- [ ] CTO identifies a real technology to integrate
- [ ] Clones itself, applies upgrade, tests
- [ ] Archives old version, promotes new version
- [ ] Reports decision to user
- [ ] New version is stable and operational
**Status:** Open
**Blocked by:** CTO-004, CTO-005, CTO-009
