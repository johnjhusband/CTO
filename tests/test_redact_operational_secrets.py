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


if __name__ == "__main__":
    unittest.main()
