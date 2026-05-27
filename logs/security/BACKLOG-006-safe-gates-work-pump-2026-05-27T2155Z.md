# BACKLOG-006 safe credential/security gate verification

- Timestamp: 2026-05-27T21:55:07Z
- Selected item: BACKLOG-006 — rotate live service credentials and remove secret values from operational logs/history.
- A2A2H per-tick check: no upstream-eligible CTO commits since tracker SHA 6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3; no port required.
- Backlog completion scan: 11 open/pending items found; none were observably complete without John phone verification, coordinated live credential rotation, destructive history rewrite approval/window, external-provider credentials, or privileged host action.
- Hermes delegation: skipped; provider state: consecutive_failures=2 reason=agent_incomplete_provider_NoneType last_failure_utc=2026-05-27T21:40:26Z last_circuit_notice_utc=2026-05-27T21:42:32Z.
- Verification command: scripts/security/run-safe-security-gates.sh

== secret artifact guard ==
Secret artifact guard passed: scanned 567 source-visible files.

== operational secret redaction check ==
Operational secret redaction check passed: scanned 400 file(s) plus chat.db; no unredacted markers found.

== install secret-handling guard ==
Install secret-handling guard passed: checked scripts/install.sh metadata only.

== credential rotation preflight syntax ==

== credential rotation smoke syntax ==

== credential rotation plan syntax ==

== credential rotation preflight (names only) ==
Credential rotation preflight (no secret values printed)
env_file=/opt/cto/.env owner=cto:cto mode=600

Required credential names:
- HETZNER_API_TOKEN: present_nonempty
- GITHUB_TOKEN: present_nonempty
- HERMES_API_SERVER_KEY: present_nonempty
- HERMES_A2A_TOKEN: present_nonempty
- OPENAI_API_KEY: present_nonempty
- PWA_AUTH_TOKEN: present_nonempty

Optional/retired credential names to reconcile during rotation window:
- CTO_EMAIL_SMTP_PASSWORD: present_nonempty
- GOOGLE_ACCOUNT_PASSWORD_PENDING: present_nonempty
- OPENROUTER_API_KEY: present_nonempty

Dependent user services:
- openclaw-gateway.service: active
- hermes-gateway.service: active
- cto-hermes-a2a-sidecar.service: active
- cto-pwa-backend.service: active
- cto-a2a-registry.service: active

Recommended coordinated order (names only):
1. Prepare replacement values out of band for all present required names.
2. Update /opt/cto/.env atomically with mode 600 and no shell history echo.
3. Restart dependent user services in a controlled window.
4. Verify PWA auth, Hermes A2A, OpenClaw gateway, embeddings, GitHub, and Hetzner paths.
5. Revoke superseded provider credentials only after verification.
6. Run scripts/security/run-safe-security-gates.sh and record evidence.

Preflight result: ready_for_coordinated_rotation_window

== credential rotation plan check (metadata only) ==
Credential rotation coordinated plan check (metadata only)
root=/opt/cto

Required local artifacts:
- scripts/security/rotation-preflight.sh: executable
- scripts/security/rotation-smoke.sh: executable
- scripts/security/redact-operational-secrets.py: executable
- scripts/security/check-git-history-secret-markers.sh: executable
- scripts/security/run-safe-security-gates.sh: executable

Artifact syntax:
- scripts/security/rotation-preflight.sh: syntax_ok
- scripts/security/rotation-smoke.sh: syntax_ok
- scripts/security/check-git-history-secret-markers.sh: syntax_ok
- scripts/security/run-safe-security-gates.sh: syntax_ok
- scripts/security/redact-operational-secrets.py: syntax_ok

Secret store hygiene:
- env_file: present owner=cto:cto mode=600
Required credential names:
- HETZNER_API_TOKEN: present_nonempty
- GITHUB_TOKEN: present_nonempty
- HERMES_API_SERVER_KEY: present_nonempty
- HERMES_A2A_TOKEN: present_nonempty
- OPENAI_API_KEY: present_nonempty
- PWA_AUTH_TOKEN: present_nonempty

Dependent restart/verification order (names only):
- openclaw-gateway.service: active
- hermes-gateway.service: active
- cto-hermes-a2a-sidecar.service: active
- cto-pwa-backend.service: active
- cto-a2a-registry.service: active

Required operator actions outside this script:
1. Prepare replacement credential values out of band; do not paste them into chat/logs.
2. Atomically update /opt/cto/.env with mode 600 during the approved rotation window.
3. Restart services in the order above and run rotation-smoke plus safe security gates.
4. Revoke superseded external credentials only after local verification succeeds.
5. Decide separately whether to coordinate public git-history rewrite or risk acceptance.

Plan check result: ready_for_coordinated_rotation_window

== credential rotation smoke check (no values) ==
Credential rotation smoke check (no secret values printed)
env_file=/opt/cto/.env owner=cto:cto mode=600

