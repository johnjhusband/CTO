# BACKLOG-016 visible coordination UI regression

- Timestamp: 2026-05-26T23:56Z
- Selected item: BACKLOG-016 P0 A2A2H visible inter-hemisphere coordination transcript
- Status: advanced_not_closed
- Why not closed: BACKLOG-016 explicitly requires John/device confirmation that the phone PWA shows and uses the toggle.
- Work done: added `test_frontend_has_visible_a2a_coordination_toggle` to `tests/test_pwa_routing.py`.
- Contract pinned: `index.html` has `Show agent coordination`; `app.js` renders `a2a_*` rows with capability/findings and collapsible `Raw JSON`; `style.css` hides A2A rows until `.show-a2a`; service worker cache is `cto-shell-v7`.
- Verification: `python3 -m unittest -v tests/test_pwa_routing.py` passed 27/27.
- Secret handling: no secrets recorded.
