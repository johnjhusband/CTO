# Clone Readiness Audit — 2026-05-25

## Bottom line
No-spend clone readiness is materially improved but not yet a full clone-test-replace approval. Local code now has explicit candidate chat isolation, coordinated `@both` routing tests, a no-spend validator, and a Phase 4 pre-provision test plan. No VPS was provisioned and no external infrastructure was touched.

## Implemented / verified tonight
- Candidate clone chat isolation is enforced in `services/chat/db.py`: non-production `CTO_INSTANCE_ID` cannot use `/opt/cto/chat.db`.
- `services/pwa/backend/server.py` imports the shared chat isolation helper, checks isolation at startup/import, recognizes explicit `@both`, and keeps coordinated `@both` sequential: OpenClaw strategy first, Hermes implementation second.
- `scripts/install.sh` writes fresh VPS installs as candidates by default: `CTO_INSTANCE_ID=candidate-<vps>`, `CHAT_DB=/opt/cto/.candidate/<id>/chat.db`, and candidate-scoped OpenClaw/Hermes session IDs.
- `scripts/install-cto.sh` keeps production defaults for in-place production service generation and wires namespace/session/chat DB values into PWA and Hermes sidecar systemd units.
- `tests/test_pwa_routing.py` covers explicit `@both`, mixed `@openclaw` + `@hermes`, sequential handoff, and candidate chat DB isolation.
- `scripts/validate-no-spend.sh` runs local shell/Python syntax checks, routing/isolation unit tests, clone namespace greps, retired-provider assignment checks, secret/runtime tracked-file checks, and optional frontend builds only when dependencies are already present.
- `test-plan.md` now includes Phase 4 no-spend clone readiness checks before any provisioning.

## Safe local checks run
- `python3 -m unittest tests.test_pwa_routing -v` — PASS, 6 tests.
- `python3 -m py_compile services/pwa/backend/server.py services/pwa/backend/job_runner.py tests/test_pwa_routing.py` — PASS.
- `bash -n scripts/install-cto.sh` — PASS.
- `bash scripts/validate-no-spend.sh` — PASS.

## Remaining blockers before spend/provision approval
1. Decide/record the exact promotion step that flips candidate values back to production (`CTO_INSTANCE_ID=production`, `CHAT_DB=/opt/cto/chat.db`, production session IDs) after a candidate passes tests.
2. Run the no-spend validator from a clean checkout to prove tracked repo state alone is sufficient.
3. Reconcile historical docs that still mention Telegram/OpenRouter as old architecture; many are archived research docs, but hot docs should clearly mark those paths superseded.
4. Run real Phase 3 functional PWA/A2A checks only when safe to exercise live agents; these may spend model quota but not infrastructure money.

## Safety note
No Hetzner resources were provisioned, no paid infrastructure action was taken, no auth was weakened, no secrets were exposed, and no production services were restarted during this audit.