Dependent user services:
- openclaw-gateway.service: active
- hermes-gateway.service: active
- cto-hermes-a2a-sidecar.service: active
- cto-pwa-backend.service: active
- cto-a2a-registry.service: active

Local health endpoints:
- openclaw-gateway: ok (27 bytes)
- hermes-gateway: ok (44 bytes)
- hermes-a2a-sidecar: ok (49 bytes)
- pwa-backend: ok (42 bytes)

Smoke result: local_services_healthy

== redaction unit tests ==
test_does_not_report_secret_values_in_counts (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_does_not_report_secret_values_in_counts) ... ok
test_leaves_angle_bracket_placeholders_safe (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_leaves_angle_bracket_placeholders_safe) ... ok
test_leaves_existing_placeholders_safe (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_leaves_existing_placeholders_safe) ... ok
test_redacts_adjacent_url_query_secret_names (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_adjacent_url_query_secret_names) ... ok
test_redacts_http_auth_headers_and_pwa_session_cookies (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_http_auth_headers_and_pwa_session_cookies) ... ok
test_redacts_legacy_pwa_query_token_values (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_legacy_pwa_query_token_values) ... ok
test_redacts_natural_language_password_pastes (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_natural_language_password_pastes) ... ok
test_redacts_runtime_token_names_missing_from_initial_gate (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_runtime_token_names_missing_from_initial_gate) ... ok
test_redacts_sensitive_http_headers_and_generic_session_cookies (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_sensitive_http_headers_and_generic_session_cookies) ... ok

----------------------------------------------------------------------
Ran 9 tests in 0.001s

OK

== credential rotation plan unit tests ==
test_check_only_reports_names_not_values (tests.test_credential_rotation_plan.CredentialRotationPlanTests.test_check_only_reports_names_not_values) ... ok
test_rejects_mutating_modes (tests.test_credential_rotation_plan.CredentialRotationPlanTests.test_rejects_mutating_modes) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.075s

OK

