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

    def test_resend_provider_check_requires_api_key_name_only(self):
        with mock.patch.dict(os.environ, {"CTO_EMAIL_PROVIDER": "resend"}, clear=True):
            with self.assertRaises(RuntimeError) as raised:
                self.module.check_credentials()

        self.assertIn("CTO_EMAIL_API_KEY", str(raised.exception))

    def test_resend_provider_check_does_not_send_or_print_secret(self):
        with mock.patch.dict(
            os.environ,
            {"CTO_EMAIL_PROVIDER": "resend", "CTO_EMAIL_API_KEY": "resend-secret"},
            clear=True,
        ), mock.patch.object(self.module.request, "urlopen") as urlopen:
            self.module.check_credentials()

        urlopen.assert_not_called()


class SendStatusEmailResendTests(TestCase):
    def setUp(self):
        self.module = load_module()

    def test_send_message_resend_posts_plaintext_payload(self):
        env = {
            "CTO_EMAIL_PROVIDER": "resend",
            "CTO_EMAIL_API_KEY": "resend-secret",
            "CTO_EMAIL_FROM": "CTO <cto@example.test>",
            "CTO_EMAIL_TO": "john@example.test",
        }
        response = mock.Mock()
        response.__enter__ = mock.Mock(return_value=response)
        response.__exit__ = mock.Mock(return_value=None)
        response.status = 200

        with mock.patch.dict(os.environ, env, clear=True), mock.patch.object(
            self.module.request, "urlopen", return_value=response
        ) as urlopen:
            msg = self.module.build_message("Status", "Body text")
            self.module.send_message(msg)

        req = urlopen.call_args.args[0]
        self.assertEqual(req.full_url, self.module.DEFAULT_RESEND_API_URL)
        self.assertEqual(req.get_method(), "POST")
        self.assertEqual(req.headers["Authorization"], "Bearer resend-secret")
        body = req.data.decode("utf-8")
        self.assertIn('"from": "CTO <cto@example.test>"', body)
        self.assertIn('"to": ["john@example.test"]', body)
        self.assertIn('"subject": "Status"', body)
        self.assertIn('"text": "Body text\\n"', body)
