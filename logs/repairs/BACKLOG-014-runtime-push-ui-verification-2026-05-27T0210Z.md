# BACKLOG-014 runtime push UI verification — 2026-05-27T02:10Z

## Selection
OpenClaw continuous work pump selected BACKLOG-014 after the required A2A2H per-tick upstream-port check was clean. The higher P0 credential/history-scrub items (BACKLOG-005/BACKLOG-006) remain blocked on a coordinated credential rotation / history scrub window, while BACKLOG-014 is a safe communication-delivery item that can be advanced with non-destructive verification.

## Required context checked
- Policy: `/opt/cto/wiki/continuous-work-policy.md`.
- A2A2H maintenance: `/opt/cto/wiki/A2A2H_MAINTENANCE.md` and `/opt/cto/wiki/A2A2H_LAST_SYNC.md`.
- Heartbeat: `/opt/cto/HEARTBEAT.md`.
- Backlog: `/opt/cto/BACKLOG.md` and `logs/backlog/BACKLOG-014.json`.
- Recent PWA chat: `/opt/cto/logs/pwa-chat/2026-05-27.md` and late 2026-05-26 directive context.
- Recent failed verification: `logs/repairs/BACKLOG-004-runtime-voice-ui-verification-2026-05-27T0140Z.md` and `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T020411Z.md`.

## A2A2H per-tick check
Command scope: `git log bfe5ad51f99dd15019ebb3dbd510b73d0ea49072..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py`.

Result: no upstream-eligible CTO commits after the last synced SHA. No A2A2H port required this tick.

## Service health snapshot
- `systemctl --user --failed`: 0 failed units.
- Loopback listeners present: PWA backend `127.0.0.1:8088`, Hermes A2A sidecar `127.0.0.1:8643`, Hermes gateway `127.0.0.1:8642`, OpenClaw gateway `127.0.0.1:18789`.
- The latest Hermes work-pump reliability artifact still reports `agent_incomplete`; no restart was attempted in this tick because the recovery cooldown was active and this tick selected the higher-priority PWA delivery verification item.

## Runtime verification
Performed against the live local PWA backend at `127.0.0.1:8088` using a temporary session cookie. The PWA auth token was read from `/opt/cto/.env` but was not printed or recorded.

Results:
- `POST /api/login`: `303` and session cookie issued.
- Authenticated `GET /`: `200` and the shell contains visible `id="enable-push"` / `Test push` UI.
- Authenticated `GET /static/app.js`: client code requests notification permission, subscribes through `/api/push/subscribe`, and exposes `/api/push/test` from the visible button path.
- Authenticated `GET /static/service-worker.js`: `SHELL_CACHE = "cto-shell-v8"`, push events call `showNotification`, and notification clicks focus/open the PWA.
- Authenticated `GET /api/push/vapid_public_key`: returned a non-empty public key without exposing private key material.
- Stored push subscription files: `1` present under the runtime subscription directory.

This verifies that the live backend is serving the visible push self-test UI and that the runtime push prerequisites are present. It intentionally did not call `/api/push/test` in this unattended cron tick, to avoid sending John an unsolicited device notification.

## Regression gates
- `python3 -m unittest -v tests/test_pwa_routing.py tests/test_pwa_voice_ui.py` — 29/29 passed.
- `scripts/security/run-safe-security-gates.sh` — passed:
  - secret artifact guard scanned 301 source-visible files;
  - operational redaction check scanned 164 file(s) plus `chat.db`;
  - install secret-handling guard passed;
  - credential rotation preflight syntax passed;
  - credential rotation preflight runtime names-only check returned `ready_for_coordinated_rotation_window`;
  - redaction unit tests passed;
  - PWA auth/routing tests passed;
  - PWA voice UI regression passed.

## Result
BACKLOG-014 advanced from code/UI implementation to live runtime verification of the visible push self-test path and runtime prerequisites. The item remains open because final closure still requires John/device confirmation that tapping the visible Test push button on his phone displays the background notification.
