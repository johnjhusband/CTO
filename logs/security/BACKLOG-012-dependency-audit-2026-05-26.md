# BACKLOG-012 dependency/security gate artifact — 2026-05-26

## Scope
BACKLOG-012: patch management / dependency hygiene for OpenClaw and CTO Node subprojects.

## Environment
- node: v22.22.2
- npm: 10.9.7
- openclaw installed: OpenClaw 2026.5.7 (eeef486)
- openclaw npm latest: 2026.5.22

## Audit results

### lib/a2a-secure
found 0 vulnerabilities

### plugins/openclaw-secure-a2a
found 0 vulnerabilities

### scripts/namecheap-playwright
found 0 vulnerabilities

### ui/cto-chat
found 0 vulnerabilities

## Verification command
for d in lib/a2a-secure plugins/openclaw-secure-a2a scripts/namecheap-playwright ui/cto-chat; do (cd /opt/cto/$d && npm audit --omit=dev --audit-level=moderate); done && test "$(openclaw --version | awk '{print $2}')" = "2026.5.7" && test "$(npm view openclaw version)" = "2026.5.22"
