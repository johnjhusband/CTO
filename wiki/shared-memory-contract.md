# Shared Memory Contract

Status: accepted by OpenClaw after negotiation with Hermes on 2026-05-24.
Owner: OpenClaw owns strategic canon and final promotion. Hermes owns execution-derived observations and proposals.

## Purpose

Shared memory exists to keep OpenClaw and Hermes coherent without merging their private internals. It stores durable CTO-level knowledge only.

## Shared knowledge categories

Shared memory may contain:

- Stable facts explicitly provided by John, including preferences, communication norms, and corrections.
- Architecture decisions and durable system topology.
- Decision-log references and canonical artifact pointers.
- Task handoffs that another hemisphere needs to resume or validate work.
- Research syntheses and reusable procedures that affect both hemispheres.
- Execution-derived observations from Hermes when they are stable, source-tagged, and useful beyond the current task.

## Private knowledge categories

Shared memory must not contain:

- Secrets, credentials, auth tokens, private keys, or raw environment dumps.
- Raw chain-of-thought or private deliberation from either hemisphere.
- Raw tool traces, transient logs, temporary scratchpads, retries, or debug noise.
- Hemisphere-local skills or operational state unless explicitly promoted as a reusable procedure.
- Ephemeral task status, stale PR numbers, stale issue numbers, or completed-work chatter unless preserved as an artifact pointer.

## Source of truth

The human-readable CTO vault is the canonical source of truth for shared memory: `/opt/cto/wiki`, `/opt/cto/MEMORY.md`, role docs, decision logs, and handoff docs.

Engram/SQLite is the searchable coordination and index layer. Current repaired Engram store is `/opt/cto/.engram/engram.db` via `ENGRAM_DATA_DIR=/opt/cto/.engram`. The previous `/opt/cto/.engram/cto.db` path is a stale empty artifact from the broken MCP configuration and is not canonical unless a future decision deliberately migrates Engram to that file.

## Write ownership

OpenClaw may directly promote strategic shared memory, architecture facts, policy, John instructions, conflict resolutions, and final task handoffs.

Hermes may write or propose execution-derived observations, validation findings, reusable procedures, and artifact pointers. Hermes must submit proposals for architecture, policy, ownership, security posture, or anything that conflicts with existing canon.

John overrides both hemispheres.

## Intake statuses

Use these statuses for proposed shared-memory records:

- private: keep local to the originating hemisphere.
- proposed_shared: submitted for OpenClaw review.
- accepted_shared: promoted into canonical shared memory.
- rejected: reviewed and not accepted.
- superseded: replaced by a newer canonical record.
- conflict: preserved but not resolved; requires OpenClaw or John decision.

## Required metadata

Every material shared-memory record should include subject, scope, proposed fact or summary, source agent, owner, evidence or artifact path, confidence, timestamp, status, and supersedes/contradicts links when applicable.

## Conflict resolution order

Resolve conflicts in this order:

1. John’s latest explicit instruction.
2. OpenClaw architecture decisions.
3. Canonical decision records and role docs.
4. Newer verified tool-backed facts.
5. Agent-local memory.

Do not silently overwrite conflicting claims. Preserve provenance, mark the conflict, and escalate unresolved identity/preference conflicts to John.
