# Component Prerequisites Audit
**L0:** Full dependency chain for every component. Identifies what we have, what we need, and what's unresearched.
**L1:** Every component CTO v1 needs, with its prerequisites, whether we have them, and gaps to fill. Created after discovering memweave's embedding dependency during install — the research methodology missed prerequisites.
**Last updated:** 2026-04-26
**Source:** Audit of all planned components against documented research

## Audit Results

### 1. OpenClaw
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| Node.js 22+ | Yes (22.22.2 on VPS) | |
| npm | Yes (10.9.7) | |
| LLM API key | **NO** | Need OpenRouter key from John |
| systemd (for daemon) | Yes (Ubuntu 24.04) | |
| Port 18789 available | **UNVERIFIED** | Need to check on VPS |

### 2. MCPVault (filesystem MCP for wiki)
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| Node.js | Yes | |
| npx | Yes | |
| Vault directory | Yes (/opt/cto/wiki) | |
| API keys | None needed | |
**Status: COMPLETE — installed and tested locally**

### 3. memweave (SQLite coordination)
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| Python 3.8+ | Yes (3.12) | |
| pip / venv | Yes | |
| Embedding model | **NO** | Needs either: OpenAI API key, OR OpenRouter key (via LiteLLM), OR Ollama with local model |
| sqlite3 | Yes (built into Python) | |
**Status: INCOMPLETE — FTS works, vector search blocked on embedding API**

**Research needed:** Can memweave use OpenRouter for embeddings via LiteLLM? What's the exact config? This would let us use one API key for both OpenClaw and memweave.

### 4. Telegram Bot
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| @BotFather bot token | **NO** | John creates via Telegram |
| John's numeric user ID | **NO** | John gets from @userinfobot |
| John has Telegram installed | **YES** | Installed during this session |
| First message from John to bot | **NO** | Required before bot can send proactively (known bug) |
**Status: BLOCKED on John creating bot**

### 5. OpenRouter
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| API key | **NO** | John creates at openrouter.ai/keys |
| Credit balance | **UNKNOWN** | Does OpenRouter need prepaid credits or is it postpaid? |
**Status: BLOCKED on John + billing model unresearched**

### 6. Hetzner Cloud API / hcloud CLI
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| API token | **NO** | John creates at console.hetzner.cloud |
| hcloud CLI binary | **NO** | Not yet installed on VPS |
| SSH key registered with Hetzner | **UNKNOWN** | Does the cto-deploy key need to be uploaded to Hetzner API? |
**Status: BLOCKED on John + SSH key registration unresearched**

### 7. brave-search MCP server
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| Brave Search API key | **NO** | **UNRESEARCHED** — how to get it, cost, rate limits |
| npm package exists | **UNVERIFIED** | Listed as @modelcontextprotocol/server-brave-search |
**Status: UNRESEARCHED**

### 8. github MCP server
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| GitHub Personal Access Token | **NO** | Need to create or use existing |
| npm package exists | **UNVERIFIED** | Listed as @modelcontextprotocol/server-github |
| Token scopes needed | **UNRESEARCHED** | What permissions does the PAT need? |
**Status: PARTIALLY RESEARCHED**

### 9. fetch MCP server
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| npm package exists | **UNVERIFIED** | Listed as @modelcontextprotocol/server-fetch |
| API keys | **UNKNOWN** | Does it need any? |
**Status: UNRESEARCHED**

### 10. hetzner MCP server
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| npm package exists | **UNVERIFIED** | Listed as hetzner-cloud-mcp |
| Hetzner API token | **NO** | Same as #6 |
| What it actually provides | **UNRESEARCHED** | Claimed 60 tools — verified? |
**Status: UNRESEARCHED**

### 11. filesystem MCP server
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| npm package exists | **UNVERIFIED** | Listed as @modelcontextprotocol/server-filesystem |
| Path permissions | Depends on user | cto user owns /opt/cto |
**Status: UNRESEARCHED for verification**

### 12. Security hardening (firewall, fail2ban)
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| ufw | **UNKNOWN** | Is it installed on Ubuntu 24.04 by default? |
| fail2ban | **UNKNOWN** | Need to install? |
| What ports to open/close | **UNRESEARCHED** | Need to map all services to ports |
**Status: UNRESEARCHED**

### 13. Python on VPS
| Prerequisite | Have it? | Notes |
|-------------|----------|-------|
| Python 3 | **UNVERIFIED** | Ubuntu 24.04 should have it but not confirmed |
| pip / venv | **UNVERIFIED** | May need python3-pip python3-venv packages |
**Status: UNVERIFIED on VPS**

## Summary

| Status | Count | Components |
|--------|-------|------------|
| **Complete** | 1 | MCPVault |
| **Partially researched** | 4 | OpenClaw, memweave, Telegram, github MCP |
| **Blocked on John** | 3 | OpenRouter key, Telegram bot token, Hetzner API token |
| **Unresearched** | 5 | brave-search MCP, fetch MCP, hetzner MCP, filesystem MCP, security hardening |
| **Unverified on VPS** | 2 | Python, port availability |

## Research Results (Completed)

### VPS Verification
- Python 3.12.3: YES
- pip 24.0: YES
- venv: YES
- Port 18789: FREE
- ufw: INSTALLED
- fail2ban: NOT INSTALLED (need to install)

### Package Verification — CRITICAL CORRECTIONS

**Several packages in our openclaw.json reference are WRONG:**

| Our Config | Reality | Correction |
|------------|---------|------------|
| `@modelcontextprotocol/server-brave-search` | **DEPRECATED** | Use `@brave/brave-search-mcp-server` (v2.0.80) |
| `@modelcontextprotocol/server-github` | **DEPRECATED** | Use `github/github-mcp-server` (Go binary, not npm) |
| `@modelcontextprotocol/server-fetch` | **DOES NOT EXIST on npm** | Use Python `mcp-server-fetch` (PyPI) or community TS package |
| `hetzner-cloud-mcp` | **DOES NOT EXIST on npm** (it's PHP) | Use `@lazyants/hetzner-mcp-server` (104 tools, npm) |
| `@modelcontextprotocol/server-filesystem` | EXISTS, v2026.1.14 | Correct as documented |

### OpenRouter Billing
- **Prepaid**, not postpaid. Add credits, deducted in real-time.
- Free tier: dozens of free models, $1 in free credits for new users
- No minimum deposit, credits never expire, no monthly fees
- ~5% platform fee (bypassed with own provider key)

### memweave + OpenRouter Embeddings
- memweave does NOT natively support OpenRouter or LiteLLM
- LiteLLM supports OpenRouter embeddings (PR #18391, Jan 2026)
- Would need custom adapter to bridge memweave → LiteLLM → OpenRouter
- Not out-of-the-box. Alternative: use OpenAI embedding key directly, or FTS-only

### Brave Search API
- $5/month free credit (covers ~1,000 queries/month)
- Credit card required at signup
- Rate limit: 1 query/second on free tier
- Old free tier (2,000-5,000 queries) killed Feb 2026

### GitHub PAT Scopes
- Minimum: `repo` (private) or `public_repo` (public only)
- Full: `repo`, `gist`, `admin:org`, `project`, `notifications`
- Fine-grained PATs: scoping enforced at API level, not token level

## Remaining Gaps
1. Hetzner SSH key registration via API — does cto-deploy key need uploading?
2. Security hardening details — fail2ban install, ufw rules, port mapping
3. memweave custom adapter for OpenRouter embeddings — feasibility assessment
