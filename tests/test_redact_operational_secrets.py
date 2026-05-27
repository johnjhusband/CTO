#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
from pathlib import Path
import unittest


def load_redactor():
    path = Path(__file__).resolve().parents[1] / "scripts" / "security" / "redact-operational-secrets.py"
    spec = importlib.util.spec_from_file_location("redact_operational_secrets", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


redactor = load_redactor()


class RedactOperationalSecretsTests(unittest.TestCase):
    def test_redacts_runtime_token_names_missing_from_initial_gate(self):
        text = (
            "HERMES_A2A_TOKEN=abc123\n"
            "API_SERVER_KEY='server-secret'\n"
            'NAMECHEAP_API_KEY="namecheap-secret"\n'
            "CTO_EMAIL_SMTP_PASSWORD=smtp-secret\n"
        )

        redacted, counts = redactor.redact_text(text)

        self.assertNotIn("abc123", redacted)
        self.assertNotIn("server-secret", redacted)
        self.assertNotIn("namecheap-secret", redacted)
        self.assertNotIn("smtp-secret", redacted)
        self.assertEqual(counts["env:HERMES_A2A_TOKEN"], 1)
        self.assertEqual(counts["env:API_SERVER_KEY"], 1)
        self.assertEqual(counts["env:NAMECHEAP_API_KEY"], 1)
        self.assertEqual(counts["env:CTO_EMAIL_SMTP_PASSWORD"], 1)

    def test_leaves_existing_placeholders_safe(self):
        text = "HERMES_A2A_TOKEN=REDACTED\nAPI_SERVER_KEY=<set>\n"

        redacted, counts = redactor.redact_text(text)

        self.assertEqual(redacted, text)
        self.assertEqual(counts, {})


    def test_leaves_angle_bracket_placeholders_safe(self):
        text = "PWA_AUTH_TOKEN=<from /opt/cto/.env> pytest tests/test_pwa_chat_first_layout.py\n"

        redacted, counts = redactor.redact_text(text)

        self.assertEqual(redacted, text)
        self.assertEqual(counts, {})

    def test_does_not_report_secret_values_in_counts(self):
        _, counts = redactor.redact_text("GOOGLE_ACCOUNT_PASSWORD_PENDING=super-secret-value\n")

        rendered = repr(counts)
        self.assertIn("env:GOOGLE_ACCOUNT_PASSWORD_PENDING", rendered)
        self.assertNotIn("super-secret-value", rendered)

    def test_redacts_legacy_pwa_query_token_values(self):
        redacted, counts = redactor.redact_text(
            "GET /api/stream?token=legacy-secret&since_id=1 HTTP/1.1\n"
            "https://cto.example/?x=1&token=another-secret#frag\n"
            "encoded=%2F%3Ftoken%3Durlencoded-secret\n"
        )

        self.assertEqual(counts, {"url_query_secret": 3})
        self.assertIn("?token=REDACTED&since_id=1", redacted)
        self.assertIn("&token=REDACTED#frag", redacted)
        self.assertIn("%3Ftoken%3DREDACTED", redacted)
        self.assertNotIn("legacy-secret", redacted)
        self.assertNotIn("another-secret", redacted)
        self.assertNotIn("urlencoded-secret", redacted)

    def test_redacts_adjacent_url_query_secret_names(self):
        redacted, counts = redactor.redact_text(
            "/callback?access_token=access-secret&api_key=api-secret&ok=1\n"
            "encoded=%26auth_token%3Dauth-secret\n"
        )

        self.assertEqual(counts, {"url_query_secret": 3})
        self.assertIn("access_token=REDACTED", redacted)
        self.assertIn("api_key=REDACTED", redacted)
        self.assertIn("%26auth_token%3DREDACTED", redacted)
        self.assertNotIn("access-secret", redacted)
        self.assertNotIn("api-secret", redacted)
        self.assertNotIn("auth-secret", redacted)

    def test_redacts_natural_language_password_pastes(self):
        redacted, counts = redactor.redact_text("@hermes the pw is pasted-secret\n")

        self.assertEqual(counts, {"chat_password_phrase": 1})
        self.assertEqual(redacted, "@hermes the pw is REDACTED\n")
        self.assertNotIn("pasted-secret", redacted)

    def test_redacts_http_auth_headers_and_pwa_session_cookies(self):
        redacted, counts = redactor.redact_text(
            "Authorization: Bearer live-a2a-token\n"
            "Authorization=Bearer another-token\n"
            "Cookie: cto_pwa_session=session-secret; other=1\n"
        )

        self.assertEqual(counts, {"authorization_bearer": 2, "session_cookie": 1})
        self.assertIn("Authorization: Bearer REDACTED", redacted)
        self.assertIn("Authorization=Bearer REDACTED", redacted)
        self.assertIn("cto_pwa_session=REDACTED;", redacted)
        self.assertNotIn("live-a2a-token", redacted)
        self.assertNotIn("another-token", redacted)
        self.assertNotIn("session-secret", redacted)

    def test_redacts_sensitive_http_headers_and_generic_session_cookies(self):
        redacted, counts = redactor.redact_text(
            "X-API-Key: api-secret\n"
            "x-auth-token=auth-secret\n"
            "Cookie: session=generic-session; sid=short-session\n"
        )

        self.assertEqual(counts, {"sensitive_header": 2, "session_cookie": 2})
        self.assertIn("X-API-Key: REDACTED", redacted)
        self.assertIn("x-auth-token=REDACTED", redacted)
        self.assertIn("session=REDACTED;", redacted)
        self.assertIn("sid=REDACTED", redacted)
        self.assertNotIn("api-secret", redacted)
        self.assertNotIn("auth-secret", redacted)
        self.assertNotIn("generic-session", redacted)
        self.assertNotIn("short-session", redacted)


if __name__ == "__main__":
    unittest.main()
