# Upgrade Cycle (Clone-Test-Replace via VPS)
**L0:** Provision fresh Hetzner VPS → deploy candidate → test on real infrastructure → snapshot current → promote or destroy. Not Docker.
**L1:** CTO never upgrades in-place. Each candidate version deploys to a fresh Hetzner VPS via API (not Docker — Docker can't test system-level changes). Full test suite runs on real infrastructure. If pass: snapshot production VPS, promote candidate, destroy old. If fail: iterate or destroy candidate with documented reason. Hetzner bills hourly (~EUR 0.02-0.05 per test run). Rollback from snapshot is one API call. Every version archived with snapshot ID + git tag + decision log.
**Last updated:** 2026-04-26
**Verification:** Hetzner API create/delete verified. VPS-based testing is our design decision. 'Research the target' step added from experience.
**Source:** PRD.md + architectural correction (Docker cannot test system-level changes)

## Key Facts
- CTO never upgrades in-place — always test on a fresh VPS first
- Each candidate version is deployed to a **new Hetzner VPS**, not a Docker container
- Docker cannot faithfully test system-level changes (packages, services, network, Docker itself)
- Every version is archived before replacement
- Failed upgrades are iterated on or abandoned with documentation
- Rollback is a first-class operation
- Hetzner API enables programmatic VPS provisioning and destruction

## Why VPS-Based Testing, Not Docker

CTO has full system-level access. Macro evolution can change anything:
- OS packages (`apt-get install`)
- System services (`systemd`)
- Network configuration
- Docker containers (Docker-in-Docker is fragile and unreliable)
- The agent framework itself
- Python/Node.js versions
- Cron jobs, firewall rules, SSH config

A Docker container cannot test any of these faithfully. Only a full VPS provides a true test environment that mirrors production.

**Cost:** Hetzner bills hourly. A test VPS running for 2 hours costs ~EUR 0.02-0.05. Destroy it after testing — no ongoing cost.

## The Cycle (Step by Step)

### 1. Discovery
- Research engine identifies a new technology, tool, or process
- Decision engine evaluates relevance and potential value

### 2. Research the Target
- BEFORE attempting installation or configuration of anything new, research:
  - What does the target platform expect? (file structure, conventions, config format)
  - What does its setup process ask for? (exact wizard steps, required inputs)
  - **What are ALL prerequisites and dependencies?** (runtime versions, API keys, external services, embedding models, database engines, other packages it depends on)
  - **For each dependency: do we have it? If not, what does IT need?** (recurse until the full dependency chain is mapped)
  - How does it integrate with existing components? (memory, tools, communication)
  - What are the known gotchas? (defaults that overwrite your files, missing dependencies, breaking changes)
- Map the target's requirements against our current architecture — identify gaps and conflicts BEFORE touching infrastructure
- This step prevents TWO patterns: (1) pressing forward without understanding what you're building on, and (2) discovering missing prerequisites during installation

*Origin: memweave was installed without knowing it needs an embedding API key or local embedding model. The research covered capabilities and configuration but not prerequisites.*

### 3. Provision
- CTO provisions a **new Hetzner VPS** via the Hetzner Cloud API
- Same specs as production (or configurable for testing different tiers)
- Fresh Ubuntu install, no prior state

### 4. Deploy Candidate
- CTO deploys the candidate version to the new VPS:
  - Clones the git repo
  - Applies the proposed changes (new packages, new framework, new config, etc.)
  - Installs all dependencies
  - Starts the agent

### 5. Test
- Full test suite runs on the candidate VPS:
  - All existing functionality still works (regression)
  - New capability functions correctly
  - Communication module works (can send test message)
  - Research engine works (can fetch and parse)
  - System-level integrations work (services, packages, cron)
  - Health check passes

### 6. Decide
- **Tests pass:** proceed to promotion
- **Tests fail:** iterate (fix and re-test on same candidate VPS) or abandon
- Decision is logged regardless of outcome

### 7. Handoff
- Outgoing CTO writes a HANDOFF.md for the incoming version:
  - What changed and why (the full reasoning, not just the diff)
  - What was learned during this version's operation
  - Mistakes made and corrections received from John
  - What to watch out for in the new version
  - Any open questions or deferred decisions
- This is the knowledge transfer mechanism. Without it, each new version starts without the context of why things are the way they are.

### 8. Archive
- Current production CTO is archived:
  - Hetzner VPS snapshot (one-click restore)
  - Git tag: `v{version}-archived-{date}`
  - Decision log entry written
  - HANDOFF.md committed with this version's context
  - Rollback instructions generated

### 9. Promote
- Candidate VPS becomes the new primary CTO
- DNS/IP updated if needed (or CTO migrates state to candidate)
- Old production VPS is destroyed (after confirming candidate is healthy)
- New CTO takes over all duties

### 10. Report
- User notified via Telegram Bot / Gmail fallback
- Report includes: what changed, why, test results, rollback instructions

## Rollback Procedure
1. Restore archived Hetzner snapshot to a new VPS (or re-provision from git tag)
2. Start the restored version
3. Verify health
4. Point traffic/state to restored VPS
5. Destroy the failed version's VPS
6. Log rollback in decision log

## Hetzner API Integration
- Provision VPS: `POST /servers` with server type, image, SSH key
- Create snapshot: `POST /servers/{id}/actions/create_image`
- Destroy VPS: `DELETE /servers/{id}`
- List snapshots: `GET /images?type=snapshot`
- API token stored securely in CTO's environment

## Relationships
- [Architecture](architecture.md) — where upgrade cycle fits
- [Decision Log Format](decision-log-format.md) — how upgrades are documented
- [Version Archive](version-archive.md) — storage and retrieval of versions

## Open Questions
- Hetzner API token provisioning — John must create and provide
- State migration strategy: how does CTO transfer memory/wiki/logs from old VPS to new?
- IP address handling: static IP that moves between VPS instances, or DNS update?
- Maximum test VPS lifetime before auto-destroy (cost guard)
