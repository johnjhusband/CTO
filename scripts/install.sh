#!/bin/bash
# scripts/install.sh — Single-command CTO install from anywhere.
#
# What this does (in order):
#   1. Reads secrets from $CTO_SECRETS (default: ~/.cto-secrets.env) or env vars.
#   2. Verifies prereqs on the runner (HETZNER_API_TOKEN required, others optional).
#   3. Provisions a fresh Hetzner VPS (cx43, falls back to cpx42).
#   4. Bootstraps the VPS as root: cto user with sudo NOPASSWD, Node 22 via NodeSource,
#      /opt/cto directory, SSH key authorized.
#   5. Builds /opt/cto/.env on the VPS from the secrets + auto-generated keys.
#   6. Clones the CTO repo to /opt/cto on the VPS (via HTTPS + GITHUB_TOKEN).
#   7. Runs scripts/install-cto.sh on the VPS as the cto user.
#   8. Verifies the install passed the install-cto.sh Phase 1 + Phase 2 gates.
#   9. Prints a structured summary.
#
# Runs from: laptop OR an existing CTO instance (the same script is used for
# autonomous clone-test-replace).
#
# Idempotent re-runs: NO — this script always provisions a fresh VPS. To re-run
# install-cto.sh against an existing VPS, ssh in and run it directly. This script
# is for the "fresh install" path.
#
# Prereqs the human must supply (one-time):
#   ~/.cto-secrets.env (gitignored, file mode 0600 recommended) containing at minimum:
#     HETZNER_API_TOKEN=...
#     GITHUB_TOKEN=...        # or gh auth will be used if gh CLI is installed
#   Optional in same file:
#     OPENAI_API_KEY=...      # for embeddings
#     BRAVE_API_KEY=...       # Brave web-search MCP
# OpenRouter retired 2026-05-24 (CTO-DECISION-014). Do NOT set OPENROUTER_API_KEY.

set -euo pipefail

# ─── Setup & logging ───────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="${REPO_ROOT}/logs/install"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/install-wrapper-${TIMESTAMP}.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== CTO Install (entry script) — $(date -Is) ==="
echo "Log: ${LOG_FILE}"
echo ""

fail()   { echo "FAIL: $*" >&2; exit 1; }
note()   { echo "→ $*"; }
section(){ echo ""; echo "═══ $* ═══"; }

# ─── Section 1: Load secrets ───────────────────────────────────────────────

section "1 — Load secrets"

CTO_SECRETS="${CTO_SECRETS:-${HOME}/.cto-secrets.env}"
if [ -f "${CTO_SECRETS}" ]; then
  note "Loading secrets from ${CTO_SECRETS}"
  set -a
  # shellcheck disable=SC1090
  . "${CTO_SECRETS}"
  set +a
else
  note "${CTO_SECRETS} not found — relying on env vars from current shell"
fi

# Required
: "${HETZNER_API_TOKEN:?HETZNER_API_TOKEN missing — add to ${CTO_SECRETS} or export it}"

# GITHUB_TOKEN: fall back to gh auth token if available
if [ -z "${GITHUB_TOKEN:-}" ]; then
  if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
    GITHUB_TOKEN="$(gh auth token)"
    note "GITHUB_TOKEN sourced from gh CLI auth"
  else
    fail "GITHUB_TOKEN missing and gh CLI not available — add to ${CTO_SECRETS}"
  fi
fi

# Optional secrets — warn if absent but don't fail
[ -z "${OPENAI_API_KEY:-}" ]     && note "OPENAI_API_KEY not set — embeddings unavailable on CTO"
# OpenRouter retired 2026-05-24 (CTO-DECISION-014). No LLM fallback configured.
[ -z "${BRAVE_API_KEY:-}" ]      && note "BRAVE_API_KEY not set — Brave search MCP will fail at runtime"

# Auto-generate the Hermes API server key
HERMES_API_SERVER_KEY="${HERMES_API_SERVER_KEY:-$(openssl rand -hex 32)}"

note "Secrets loaded"

# ─── Section 2: Resolve Hetzner SSH key + locate cto-deploy private key ────

section "2 — SSH key resolution"

