#!/usr/bin/env bash
# Local clone-readiness checks that must not provision paid infrastructure.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

fail() { echo "FAIL: $*" >&2; exit 1; }
section() { echo; echo "═══ $* ═══"; }

section "shell syntax"
bash -n scripts/install.sh
bash -n scripts/install-cto.sh
bash -n scripts/cache-keepalive.sh
bash -n scripts/remove-channels.sh

section "python syntax"
python3 -m compileall -q services scripts/index_wiki.py tests

section "PWA routing + clone isolation unit tests"
python3 tests/test_pwa_routing.py

section "clone chat isolation defaults"
grep -q 'CLONE_INSTANCE_ID=.*candidate-' scripts/install.sh || fail "scripts/install.sh must namespace fresh VPS installs as candidates"
grep -q 'CTO_TEST_MODE=1' scripts/install.sh || fail "scripts/install.sh must put fresh candidates in test mode"
grep -q 'test_mode.*true' scripts/install.sh || fail "Hetzner candidate labels must include test_mode=true"
grep -q 'ALLOW_TEST_MODE_SELF_CLONE' scripts/install.sh || fail "test-mode candidates must refuse self-clone by default"
grep -q 'CHAT_DB=/opt/cto/.candidate/' scripts/install.sh || fail "scripts/install.sh must route candidates to isolated chat DB"
python3 - <<'PY'
import os, sys, tempfile
from pathlib import Path
root = Path.cwd()
services = root / 'services'
sys.path.insert(0, str(services))
from chat.db import clone_chat_isolation_error
assert clone_chat_isolation_error(instance_id='candidate-check', chat_db='/opt/cto/chat.db', cto_root='/opt/cto')
assert clone_chat_isolation_error(instance_id='production', chat_db='/opt/cto/chat.db', cto_root='/opt/cto') is None
assert clone_chat_isolation_error(instance_id='candidate-check', chat_db='/opt/cto/.candidate/candidate-check/chat.db', cto_root='/opt/cto') is None
print('PASS: clone isolation helper')
PY

section "retired provider not in active install surfaces"
! grep -RIn '^[[:space:]]*[^#[:space:]].*OPENROUTER_API_KEY=' README.md example.cto-secrets.env scripts/install.sh scripts/install-cto.sh services ui 2>/dev/null \
  || fail "OPENROUTER_API_KEY remains as an active assignment in install surfaces"

section "tracked secret/runtime files"
! git ls-files --error-unmatch .env chat.db .vapid/private.pem >/dev/null 2>&1 \
  || fail "secret/runtime file tracked by git"

section "frontend TypeScript build if dependencies are present"
if [ -d ui/cto-chat/node_modules ]; then
  npm --prefix ui/cto-chat run build
else
  echo "SKIP: ui/cto-chat/node_modules absent"
fi

if [ -d lib/a2a-secure/node_modules ]; then
  npm --prefix lib/a2a-secure run build
else
  echo "SKIP: lib/a2a-secure/node_modules absent"
fi

if [ -d plugins/openclaw-secure-a2a/node_modules ]; then
  npm --prefix plugins/openclaw-secure-a2a run build
else
  echo "SKIP: plugins/openclaw-secure-a2a/node_modules absent"
fi

echo
echo "PASS: no-spend validation complete"
