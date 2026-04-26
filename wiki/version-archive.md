# Version Archive
**Last updated:** 2026-04-26
**Source:** PRD.md, upgrade cycle architectural correction

## Key Facts
- Every CTO version is archived before replacement — no exceptions
- Archives must support rapid rollback
- Both Hetzner snapshots and git tags are used for archiving
- Archive includes full VPS state, code, config, decision context, and rollback instructions

## Archive Strategy

### Primary: Hetzner VPS Snapshots
- Before promoting a candidate, snapshot the current production VPS
- Snapshot captures entire disk state (OS, packages, config, data, everything)
- Restore by creating a new VPS from the snapshot
- Hetzner snapshot pricing: EUR 0.012/GB/month

### Secondary: Git Tags
- Every version tagged in git: `v{major}.{minor}.{patch}`
- Archived versions tagged: `v{major}.{minor}.{patch}-archived-{YYYYMMDD}`
- Git repo contains: agent code, skills, config templates, test suite, wiki, docs
- Does NOT contain: secrets, API keys, runtime state, VPS snapshots

### Decision Log Entry
- Each archive links to its decision log entry explaining what changed and why
- Stored in `logs/decisions/CTO-DECISION-{NNN}.json`

## Archive Structure (in git)
```
CTO/
├── versions/
│   ├── VERSIONS.md             # Index of all versions with dates, summaries, snapshot IDs
│   ├── v0.1.0/
│   │   ├── decision.json       # Decision that led to this version being replaced
│   │   ├── ROLLBACK.md         # How to restore this version
│   │   └── snapshot-id.txt     # Hetzner snapshot ID for full VPS restore
│   ├── v0.2.0/
│   │   └── ...
```

## Git Tagging Convention
- Active version: `v{major}.{minor}.{patch}`
- Archived version: `v{major}.{minor}.{patch}-archived-{YYYYMMDD}`

## Rollback Command
```bash
# Option 1: Restore from Hetzner snapshot (fastest, full state)
hcloud server create --name cto-rollback --type cx33 --image <snapshot-id> --ssh-key cto-deploy

# Option 2: Fresh VPS + deploy from git tag (clean but requires setup)
hcloud server create --name cto-rollback --type cx33 --image ubuntu-24.04 --ssh-key cto-deploy
# Then deploy the tagged version via the setup scripts
```

## Relationships
- [Upgrade Cycle](upgrade-cycle.md) — archiving is part of the cycle
- [Decision Log Format](decision-log-format.md) — each archive links to its decision entry

## Open Questions
- Snapshot retention policy — how many versions before pruning old snapshots?
- Should archives include a full memory/wiki export in git (in addition to snapshot)?
- Hetzner snapshot storage cost at scale (EUR 0.012/GB/month × snapshot size × count)
