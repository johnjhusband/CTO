# BACKLOG-016 runtime visible A2A coordination UI verification — 2026-05-27T02:18Z

## Selection
OpenClaw continuous work pump selected BACKLOG-016 after the required state inspection. Higher P0 security/history items remain blocked on coordinated credential rotation / public history scrub windows. BACKLOG-014 had just been runtime-verified and committed, so the next safe human-interface P0 was visible inter-hemisphere coordination.

## Required context checked
- Recent PWA chat showed Hermes A2A `agent_incomplete` errors still being captured as sanitized a2a_response rows.
- `systemctl --user --failed` reported 0 failed user units.
- PWA backend, OpenClaw gateway, Hermes gateway, and Hermes A2A sidecar were active.
- A2A2H per-tick check found no upstream-eligible CTO chat-bridge drift; commits since the last sync only touched CTO operational/security paths.

## Runtime verification
Performed against the live local PWA backend at `127.0.0.1:8088` using a temporary authenticated session. The PWA auth token was read from `/opt/cto/.env` but was not printed or recorded.

Results:
- Login issued a session cookie (`303`).
- Authenticated `GET /` returned `200` and contained `id="toggle-a2a"` plus the visible label `Show agent coordination`.
- Authenticated `GET /static/app.js` contains the A2A rendering path for `m.kind.startsWith("a2a_")`, `a2a-capability`, and `Raw JSON` details.
- Authenticated `GET /static/style.css` hides A2A rows by default with `body:not(.show-a2a) .msg.a2a { display: none; }`.
- Authenticated `/api/messages` returned live A2A audit rows visible to the client, including both `a2a_request` and `a2a_response` kinds.

## Regression gates
- `python3 -m unittest -v tests/test_pwa_routing.py tests/test_pwa_voice_ui.py` passed: 29/29.
- `scripts/security/run-safe-security-gates.sh` passed:
  - secret artifact guard;
  - operational redaction check across logs plus `chat.db`;
  - install secret-handling guard;
  - credential rotation preflight syntax;
  - credential rotation preflight runtime names/status-only check returned `ready_for_coordinated_rotation_window`;
  - redaction tests;
  - PWA auth/routing tests;
  - PWA voice UI test.

## Result
BACKLOG-016 advanced from regression coverage to live runtime verification that the authenticated PWA serves the visible Show agent coordination UI and exposes live A2A audit rows. The item remains open because final closure still requires John/device confirmation that the phone PWA shows and uses the toggle as expected.
