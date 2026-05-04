# Auth Infrastructure — Authelia + A2A OAuth
**L0:** Authelia (30MB, standalone binary, no Docker) as OAuth2/OIDC server. Issues tokens to John (browser login) and future agents (client_credentials). Custom scopes per agent (command vs inform). CTO manages Authelia config to add new agents.
**L1:** Each agent's A2A endpoint requires OAuth tokens. Authelia handles issuance. John gets tokens via browser login (authorization_code flow). Agents get tokens via client_credentials flow. Custom scopes (cto:command, cto:inform, cfo:command, etc.) control who can command vs inform. CTO manages Authelia YAML config — when CTO creates a new agent, it adds a client entry and restarts Authelia. No Docker required (standalone binary or APT install). 30MB RAM. SQLite built-in.
**Last updated:** 2026-05-03
**Verification:** Authelia bare-metal install verified against official docs. A2A OAuth flow verified against spec. Agent Card securitySchemes format verified.

## Architecture

```
Authelia (OAuth2/OIDC, 30MB, systemd service)
  ├── John: authorization_code flow (browser login)
  ├── Future agents: client_credentials flow
  ├── Custom scopes: {agent}:command, {agent}:inform
  └── CTO manages config (adds new agent clients)

CTO Agent (A2A endpoint + FastAPI middleware)
  ├── Agent Card at /.well-known/agent.json (public, unauthenticated)
  ├── All other A2A requests require Bearer token
  ├── Middleware validates JWT, extracts scopes
  └── Skills declare required scopes (command vs inform)
```

## Installation (No Docker)

```bash
# Option 1: APT (Debian/Ubuntu)
sudo curl -fsSL https://www.authelia.com/keys/authelia-security.gpg \
  -o /usr/share/keyrings/authelia-security.gpg
# Add APT repo, then: sudo apt install authelia

# Option 2: Direct binary from GitHub releases
# Download from github.com/authelia/authelia/releases

# Run as systemd service
sudo systemctl enable authelia
sudo systemctl start authelia
```

Config at `/etc/authelia/configuration.yml`

## Agent Card Example (CTO)

```json
{
  "name": "CTO Agent",
  "url": "https://cto.yourdomain.com/a2a",
  "securitySchemes": {
    "oauth2": {
      "type": "oauth2",
      "flows": {
        "clientCredentials": {
          "tokenUrl": "https://auth.yourdomain.com/api/oidc/token",
          "scopes": {
            "cto:command": "Execute commands and make changes",
            "cto:inform": "Read-only status and information queries"
          }
        }
      }
    }
  },
  "security": [{"oauth2": ["cto:inform"]}],
  "skills": [
    {"id": "execute-upgrade", "security": [{"oauth2": ["cto:command"]}]},
    {"id": "status-report", "security": [{"oauth2": ["cto:inform"]}]},
    {"id": "research-request", "security": [{"oauth2": ["cto:inform"]}]}
  ]
}
```

## Authelia Config (Minimal)

```yaml
identity_providers:
  oidc:
    clients:
      # John's human access
      - client_id: 'john-human'
        client_name: 'John Human Access'
        client_secret: '$pbkdf2-sha512$...'
        redirect_uris:
          - 'https://cto.yourdomain.com/callback'
        scopes: ['openid', 'cto:command', 'cto:inform']
        grant_types: ['authorization_code', 'refresh_token']

      # Template for future agents (CTO adds these)
      # - client_id: 'agent-cfo'
      #   client_name: 'CFO Agent'
      #   client_secret: '$pbkdf2-sha512$...'
      #   scopes: ['cto:inform']
      #   grant_types: ['client_credentials']

authentication_backend:
  file:
    path: /etc/authelia/users_database.yml

storage:
  local:
    path: /var/lib/authelia/db.sqlite3
```

## How CTO Creates a New Agent

1. CTO provisions new VPS via Hetzner API
2. CTO generates client_id and client_secret for the new agent
3. CTO adds client entry to Authelia YAML config
4. CTO restarts Authelia: `sudo systemctl restart authelia`
5. CTO deploys the new agent to the VPS with its credentials
6. New agent publishes its Agent Card
7. CTO discovers the new agent via Agent Card and can communicate

No human involved in agent registration.

## Scope Model

| Scope | Who Gets It | What It Allows |
|-------|------------|----------------|
| `cto:command` | CEO, John | Execute upgrades, change config, modify architecture |
| `cto:inform` | Any agent, John | Read status, receive reports, share information |
| `cfo:command` | CEO, John | (future) Execute financial operations |
| `cfo:inform` | Any agent, John | (future) Read financial reports |

## Sources
- [Authelia Bare-Metal Docs](https://www.authelia.com/integration/deployment/bare-metal/)
- [Authelia OIDC Client Config](https://www.authelia.com/configuration/identity-providers/openid-connect/clients/)
- [A2A Protocol Specification](https://a2a-protocol.org/latest/specification/)
- [A2A Protocol Enterprise Features](https://a2a-protocol.org/latest/topics/enterprise-ready/)
- [Christian Posta: A2A OAuth](https://blog.christianposta.com/setting-up-a2a-oauth-user-delegation/)