# Local cto-deploy private key (used to SSH into the new VPS)
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/cto-deploy}"
[ -f "${SSH_KEY}" ] || fail "SSH key not found at ${SSH_KEY} — generate or set SSH_KEY env var"
note "Using local SSH key: ${SSH_KEY}"

# Hetzner-side SSH key ID (the public key registered with Hetzner)
HETZNER_SSH_KEY_NAME="${HETZNER_SSH_KEY_NAME:-cto-agent-deploy}"
HETZNER_SSH_KEY_ID=$(curl -fsSL -H "Authorization: Bearer ${HETZNER_API_TOKEN}" \
  https://api.hetzner.cloud/v1/ssh_keys \
  | python3 -c "import json,sys; d=json.load(sys.stdin); m=[k for k in d['ssh_keys'] if k['name']==\"${HETZNER_SSH_KEY_NAME}\"]; print(m[0]['id'] if m else '')")
[ -n "${HETZNER_SSH_KEY_ID}" ] || fail "No Hetzner SSH key named '${HETZNER_SSH_KEY_NAME}' — upload via console.hetzner.cloud or set HETZNER_SSH_KEY_NAME"
note "Hetzner SSH key '${HETZNER_SSH_KEY_NAME}' has ID ${HETZNER_SSH_KEY_ID}"

# ─── Section 3: Pick the next VPS name ──────────────────────────────────────

section "3 — Pick a new VPS name (auto-increment)"

