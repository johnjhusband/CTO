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

        self.assertEqual(counts, {"url_query_token": 3})
        self.assertIn("?token=REDACTED&since_id=1", redacted)
        self.assertIn("&token=REDACTED#frag", redacted)
        self.assertIn("%3Ftoken%3DREDACTED", redacted)
        self.assertNotIn("legacy-secret", redacted)
        self.assertNotIn("another-secret", redacted)
        self.assertNotIn("urlencoded-secret", redacted)

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

        self.assertEqual(counts, {"authorization_bearer": 2, "pwa_session_cookie": 1})
        self.assertIn("Authorization: Bearer REDACTED", redacted)
        self.assertIn("Authorization=Bearer REDACTED", redacted)
        self.assertIn("cto_pwa_session=REDACTED;", redacted)
        self.assertNotIn("live-a2a-token", redacted)
        self.assertNotIn("another-token", redacted)
        self.assertNotIn("session-secret", redacted)


if __name__ == "__main__":
    unittest.main()
