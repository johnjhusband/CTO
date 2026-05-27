# BACKLOG-014/PWA visibility repair — feature request status summary

- Timestamp: 2026-05-27T02:55Z
- Selected item: P0 PWA improvements visibility after John reported that feature requests were not visible in the phone PWA.
- A2A2H per-tick check: no upstream-eligible CTO commits since `180e8da5b14943e8ccb6dd55e5b0309ff840aeaf`; no port required before this repair.

## Change

Added a visible feature-request status strip to the PWA shell so the implemented requests are no longer hidden behind assumptions or chat history:

- Background alerts: shows `Needs phone test` next to the Enable/Test push button.
- Agent coordination: shows `Live` next to the Show coordination toggle.
- Chat history: shows `Live` next to the durable `/chat-log/` link.
- Voice: shows `Browser-native` next to the voice controls.
- Added a persistent `Feature request status:` summary line with a direct `Review full logs` link.
- Bumped the service-worker shell cache from `cto-shell-v10` to `cto-shell-v11` so John's installed PWA can fetch the visible update.

## Verification

Passed:

```bash
python3 -m unittest -v tests/test_pwa_routing.py tests/test_pwa_voice_ui.py
python3 -m unittest -v tests/test_redact_operational_secrets.py
python3 -c "import ast; ast.parse(open('services/pwa/backend/server.py').read())"
python3 - <<'PY'
from pathlib import Path
index=Path('services/pwa/frontend/index.html').read_text()
worker=Path('services/pwa/frontend/service-worker.js').read_text()
assert 'Feature request status:' in index
assert 'cto-shell-v11' in worker
print('static verification ok: feature summary visible, cache cto-shell-v11')
PY
```

Result: 30/30 PWA routing+voice tests passed; 8/8 operational secret redaction tests passed; backend syntax sanity passed; static shell check passed.

## Status

This does not close BACKLOG-014 because actual background notification display still needs John's phone/browser confirmation. It does make the PWA's shipped feature requests explicit and visible in the app shell.

## A2A2H port

Ported CTO `07c3efa` PWA feature-status shell changes to A2A2H through `8156811db9b23dddf10807752bb37b7222db439e` and updated `wiki/A2A2H_LAST_SYNC.md` in follow-up sync commits.
A2A2H verification: backend syntax sanity passed, static feature-summary/cache assertions passed, and grep for `cto`, `/opt/cto`, and `husband.llc` across upstream service/script/frontend paths returned no hits.
