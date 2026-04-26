# Upgrade Cycle (Clone-Test-Replace)
**Last updated:** 2026-04-26
**Source:** PRD.md + live research on framework capabilities

## Key Facts
- CTO never upgrades in-place — always clone first
- Docker is the sandboxing mechanism for testing
- Every version is archived before replacement
- Failed upgrades are iterated on or abandoned with documentation
- Rollback is a first-class operation
- Both Hermes Agent and Agent Zero support Docker-native operation, making this cycle natural

## The Cycle (Step by Step)

### 1. Discovery
- Research engine identifies a new technology, tool, or process
- Decision engine evaluates relevance and potential value

### 2. Clone
- Current CTO is cloned into a Docker container
- Clone is an exact replica of the running CTO
- Clone has its own isolated environment

### 3. Integrate
- New capability is added to the clone
- This may involve: installing packages, modifying code, adding new modules, changing config, swapping LLM provider

### 4. Test
- Full test suite runs against the clone:
  - All existing functionality still works (regression)
  - New capability functions correctly
  - Communication module works
  - Research engine works
  - Upgrade cycle itself works (meta-test)

### 5. Decide
- **Tests pass:** proceed to promotion
- **Tests fail:** iterate (fix and re-test) or abandon
- Decision is logged regardless of outcome

### 6. Archive
- Current (soon-to-be-replaced) CTO is archived:
  - Git tag: `v{version}-archived-{date}`
  - Docker image saved: `cto:v{version}`
  - Decision log entry written
  - Rollback instructions generated

### 7. Promote
- Clone becomes the new primary CTO
- Old CTO container is stopped
- New CTO takes over the system root
- Health check confirms new CTO is operational

### 8. Report
- User notified via Telegram Bot (primary) / Gmail (fallback)
- Report includes: what changed, why, test results, rollback instructions

## Framework-Specific Notes

### If using Hermes Agent
- Hermes has built-in self-evolution via `hermes-agent-self-evolution` repo (DSPy + GEPA)
- Learning loop auto-creates skills from successful tasks
- **Caution:** No built-in safe upgrade mechanism yet. OpenClaw has the same gap (Issue #44876).
- Must build custom Docker orchestration for clone-test-replace

### If using Agent Zero
- Docker-native by design — agents already run in isolated containers
- Hierarchical agent spawning maps naturally to clone-test pattern
- Dynamic tool creation means the clone can create its own upgrade tools

## Rollback Procedure
1. Stop current CTO
2. Load archived Docker image for target version
3. Start archived version
4. Verify health
5. Log rollback in decision log

## Relationships
- [Architecture](architecture.md) — where upgrade cycle fits
- [Decision Log Format](decision-log-format.md) — how upgrades are documented
- [Version Archive](version-archive.md) — storage and retrieval of versions

## Open Questions
- Docker image size management — how many versions to keep locally vs push to registry
- Should CTO test the rollback procedure as part of every upgrade?
- Maximum iteration count before abandoning an upgrade
