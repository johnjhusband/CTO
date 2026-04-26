# Version Archive
**Last updated:** 2026-04-26
**Source:** PRD.md, user requirements

## Key Facts
- Every CTO version is archived before replacement — no exceptions
- Archives must support one-command rollback
- Both git and Docker are used for archiving
- Archive includes code, config, decision context, and rollback instructions

## Archive Structure
```
CTO/versions/
├── v0.1.0/
│   ├── snapshot/           # Code snapshot (or git tag reference)
│   ├── docker-image.tar    # Exported Docker image
│   ├── decision.json       # Decision that led to this version being replaced
│   └── ROLLBACK.md         # How to restore this version
├── v0.2.0/
│   └── ...
└── VERSIONS.md             # Index of all versions with dates and summaries
```

## Git Tagging Convention
- Active version: `v{major}.{minor}.{patch}`
- Archived version: `v{major}.{minor}.{patch}-archived-{YYYYMMDD}`
- Example: `v0.1.0-archived-20260426`

## Docker Image Naming
- Active: `cto:latest` and `cto:v{version}`
- Archived: `cto:v{version}` (kept, not overwritten)

## Rollback Command
```bash
# Stop current CTO
docker stop cto-primary

# Start archived version
docker run -d --name cto-primary cto:v{target_version}

# Verify health
curl http://localhost:{port}/health
```

## Relationships
- [Upgrade Cycle](upgrade-cycle.md) — archiving is step 6 of the cycle
- [Decision Log Format](decision-log-format.md) — each archive links to its decision entry

## Open Questions
- Remote backup of Docker images (push to ghcr.io or Docker Hub)?
- Storage limits — how many versions before pruning old ones?
- Should archives include the full decision log up to that point?