== PWA auth/routing regression tests ==
test_access_log_redacts_legacy_query_token (tests.test_pwa_routing.PwaAccessControlTests.test_access_log_redacts_legacy_query_token) ... ok
test_api_query_token_no_longer_authenticates (tests.test_pwa_routing.PwaAccessControlTests.test_api_query_token_no_longer_authenticates) ... ok
test_auth_rejects_bare_url_without_cookie (tests.test_pwa_routing.PwaAccessControlTests.test_auth_rejects_bare_url_without_cookie) ... ok
test_legacy_stream_query_token_204_access_log_is_suppressed (tests.test_pwa_routing.PwaAccessControlTests.test_legacy_stream_query_token_204_access_log_is_suppressed) ... ok
test_legacy_stream_query_token_stops_eventsource_retry_storm (tests.test_pwa_routing.PwaAccessControlTests.test_legacy_stream_query_token_stops_eventsource_retry_storm) ... ok
test_non_production_without_auth_token_is_dev_mode_only (tests.test_pwa_routing.PwaAccessControlTests.test_non_production_without_auth_token_is_dev_mode_only) ... ok
test_previous_pwa_token_alone_does_not_satisfy_production_startup (tests.test_pwa_routing.PwaAccessControlTests.test_previous_pwa_token_alone_does_not_satisfy_production_startup) ... ok
test_previous_pwa_token_does_not_authenticate_api_query_token (tests.test_pwa_routing.PwaAccessControlTests.test_previous_pwa_token_does_not_authenticate_api_query_token) ... ok
test_previous_pwa_token_keeps_existing_session_valid_during_rotation (tests.test_pwa_routing.PwaAccessControlTests.test_previous_pwa_token_keeps_existing_session_valid_during_rotation) ... ok
test_production_without_auth_token_fails_closed (tests.test_pwa_routing.PwaAccessControlTests.test_production_without_auth_token_fails_closed) ... ok
test_pwa_shell_is_not_public_when_auth_token_configured (tests.test_pwa_routing.PwaAccessControlTests.test_pwa_shell_is_not_public_when_auth_token_configured) ... ok
test_session_cookie_authenticates (tests.test_pwa_routing.PwaAccessControlTests.test_session_cookie_authenticates) ... ok
test_session_cookie_does_not_store_bearer_token (tests.test_pwa_routing.PwaAccessControlTests.test_session_cookie_does_not_store_bearer_token) ... ok
test_static_file_disconnect_does_not_raise (tests.test_pwa_routing.PwaAccessControlTests.test_static_file_disconnect_does_not_raise) ... ok
test_unauthorized_json_responses_are_no_store (tests.test_pwa_routing.PwaAccessControlTests.test_unauthorized_json_responses_are_no_store) ... ok
test_push_payload_truncates_reply_body (tests.test_pwa_routing.PwaPushNotificationTests.test_push_payload_truncates_reply_body) ... ok
test_push_without_vapid_key_degrades_to_noop (tests.test_pwa_routing.PwaPushNotificationTests.test_push_without_vapid_key_degrades_to_noop) ... ok
test_a2a_audit_sanitizer_redacts_obvious_secrets (tests.test_pwa_routing.PwaRoutingTests.test_a2a_audit_sanitizer_redacts_obvious_secrets) ... ok
test_candidate_chat_connection_creates_parent_directory (tests.test_pwa_routing.PwaRoutingTests.test_candidate_chat_connection_creates_parent_directory) ... ok
test_candidate_clone_allows_isolated_chat_db (tests.test_pwa_routing.PwaRoutingTests.test_candidate_clone_allows_isolated_chat_db) ... ok
test_candidate_clone_rejects_production_chat_db (tests.test_pwa_routing.PwaRoutingTests.test_candidate_clone_rejects_production_chat_db) ... ok
test_chat_append_writes_human_markdown_log_and_skips_a2a_json (tests.test_pwa_routing.PwaRoutingTests.test_chat_append_writes_human_markdown_log_and_skips_a2a_json) ... ok
test_chat_log_helpers_reject_traversal_and_limit_export_range (tests.test_pwa_routing.PwaRoutingTests.test_chat_log_helpers_reject_traversal_and_limit_export_range) ... ok
test_coordinated_both_calls_openclaw_before_hermes (tests.test_pwa_routing.PwaRoutingTests.test_coordinated_both_calls_openclaw_before_hermes) ... ok
test_frontend_has_visible_a2a_coordination_toggle (tests.test_pwa_routing.PwaRoutingTests.test_frontend_has_visible_a2a_coordination_toggle) ... ok
test_frontend_resyncs_history_on_foreground (tests.test_pwa_routing.PwaRoutingTests.test_frontend_resyncs_history_on_foreground) ... ok
test_manifest_icons_exist_and_are_cached_by_service_worker (tests.test_pwa_routing.PwaRoutingTests.test_manifest_icons_exist_and_are_cached_by_service_worker) ... ok
test_openclaw_session_id_base_override_is_bounded_to_utc_day (tests.test_pwa_routing.PwaRoutingTests.test_openclaw_session_id_base_override_is_bounded_to_utc_day) ... ok
test_openclaw_session_id_is_bounded_to_utc_day (tests.test_pwa_routing.PwaRoutingTests.test_openclaw_session_id_is_bounded_to_utc_day) ... ok
test_parse_mention_mixed_openclaw_and_hermes_becomes_coordinated_both (tests.test_pwa_routing.PwaRoutingTests.test_parse_mention_mixed_openclaw_and_hermes_becomes_coordinated_both) ... ok
test_parse_mention_recognizes_explicit_both (tests.test_pwa_routing.PwaRoutingTests.test_parse_mention_recognizes_explicit_both) ... ok
test_production_allows_production_chat_db (tests.test_pwa_routing.PwaRoutingTests.test_production_allows_production_chat_db) ... ok
test_push_device_status_summary_is_bounded_and_non_secret (tests.test_pwa_routing.PwaRoutingTests.test_push_device_status_summary_is_bounded_and_non_secret) ... ok
test_send_to_hermes_reports_a2a_token_mismatch_actionably (tests.test_pwa_routing.PwaRoutingTests.test_send_to_hermes_reports_a2a_token_mismatch_actionably) ... ok
test_send_to_hermes_writes_visible_sanitized_a2a_audit_rows (tests.test_pwa_routing.PwaRoutingTests.test_send_to_hermes_writes_visible_sanitized_a2a_audit_rows) ... ok
test_stale_chat_worker_watchdog_writes_visible_system_event (tests.test_pwa_routing.PwaRoutingTests.test_stale_chat_worker_watchdog_writes_visible_system_event) ... ok
test_voice_device_status_summary_is_bounded_and_non_secret (tests.test_pwa_routing.PwaRoutingTests.test_voice_device_status_summary_is_bounded_and_non_secret) ... ok
test_worker_crash_event_is_visible_in_chat_db_contract (tests.test_pwa_routing.PwaRoutingTests.test_worker_crash_event_is_visible_in_chat_db_contract) ... ok

----------------------------------------------------------------------
Ran 38 tests in 0.256s

OK

== PWA voice UI regression tests ==
test_voice_controls_are_visible_and_cache_bumped (tests.test_pwa_voice_ui.PwaVoiceUiTests.test_voice_controls_are_visible_and_cache_bumped) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.000s

OK

Safe security gates passed.

- Result: PASS — non-destructive credential/security gates remain healthy and ready for a coordinated rotation window.
- Safety boundary: no credentials were rotated/revoked, no secret values printed, no git history rewritten, and no infrastructure changed.
- Remaining blocker: actual live credential rotation/revocation and public-history cleanup require a coordinated external-service window / explicit approval.
