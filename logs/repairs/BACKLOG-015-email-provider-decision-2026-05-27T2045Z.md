# BACKLOG-015 email provider decision — 2026-05-27T20:45Z

- A2A2H per-tick check: no upstream-eligible CTO drift since `6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3`; no port required.
- Backlog completion scan: no P0/P1 item was safely closable from disk evidence. P0 history/credential work still needs coordinated destructive/rotation windows; PWA voice/push/audit/chat visible items still need John phone evidence.
- Hermes: semantic delegation skipped because `.cache/hermes-work-pump-provider-failure.json` shows the provider circuit open (`agent_incomplete_provider_NoneType`).
- Selected item: BACKLOG-015, because John explicitly told CTO not to leave outbound email as an adapter/credential decision forever, and higher-priority items were blocked.
- Evidence: the existing SMTP credential check failed with Gmail `535 Username and Password not accepted`; no secret values were printed or stored.
- Decision: CTO-DECISION-022 adopts a non-Google transactional email API path, with Resend as the first implemented provider target.
- Artifact shipped: `scripts/send-status-email.py` now supports `CTO_EMAIL_PROVIDER=resend` + `CTO_EMAIL_API_KEY` via HTTP API, while keeping SMTP fallback; `tests/test_send_status_email.py` covers API-key name-only validation and mocked send payloads.
- Verification: `python3 -m unittest -v tests/test_send_status_email.py` passed (5/5). `python3 scripts/send-status-email.py --dry-run --subject 'CTO status smoke'` produced metadata only and sent no email.
- Remaining blocker: runtime still needs a non-Google provider API key/from-domain in the secret store before scheduled or event-triggered email sends can be enabled.
