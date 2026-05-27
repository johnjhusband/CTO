# BACKLOG-003 Dependabot PR triage — 2026-05-27T10:35Z

## Scope
[verified] Advanced the public-repo dependency-chain audit portion of BACKLOG-003. This tick did not merge dependency PRs, change runtime services, rotate credentials, rewrite history, spend money, or delegate semantic work to Hermes.

## Required pre-checks
- [verified] A2A2H drift check was clean: no upstream-eligible CTO commits after `27abb1203d2a13253e8c1b7e9658518d77794236`.
- [verified] Hermes provider circuit is open with `agent_incomplete_provider_NoneType`; no Hermes semantic delegation was attempted.
- [verified] P0 credential/history work remains blocked on coordinated rotation/history-scrub windows; P0 PWA voice/background items remain open pending John/device evidence; no backlog item was safely closable from disk evidence alone.

## Findings
[verified] Dependabot created 7 open dependency PRs after `.github/dependabot.yml` was enabled:

| PR | Package / path | Change class | Notes |
|---|---|---|---|
| #1 | `@vitejs/plugin-react` in `ui/cto-chat` | major dev dependency | Plugin 6 removes Babel-related features; requires compatibility testing before merge. |
| #2 | `@types/node` in `plugins/openclaw-secure-a2a` | major dev dependency | Type-only surface; still can expose TS compile breaks. |
| #3 | `@types/node` in `lib/a2a-secure` | major dev dependency | Type-only surface; still can expose TS compile breaks. |
| #4 | `typescript` in `ui/cto-chat` | major dev dependency | TypeScript 6 major; requires compile/test gate. |
| #5 | `typescript` in `plugins/openclaw-secure-a2a` | major dev dependency | TypeScript 6 major; requires compile/test gate. |
| #6 | `typescript` in `lib/a2a-secure` | major dev dependency | TypeScript 6 major; requires compile/test gate. |
| #7 | `vite` in `ui/cto-chat` | major dev dependency | Vite 8 major; highest compatibility risk among the batch. |

[verified] Local remote branches exist for all 7 PRs and each branch only changes the relevant package manifest/lock files.

## Decision / next action
[verified] Do not auto-merge these PRs from the work pump. They are major-version dependency updates and should be handled as a bounded dependency-validation item with package-level tests/builds, preferably one package root at a time to preserve the one-material-change rule.

[verified] Suggested next safe step: create a dedicated validation artifact for PR #7 (`vite` in `ui/cto-chat`) first, because it has the largest frontend build/runtime compatibility blast radius.

## Verification evidence
- [verified] GitHub PR search returned 7 open Dependabot PRs authored by `dependabot[bot]`.
- [verified] `git branch -r` showed 7 matching `origin/dependabot/...` branches.
- [verified] `git diff --name-only origin/master...origin/dependabot/...` for each branch showed only `package.json` and `package-lock.json` in the targeted package root.

## Result
[verified] BACKLOG-003 now has a tracked dependency-update queue and a safe merge policy: evaluate, test, and merge deliberately rather than accepting major-version dependency updates automatically.
