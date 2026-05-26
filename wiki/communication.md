# Communication Module
**L0:** **A2A protocol** is the communication layer (CTO-DECISION-006, 2026-05-11). Hemisphere-to-hemisphere AND CTO-to-John traffic. Human-facing interface built/exposed on top of A2A — implementation in a subsequent phase. **Telegram and Gmail SMTP removed** from the architecture.
**L1:** A2A (Agent-to-Agent, Linux Foundation, 150+ orgs in production) is the unified comms protocol. Same wire format already chosen as the corpus callosum between OpenClaw and Hermes (CTO-DECISION-005) carries CTO-to-John traffic too. v1.0 install ships the A2A registry process and both hemispheres' Agent Cards. The human interface (web UI or phone-accessible client) is a follow-on build. Until built, John interacts via Claude Code Remote Control sessions, reads decision logs and `BACKLOG.md` directly, and consumes the daily digest at `/opt/cto/logs/digest/digest-YYYY-MM-DD.md`.
**Last updated:** 2026-05-11
**Verification:** A2A status verified against a2a-protocol.org (Linux Foundation, 22K stars, 5 production SDKs). Decision settled per CTO-DECISION-006.
**Source:** CTO-DECISION-006 supersedes CTO-DECISION-003 (Telegram). architecture-decisions-john.md #9 settled 2026-05-11.

## Why A2A, Not Telegram

Telegram had real operational limitations that conflicted with CTO's design:

1. **Bot conflict when cloning** — two CTO instances cannot share one bot. Breaks the clone-test-replace upgrade cycle the moment a candidate VPS tries to message via the same bot as production.
2. **No programmatic bot creation** — every new bot requires a human @BotFather interaction. Bottlenecks the upgrade cycle.
3. **`/approve` cards broken on mobile** — OpenClaw bugs #23856, #51245, #48499. The elevated-exec approval UI doesn't render. John accepted full autonomy (CTO-DECISION architecture-decisions-john.md #8) which sidesteps this, but the channel is still impaired for any interactive flow.
4. **Proactive-messaging bootstrap friction** — Telegram blocks bot-initiated DMs until user messages bot first. CTO must wait for John to bootstrap each new bot instance.
5. **Third-party dependency** — contradicts the principle of full system control. Telegram outages or policy changes propagate into CTO operations.

A2A solves all five: agent-native, programmatically discoverable, designed for autonomous traffic, open standard not a third-party service.

## v1.0 Install: What Ships

The install script (`scripts/install-cto.sh`) sets up:

- **A2A registry process** at `/opt/cto/a2a/registry/server.py` running as systemd user service `cto-a2a-registry` on port 9000 (loopback).
- **Two Agent Cards** at `/opt/cto/a2a/registry/cards/openclaw.json` and `/opt/cto/a2a/registry/cards/hermes.json` declaring each hemisphere's role, endpoint, and capabilities.
- **Audit log** at `/opt/cto/a2a/registry/audit.log` recording every cross-hemisphere call (used for the test plan §3.1 bidirectional delegation check).

The minimal v1.0 registry serves Cards over HTTP. Full a2a-sdk integration with JSON-RPC 2.0 delegation methods is a v1.1 upgrade.

## v1.1: Human Interface on Top of A2A

The human-facing interface — web UI accessible from John's phone or laptop, speaking A2A back to CTO — is the next planned build phase. It now includes a voice-mode requirement: CTO reports should be playable aloud, and John should be able to reply by speaking. This is tracked as BACKLOG-004 and extends the PWA/chat/push requirement in BACKLOG-001.

Options under consideration (not yet decided):

- A small self-hosted web app on the VPS, reachable over HTTPS through a reverse proxy
- An existing community A2A client (e.g., a2a-explorer or equivalent) wrapped for John's specific use
- A maintained open-source voice stack adapted into the PWA rather than built from scratch; current candidates are Purple-Horizons/openclaw-voice for the browser/FastAPI/WebSocket shape, and KoljaB/RealtimeSTT + KoljaB/RealtimeTTS as component libraries
- Direct A2A calls from John's laptop's Claude Code session via Remote Control (already in place)

Decision on which approach happens after v1.0 install validates and the team has hands-on A2A experience.

## Interim — How John Sees CTO Output Before the Human Interface Ships

| Need | Where John looks |
|---|---|
| Daily digest | `/opt/cto/logs/digest/digest-YYYY-MM-DD.md` |
| Decisions | `logs/decisions/INDEX.md` and individual JSON files |
| Capability gaps | `BACKLOG.md` (root) |
| Install / upgrade results | `logs/install/*.log` and `logs/decisions/CTO-DECISION-NNN.json` |
| Real-time agent operation | Claude Code Remote Control session on John's laptop |

## Removed (Historical Reference)

- **Telegram Bot** — superseded by CTO-DECISION-006. `@HusbandCTObot` can be revoked via @BotFather at John's convenience.
- **Gmail SMTP fallback** — removed. No third-party-service fallback in the new design.
- **WhatsApp** — was already deferred under CTO-DECISION-003; now moot, no third-party messaging channel in the architecture.

## Relationships
- [Architecture](architecture.md) — comms is the Spine layer
- [Protocol Layer](protocol-layer.md) — A2A specification details
- [Architecture Decisions (John)](architecture-decisions-john.md) — #9 settled 2026-05-11
- [`../logs/decisions/CTO-DECISION-006.json`](../logs/decisions/CTO-DECISION-006.json) — the decision record
- [`../hemisphere.md`](../hemisphere.md) — A2A is corpus callosum AND the human interface protocol

## Sources
- [A2A Protocol](https://a2a-protocol.org/latest/)
- [a2aproject/A2A on GitHub](https://github.com/a2aproject/A2A)
