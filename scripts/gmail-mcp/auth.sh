#!/usr/bin/env bash
# scripts/gmail-mcp/auth.sh — one-time Gmail OAuth consent flow.
#
# Prereqs (human, one-time):
#   1. Google Cloud project with Gmail API enabled
#   2. OAuth consent screen configured: External, scope gmail.readonly, john@husband.llc as test user
#   3. OAuth 2.0 Desktop App client created; client_secret.json saved here at:
#        scripts/gmail-mcp/client_secret.json
#
# This script:
#   - installs @grabow/safe-gmail-mcp globally (if not already)
#   - moves client_secret.json into ~/.gmail-mcp/gcp-oauth.keys.json (the location the MCP expects)
#   - runs the MCP's auth command, which opens a browser; operator clicks Allow
#   - verifies refresh token landed in ~/.gmail-mcp/credentials.json
#
# After success, the same ~/.gmail-mcp/ directory can be scp'd to any new CTO VPS
# to grant Gmail read access without re-running consent.

set -euo pipefail

CLIENT_SECRET="$(dirname "$0")/client_secret.json"
GMAIL_MCP_DIR="$HOME/.gmail-mcp"
KEYS_FILE="$GMAIL_MCP_DIR/gcp-oauth.keys.json"
CREDS_FILE="$GMAIL_MCP_DIR/credentials.json"

log() { printf '[gmail-auth] %s\n' "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

[ -f "$CLIENT_SECRET" ] || die "client_secret.json not found at $CLIENT_SECRET — complete the Google Cloud Console prereqs first"

if ! command -v safe-gmail-mcp >/dev/null 2>&1; then
  log "Installing @grabow/safe-gmail-mcp globally..."
  sudo npm install -g @grabow/safe-gmail-mcp
else
  log "@grabow/safe-gmail-mcp already installed: $(safe-gmail-mcp --version 2>/dev/null || echo unknown)"
fi

mkdir -p "$GMAIL_MCP_DIR"
chmod 700 "$GMAIL_MCP_DIR"

# Copy client_secret.json into the location the MCP expects, with strict perms.
cp "$CLIENT_SECRET" "$KEYS_FILE"
chmod 600 "$KEYS_FILE"
log "Client secrets copied to $KEYS_FILE (mode 600)"

log "Launching OAuth consent flow. A browser tab will open."
log "Click 'Allow' on the Google consent screen. Refresh token will be saved on success."

safe-gmail-mcp auth

[ -f "$CREDS_FILE" ] || die "credentials.json was not produced — consent flow may have been cancelled"
chmod 600 "$CREDS_FILE"
log "Refresh token persisted to $CREDS_FILE (mode 600)"
log "Done. The same ~/.gmail-mcp/ directory can now be scp'd to a CTO VPS."
