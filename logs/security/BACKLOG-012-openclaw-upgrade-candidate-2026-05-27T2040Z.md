# BACKLOG-012 — OpenClaw upgrade candidate smoke

Time: 2026-05-27T20:40Z

Selected item: BACKLOG-012 (patch management / dependency hygiene). This tick did not upgrade production OpenClaw in place.

## A2A2H precheck

No upstream-eligible CTO commits since `6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3`; no A2A2H port required.

## Hermes state

Hermes semantic delegation skipped because `/opt/cto/.cache/hermes-work-pump-provider-failure.json` shows the provider circuit is open for `agent_incomplete_provider_NoneType`.

## Shipped artifact

Added `scripts/security/openclaw-upgrade-candidate.sh`, a no-production-mutation candidate smoke for the latest OpenClaw npm package.

What it does:
- resolves `openclaw@latest` via npm,
- runs the target CLI in an isolated npm exec cache under `.cache/openclaw-upgrade-candidate`,
- disables npm lifecycle scripts,
- verifies `openclaw --version` and `openclaw help`,
- writes a JSON summary, and
- leaves production/global OpenClaw untouched.

## Verification

Command:

```bash
OUTPUT_DIR=/opt/cto/.cache/openclaw-upgrade-candidate/20260527T2040 \
  scripts/security/openclaw-upgrade-candidate.sh
```

Result:
- current production OpenClaw: `2026.5.7`
- latest candidate OpenClaw: `2026.5.26`
- candidate output: `OpenClaw 2026.5.26 (10ad3aa)`
- help smoke: passed
- production mutation: false
- global npm mutation: false

Remaining BACKLOG-012 work: promote OpenClaw through the approved clone-test-replace path before changing production runtime.
