# PWA Conversation Architecture — Preventing Agent Chat Collisions

## Problem

During a previous cloning exercise, multiple agents ended up talking in the same human chat without clear ownership. That creates ambiguous turns, duplicate replies, cross-agent interruptions, and unsafe routing during clone-test-replace.

## Decision

The PWA is a human-facing control room, not a free-for-all group chat. OpenClaw owns orchestration and final-mile strategy. Hermes owns execution and implementation after OpenClaw hands off a scoped task. Both may be visible to John, but only through explicit routing and turn ownership.

## Roles

- OpenClaw: left hemisphere; strategy, architecture, routing authority, clone-test-replace decision owner, final-mile reporting.
- Hermes: right hemisphere; implementation, execution, repair, validation details, skill/tool work.
- John: owner/operator; can address either or both, but the system must avoid uncontrolled simultaneous agent chatter.

## Routing Rules

1. Explicit mentions always win:
   - `@openclaw` routes only to OpenClaw.
   - `@hermes` routes only to Hermes.
   - `@both` routes to a coordinated two-step flow, not uncontrolled parallel chat.

2. No-mention routing is conservative:
   - Repair, strategy, architecture, cloning, spending, infrastructure, or ambiguous work defaults to OpenClaw.
   - Clearly Hermes-addressed work routes to Hermes.
   - Simple greetings may route to both only as a health/status affordance.

3. Coordinated `@both` flow:
   - OpenClaw speaks first unless John explicitly orders otherwise.
   - OpenClaw writes a scoped handoff for Hermes.
   - Hermes implements after receiving that handoff.
   - Hermes reports implementation result back as a bounded update.
   - OpenClaw reviews, accepts/rejects, and reports the final result to John.

4. A2A request/response rows are internal evidence by default:
   - They may be stored in `chat.db` for traceability.
   - They should not render as primary chat unless John enables A2A/debug view.
   - User-facing rows should be plain English from the owning participant.

5. Clone isolation:
   - A candidate clone must not post into the same production PWA chat as the active CTO.
   - Candidate clone uses a distinct environment identity, session ids, A2A namespace, and chat DB.
   - Promotion is the moment the candidate becomes the production responder.
   - Before promotion, candidate reports to a separate test channel/log or through OpenClaw’s controlled summary.

## Required Implementation

- Extend `parse_mention` to recognize `@both` explicitly.
- Replace naive parallel `both` delivery with a coordinated mode.
- Add a handoff mechanism: OpenClaw result can enqueue or trigger Hermes implementation.
- Add an owner/phase field for coordinated jobs so only the active phase speaks to John.
- Add clone namespace variables for candidate environments: `CTO_INSTANCE_ID`, `CHAT_DB`, `OPENCLAW_SESSION_ID`, `HERMES_HUMAN_SESSION_ID`, `HERMES_AGENT_SESSION_ID`, and A2A tokens/URLs must be candidate-specific.

## Acceptance Criteria

- `@both` no longer causes two independent agents to answer without sequencing.
- `@openclaw start with strategy... @hermes after...` is represented as OpenClaw strategy first, Hermes implementation second.
- Candidate clone can run without posting into production chat.
- Logs preserve both agents’ work without confusing John’s main chat.
