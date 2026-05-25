# Clone Strategy and Hermes Implementation Handoff — 2026-05-25

Owner: OpenClaw (strategy/routing/final authority)
Implementer: Hermes (execution/right hemisphere) once Hermes agrees with this strategy
Human authority: John Husband, PWA instruction 2026-05-25T05:13Z

## Strategic intent
Build a parity clone of the current CTO stack on a fresh Hetzner VPS. This is clone-test-replace infrastructure rehearsal and parity validation only. It is not an improvement cycle.

## Non-negotiable constraints
- Do not delete, stop, or replace the original production CTO/OpenClaw system.
- The clone must boot in TEST MODE.
- TEST MODE must prevent autonomous clone/replacement/self-evolution promotion behavior until John explicitly retires the original.
- The clone must use distinct host identity, session keys, PWA identity/chat namespace, A2A namespace, service names where needed, and logs/artifact paths so it cannot contaminate production state.
- The clone must not post into the production PWA chat before promotion; any human-facing endpoint should be isolated or disabled unless explicitly needed for John's test.
- Credential parity is authorized by John, but credential values must not be written into docs, memory, shared memory, chat, or logs. Transfer/configure them securely from existing environment/config files with restrictive permissions.
- Hetzner spend is authorized only after both hemispheres agree. This document is OpenClaw's agreement; Hermes should explicitly record agreement before provisioning.
- Failed candidate VPS destruction is authorized automatically with no iteration cap for this cycle, but capture candidate ID, failure reason, and useful logs before destroying.
- A successful clone is parity only, not an improvement. Improvements are a later phase after John + Hermes review OpenClaw recommendations.

## Architecture
1. Provision a fresh Hetzner candidate VPS in the CTO project with labels identifying it as a clone candidate and test mode.
2. Install/deploy the current CTO stack from the canonical repository and current deployment scripts.
3. Restore/copy required runtime state for parity: OpenClaw config, Hermes config, Codex OAuth/auth state, PWA service config, A2A sidecar config, memory/wiki/decision logs, and required environment secrets.
4. Rewrite/override candidate-specific identity and safety values: hostname, service env, PWA namespace, A2A agent-card identity, callback URLs, session/chat keys, and any production-facing delivery toggles.
5. Add/verify a TEST_MODE gate before any clone/replacement/evolution behavior can run.
6. Run validation gates: systemd services healthy, OpenClaw responds, Hermes gateway responds, A2A delegation works, PWA/backend health works in isolated mode, memory/wiki readable, no production chat posting, no unintended outbound actions.
7. Produce candidate HANDOFF.md with exact changes, secrets-handling method without values, tests run, failures, rollback/destroy path, and what John should test in the morning.
8. If any gate fails: preserve logs, destroy candidate, iterate with a new candidate until fixed.

## Hermes scoped task
Hermes should execute the candidate build loop, not make strategic policy changes. If Hermes finds a need to change OpenClaw/Hermes framework source, create a backlog/decision recommendation instead of silently forking. Small deployment/script/config fixes inside the CTO repo are allowed when needed for the clone test, but must be documented and verified.

## Completion definition
Done means one running candidate VPS exists, in TEST MODE, with a HANDOFF.md and a concise morning report for John, and all failed candidates have been destroyed after evidence capture. If no successful candidate exists by John's morning test window, report the best surviving blocker with candidate logs/artifacts and destroyed candidate history.
