import importlib.util
import os
from pathlib import Path
from unittest import TestCase, mock


MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "send-status-email.py"


def load_module():
    spec = importlib.util.spec_from_file_location("send_status_email", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class SendStatusEmailCredentialCheckTests(TestCase):
    def setUp(self):
        self.module = load_module()

    def test_check_credentials_logs_in_without_sending_message(self):
        env = {
            "CTO_EMAIL_SMTP_HOST": "smtp.example.test",
            "CTO_EMAIL_SMTP_PORT": "465",
            "CTO_EMAIL_SMTP_USER": "user@example.test",
            "CTO_EMAIL_SMTP_PASSWORD": "secret-password",
        }
        smtp = mock.Mock()
        smtp.__enter__ = mock.Mock(return_value=smtp)
        smtp.__exit__ = mock.Mock(return_value=None)
        with mock.patch.dict(os.environ, env, clear=True), mock.patch.object(
            self.module.smtplib, "SMTP_SSL", return_value=smtp
        ) as smtp_ssl:
            self.module.check_credentials()

        smtp_ssl.assert_called_once_with("smtp.example.test", 465, timeout=30)
        smtp.login.assert_called_once_with("user@example.test", "secret-password")
        smtp.send_message.assert_not_called()

    def test_missing_credentials_report_names_not_values(self):
        with mock.patch.dict(os.environ, {"CTO_EMAIL_SMTP_PASSWORD": "secret-password"}, clear=True):
            with self.assertRaises(RuntimeError) as raised:
                self.module.check_credentials()

        message = str(raised.exception)
        self.assertIn("CTO_EMAIL_SMTP_HOST", message)
        self.assertIn("CTO_EMAIL_SMTP_USER", message)
        self.assertNotIn("secret-password", message)
