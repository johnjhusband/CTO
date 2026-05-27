#!/usr/bin/env bash
# Run non-destructive CTO security gates that are safe for work-pump/CI use.
# This intentionally does not rotate credentials, rewrite history, touch live config,
# alter push subscriptions, or print secret values.
set -euo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

printf '== secret artifact guard ==\n'
scripts/security/check-secret-artifacts.sh

printf '\n== operational secret redaction check ==\n'
scripts/security/redact-operational-secrets.py --check

printf '\n== install secret-handling guard ==\n'
scripts/security/check-install-secret-handling.sh

printf '\n== credential rotation preflight syntax ==\n'
bash -n scripts/security/rotation-preflight.sh

printf '\n== redaction unit tests ==\n'
python3 -m unittest -v tests/test_redact_operational_secrets.py

printf '\n== PWA auth/routing regression tests ==\n'
python3 -m unittest -v tests/test_pwa_routing.py

printf '\n== PWA voice UI regression tests ==\n'
python3 -m unittest -v tests/test_pwa_voice_ui.py

printf '\nSafe security gates passed.\n'