# Find existing cto-vN servers and pick the next N
EXISTING_VERSIONS=$(curl -fsSL -H "Authorization: Bearer ${HETZNER_API_TOKEN}" \
  https://api.hetzner.cloud/v1/servers \
  | python3 -c "
import json,sys,re
d = json.load(sys.stdin)
vs = []
for s in d['servers']:
    m = re.match(r'^cto-v(\d+)$', s['name'])
    if m: vs.append(int(m.group(1)))
print('\n'.join(str(v) for v in sorted(vs)))
")
NEXT_N=1
if [ -n "${EXISTING_VERSIONS}" ]; then
  LATEST=$(echo "${EXISTING_VERSIONS}" | tail -1)
  NEXT_N=$((LATEST + 1))
fi
VPS_NAME="${VPS_NAME:-cto-v${NEXT_N}}"
note "New VPS name: ${VPS_NAME}"

# ─── Section 4: Provision VPS ───────────────────────────────────────────────

section "4 — Provision Hetzner VPS"

VPS_LOCATION="${VPS_LOCATION:-nbg1}"
PROVISION_BODY=$(cat <<JSON
{
  "name": "${VPS_NAME}",
  "image": "ubuntu-24.04",
  "location": "${VPS_LOCATION}",
  "ssh_keys": [${HETZNER_SSH_KEY_ID}],
  "labels": {"purpose": "cto", "version": "v${NEXT_N}"}
}
JSON
)

provision_attempt() {
  local server_type="$1"
  local body
  body=$(echo "${PROVISION_BODY}" | python3 -c "import json,sys; d=json.load(sys.stdin); d['server_type']='${server_type}'; print(json.dumps(d))")
  curl -fsSL -X POST -H "Authorization: Bearer ${HETZNER_API_TOKEN}" \
    -H "Content-Type: application/json" -d "${body}" \
    https://api.hetzner.cloud/v1/servers
}

# Try cx43 first (Intel, cheaper), fallback to cpx42 (AMD, more disk)
RESP=""
for TYPE in cx43 cpx42 cpx41 cx53; do
  note "Attempting server_type=${TYPE} at ${VPS_LOCATION}"
  RESP=$(provision_attempt "${TYPE}" 2>/dev/null || echo '{"error":{"code":"http_error"}}')
  ERR=$(echo "${RESP}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('error',{}).get('code',''))" 2>/dev/null || echo "parse_error")
  if [ -z "${ERR}" ]; then
    note "Provisioned with server_type=${TYPE}"
    break
  fi
  note "  ${TYPE} unavailable: ${ERR}"
  RESP=""
done
[ -n "${RESP}" ] || fail "No server_type was available in ${VPS_LOCATION} — try another location via VPS_LOCATION env var"

VPS_ID=$(echo "${RESP}" | python3 -c "import json,sys; print(json.load(sys.stdin)['server']['id'])")
VPS_IP=$(echo "${RESP}" | python3 -c "import json,sys; print(json.load(sys.stdin)['server']['public_net']['ipv4']['ip'])")
note "Provisioned: ${VPS_NAME} ID=${VPS_ID} IP=${VPS_IP}"

# Clear any stale SSH host key for this IP (in case it was reused)
ssh-keygen -R "${VPS_IP}"  -f "${HOME}/.ssh/known_hosts" >/dev/null 2>&1 || true
ssh-keygen -R "${VPS_NAME}" -f "${HOME}/.ssh/known_hosts" >/dev/null 2>&1 || true

# ─── Section 5: Wait for SSH to come up ────────────────────────────────────

section "5 — Wait for SSH on new VPS"

SSH_OPTS=(-i "${SSH_KEY}" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -o BatchMode=yes -o UserKnownHostsFile="${HOME}/.ssh/known_hosts")
DEADLINE=$(( $(date +%s) + 300 ))
while [ "$(date +%s)" -lt "${DEADLINE}" ]; do
  if ssh "${SSH_OPTS[@]}" "root@${VPS_IP}" 'echo ok' >/dev/null 2>&1; then
    note "SSH reachable on ${VPS_IP}"
    break
  fi
  echo "  waiting..."
  sleep 5
done
ssh "${SSH_OPTS[@]}" "root@${VPS_IP}" 'echo ssh-ok' >/dev/null 2>&1 \
  || fail "SSH did not come up within 5 minutes"

# ─── Section 6: Bootstrap (root, on new VPS) ───────────────────────────────

section "6 — Bootstrap VPS (root): create cto user, install Node 22"

ssh "${SSH_OPTS[@]}" "root@${VPS_IP}" 'bash -s' <<'REMOTE_ROOT'
set -e
apt-get update -qq
apt-get install -y git curl jq

# Create cto user with sudo NOPASSWD
if ! id cto >/dev/null 2>&1; then
  useradd -m -s /bin/bash cto
fi
echo 'cto ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/cto-nopasswd
chmod 0440 /etc/sudoers.d/cto-nopasswd

# SSH access for cto user (copy root's authorized_keys)
mkdir -p /home/cto/.ssh
cp /root/.ssh/authorized_keys /home/cto/.ssh/authorized_keys
chmod 700 /home/cto/.ssh
chmod 600 /home/cto/.ssh/authorized_keys
chown -R cto:cto /home/cto/.ssh

# Node 22 via NodeSource (system-wide, on PATH for all shells)
if ! command -v node >/dev/null || ! node --version | grep -q "^v22\."; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs
fi

# /opt/cto owned by cto
mkdir -p /opt/cto
chown cto:cto /opt/cto

echo "bootstrap complete: $(node --version), cto user ready"
REMOTE_ROOT

# ─── Section 7: Write /opt/cto/.env on VPS ─────────────────────────────────

section "7 — Populate /opt/cto/.env on VPS"

# Pipe the env content over SSH; never write to laptop disk or shell history
{
  echo "HETZNER_API_TOKEN=${HETZNER_API_TOKEN}"
  echo "GITHUB_TOKEN=${GITHUB_TOKEN}"
  echo "HERMES_API_SERVER_KEY=${HERMES_API_SERVER_KEY}"
  # Fresh VPS installs are clone-test-replace candidates by default. They must
  # not write into production PWA chat or reuse production chat sessions until
  # explicit promotion flips these values to production.
  CLONE_INSTANCE_ID="${CTO_INSTANCE_ID:-candidate-${VPS_NAME}}"
  echo "CTO_INSTANCE_ID=${CLONE_INSTANCE_ID}"
  echo "CHAT_DB=/opt/cto/.candidate/${CLONE_INSTANCE_ID}/chat.db"
  echo "OPENCLAW_SESSION_ID=${CLONE_INSTANCE_ID}-pwa-john-openclaw"
  echo "HERMES_HUMAN_SESSION_ID=${CLONE_INSTANCE_ID}-pwa-john-hermes"
  echo "HERMES_AGENT_SESSION_ID=${CLONE_INSTANCE_ID}-a2a-openclaw-hermes"
  # These will be filled in by install-cto.sh on the VPS if absent.
  # We don't pre-generate them on the laptop so they live on the VPS only.
  [ -n "${OPENAI_API_KEY:-}" ]     && echo "OPENAI_API_KEY=${OPENAI_API_KEY}"
  # OPENROUTER_API_KEY intentionally NOT carried — retired in CTO-DECISION-014.
  [ -n "${BRAVE_API_KEY:-}" ]      && echo "BRAVE_API_KEY=${BRAVE_API_KEY}"
} | ssh "${SSH_OPTS[@]}" "cto@${VPS_IP}" 'cat > /opt/cto/.env && chmod 0600 /opt/cto/.env'

ssh "${SSH_OPTS[@]}" "cto@${VPS_IP}" 'echo "--- .env keys present (values redacted) ---"; sed "s/=.*/=<set>/" /opt/cto/.env'

# ─── Section 7.5: Carry forward Codex auth (avoid re-approving device code) ─

section "7.5 — Reuse Codex OAuth from source host if present"

# CTO is designed for autonomous self-cloning per CTO-DECISION-005. Every clone
# re-running `codex login --device-auth` would require a human approval, which
# breaks autonomy. So: if the source host (laptop on first install, or an
# existing CTO instance during self-clone) already has ~/.codex/auth.json,
# scp it to the new VPS. install-cto.sh detects the existing auth.json and
# skips the device-code prompt.

LOCAL_CODEX_AUTH="${HOME}/.codex/auth.json"
if [ -s "${LOCAL_CODEX_AUTH}" ]; then
  note "Source host has Codex auth — copying to new VPS to skip device-code"
  ssh "${SSH_OPTS[@]}" "cto@${VPS_IP}" 'mkdir -p ~/.codex && chmod 700 ~/.codex'
  scp -q -i "${SSH_KEY}" -o StrictHostKeyChecking=accept-new \
    "${LOCAL_CODEX_AUTH}" "cto@${VPS_IP}:/home/cto/.codex/auth.json"
  ssh "${SSH_OPTS[@]}" "cto@${VPS_IP}" 'chmod 600 ~/.codex/auth.json'
  note "Codex auth.json copied"
else
  note "Source host has no ~/.codex/auth.json — VPS will run device-code flow once"
fi

# ─── Section 7.6 — Reuse Gmail OAuth refresh token from source host ────────

section "7.6 — Reuse Gmail OAuth refresh token from source host if present"

# Per CTO-DECISION-010, both hemispheres use @grabow/safe-gmail-mcp with the
# refresh token stored at ~/.gmail-mcp/credentials.json. Re-running the OAuth
# consent flow per clone breaks autonomy (browser click required). So: if the
# source host already has ~/.gmail-mcp/, scp the whole directory.

LOCAL_GMAIL_DIR="${HOME}/.gmail-mcp"
if [ -d "${LOCAL_GMAIL_DIR}" ] && [ -s "${LOCAL_GMAIL_DIR}/credentials.json" ]; then
  note "Source host has Gmail OAuth credentials — copying to new VPS"
  ssh "${SSH_OPTS[@]}" "cto@${VPS_IP}" 'mkdir -p ~/.gmail-mcp && chmod 700 ~/.gmail-mcp'
  scp -q -i "${SSH_KEY}" -o StrictHostKeyChecking=accept-new \
    "${LOCAL_GMAIL_DIR}/credentials.json" \
    "cto@${VPS_IP}:/home/cto/.gmail-mcp/credentials.json"
  if [ -s "${LOCAL_GMAIL_DIR}/gcp-oauth.keys.json" ]; then
    scp -q -i "${SSH_KEY}" -o StrictHostKeyChecking=accept-new \
      "${LOCAL_GMAIL_DIR}/gcp-oauth.keys.json" \
      "cto@${VPS_IP}:/home/cto/.gmail-mcp/gcp-oauth.keys.json"
  fi
  ssh "${SSH_OPTS[@]}" "cto@${VPS_IP}" 'chmod 600 ~/.gmail-mcp/*.json'
  note "Gmail credentials copied"
else
  note "Source host has no ~/.gmail-mcp/credentials.json — run scripts/gmail-mcp/auth.sh on source host first"
fi

# ─── Section 8: Clone repo on VPS ───────────────────────────────────────────

section "8 — Clone CTO repo on VPS"

REPO_URL="${REPO_URL:-https://github.com/johnjhusband/CTO.git}"
ssh "${SSH_OPTS[@]}" "cto@${VPS_IP}" "
  set -e
  source /opt/cto/.env
  # Clone alongside the .env, then merge
  if [ ! -d /opt/cto/.git ]; then
    git clone https://oauth2:\${GITHUB_TOKEN}@${REPO_URL#https://} /tmp/cto-clone
    mv /tmp/cto-clone/.git /opt/cto/.git
    shopt -s dotglob
    cd /tmp/cto-clone
    for item in *; do
      [ \"\$item\" = '.git' ] && continue
      [ \"\$item\" = '.env' ] && continue
      mv \"\$item\" \"/opt/cto/\$item\"
    done
    rm -rf /tmp/cto-clone
    cd /opt/cto
    # Remote stays HTTPS+token so the cto user can push/pull without an SSH deploy key
    git remote set-url origin \"https://oauth2:\${GITHUB_TOKEN}@${REPO_URL#https://}\"
    git config user.name 'CTO'
    git config user.email 'johnjhusband@users.noreply.github.com'
  fi
  cd /opt/cto && git log --oneline -1
"

# ─── Section 9: Run install-cto.sh on VPS ──────────────────────────────────

section "9 — Run install-cto.sh on VPS as cto user"

# Stream output back to laptop in real-time so device-code prompts are visible
ssh "${SSH_OPTS[@]}" "cto@${VPS_IP}" 'bash /opt/cto/scripts/install-cto.sh' \
  || fail "install-cto.sh failed on VPS — see VPS log at /opt/cto/logs/install/"

# ─── Section 9.5: Pull Codex auth BACK to source host for future installs ──

section "9.5 — Cache Codex auth.json on source host for future re-use"

# After a successful install, scp the (possibly newly-created) auth.json back.
# This means every install after the first one is zero-touch on the Codex side.
mkdir -p "${HOME}/.codex"
scp -q -i "${SSH_KEY}" -o StrictHostKeyChecking=accept-new \
  "cto@${VPS_IP}:/home/cto/.codex/auth.json" "${LOCAL_CODEX_AUTH}" 2>/dev/null \
  && chmod 600 "${LOCAL_CODEX_AUTH}" \
  && note "Cached auth.json at ${LOCAL_CODEX_AUTH} — next install will skip device-code" \
  || note "(could not pull auth.json back; future installs will require device-code)"

# Same pattern for Gmail OAuth credentials — pull them back to the source host
# so future clones inherit the refresh token.
mkdir -p "${LOCAL_GMAIL_DIR}"
scp -q -i "${SSH_KEY}" -o StrictHostKeyChecking=accept-new \
  "cto@${VPS_IP}:/home/cto/.gmail-mcp/credentials.json" \
  "${LOCAL_GMAIL_DIR}/credentials.json" 2>/dev/null \
  && chmod 600 "${LOCAL_GMAIL_DIR}/credentials.json" \
  && note "Cached gmail credentials.json at ${LOCAL_GMAIL_DIR}" \
  || note "(no gmail credentials.json on VPS to pull back)"

# ─── Section 10: Final verification ─────────────────────────────────────────

section "10 — Final verification"

ssh "${SSH_OPTS[@]}" "cto@${VPS_IP}" '
  echo "--- daemons ---"
  systemctl --user is-active openclaw-gateway hermes-gateway cto-a2a-registry
  echo "--- ports ---"
  ss -tlnp 2>/dev/null | grep -E ":18789|:8642|:9000"
  echo "--- health ---"
  curl -fsS http://127.0.0.1:8642/health || echo "(Hermes health endpoint unreachable)"
  curl -fsS http://127.0.0.1:9000/health || echo "(A2A registry health unreachable)"
'

# ─── Done ──────────────────────────────────────────────────────────────────

section "Install complete"

cat <<SUMMARY

CTO install: SUCCESS

  VPS:       ${VPS_NAME} (id ${VPS_ID})
  IP:        ${VPS_IP}
  SSH:       ssh -i ${SSH_KEY} cto@${VPS_IP}
  Wrapper log: ${LOG_FILE}

Next: see test-plan.md §3 for the canonical functional test.
SUMMARY
