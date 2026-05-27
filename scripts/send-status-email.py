#!/usr/bin/env python3
"""Send CTO status updates by email when credentials are configured.

Secrets are read only from environment variables and never from repo files.

Preferred no-Google path for regular status mail:
  CTO_EMAIL_PROVIDER=resend, CTO_EMAIL_API_KEY, CTO_EMAIL_FROM, CTO_EMAIL_TO

Legacy SMTP fallback:
  CTO_EMAIL_SMTP_HOST, CTO_EMAIL_SMTP_PORT, CTO_EMAIL_SMTP_USER,
  CTO_EMAIL_SMTP_PASSWORD, CTO_EMAIL_FROM, CTO_EMAIL_TO

Use --dry-run to validate message construction without sending.
"""
from __future__ import annotations

import argparse
import json
import os
import smtplib
import ssl
import sys
from email.message import EmailMessage
from pathlib import Path
from urllib import request

DEFAULT_TO = "john@husband.llc"
DEFAULT_RESEND_API_URL = "https://api.resend.com/emails"


def latest_digest(root: Path = Path("/opt/cto/logs/digest")) -> Path | None:
    if not root.exists():
        return None
    files = sorted(root.glob("digest-*.md"))
    return files[-1] if files else None


def build_message(subject: str, body: str) -> EmailMessage:
    sender = os.environ.get("CTO_EMAIL_FROM") or os.environ.get("CTO_EMAIL_SMTP_USER") or "cto@husband.llc"
    recipient = os.environ.get("CTO_EMAIL_TO", DEFAULT_TO)
    msg = EmailMessage()
    msg["From"] = sender
    msg["To"] = recipient
    msg["Subject"] = subject
    msg.set_content(body)
    return msg


def smtp_config() -> tuple[str, int, str, str]:
    required = ["CTO_EMAIL_SMTP_HOST", "CTO_EMAIL_SMTP_USER", "CTO_EMAIL_SMTP_PASSWORD"]
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise RuntimeError("missing email credentials: " + ", ".join(missing))
    host = os.environ["CTO_EMAIL_SMTP_HOST"]
    port = int(os.environ.get("CTO_EMAIL_SMTP_PORT", "465"))
    user = os.environ["CTO_EMAIL_SMTP_USER"]
    password = os.environ["CTO_EMAIL_SMTP_PASSWORD"]
    return host, port, user, password


def configured_provider() -> str:
    """Return the selected outbound provider without reading secret values."""
    provider = os.environ.get("CTO_EMAIL_PROVIDER", "").strip().lower()
    if provider:
        return provider
    if os.environ.get("CTO_EMAIL_API_KEY"):
        return "resend"
    return "smtp"


def with_authenticated_smtp():
    host, port, user, password = smtp_config()
    if port == 465:
        smtp = smtplib.SMTP_SSL(host, port, timeout=30)
        smtp.login(user, password)
        return smtp
    smtp = smtplib.SMTP(host, port, timeout=30)
    smtp.ehlo()
    smtp.starttls(context=ssl.create_default_context())
    smtp.ehlo()
    smtp.login(user, password)
    return smtp


def check_credentials() -> None:
    """Verify provider credentials without sending a message or printing secret values."""
    if configured_provider() == "resend":
        resend_config()
        return
    with with_authenticated_smtp() as smtp:
        try:
            smtp.noop()
        except Exception:
            # Some providers reject NOOP after login; successful login is sufficient.
            pass


def send_message(msg: EmailMessage) -> None:
    if configured_provider() == "resend":
        send_message_resend(msg)
        return
    with with_authenticated_smtp() as smtp:
        smtp.send_message(msg)


def resend_config() -> tuple[str, str]:
    api_key = os.environ.get("CTO_EMAIL_API_KEY", "")
    if not api_key:
        raise RuntimeError("missing email credentials: CTO_EMAIL_API_KEY")
    return os.environ.get("CTO_EMAIL_API_URL", DEFAULT_RESEND_API_URL), api_key


def send_message_resend(msg: EmailMessage) -> None:
    """Send a plaintext status email through Resend's HTTP API."""
    url, api_key = resend_config()
    payload = {
        "from": msg["From"],
        "to": [addr.strip() for addr in str(msg["To"]).split(",") if addr.strip()],
        "subject": msg["Subject"],
        "text": msg.get_content(),
    }
    req = request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with request.urlopen(req, timeout=30) as resp:
        if getattr(resp, "status", 200) >= 400:
            raise RuntimeError(f"email provider returned HTTP {resp.status}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Send CTO status email to John")
    parser.add_argument("--subject", default="CTO status update")
    parser.add_argument("--body-file", help="File to send; defaults to latest logs/digest/digest-*.md or stdin")
    parser.add_argument("--dry-run", action="store_true", help="Build and print metadata without sending")
    parser.add_argument(
        "--check-credentials",
        action="store_true",
        help="Verify SMTP login without sending a message or printing secret values",
    )
    args = parser.parse_args()

    if args.check_credentials:
        check_credentials()
        provider = configured_provider()
        if provider == "resend":
            print("email credential check passed: Resend API key present; no message sent")
        else:
            print("smtp credential check passed: login accepted; no message sent")
        return 0

    if args.body_file:
        body_path = Path(args.body_file)
        body = body_path.read_text()
    else:
        digest = latest_digest()
        body = digest.read_text() if digest else sys.stdin.read()
    if not body.strip():
        raise RuntimeError("no email body provided and no digest file found")

    msg = build_message(args.subject, body)
    if args.dry_run:
        print(
            f"dry-run: would send via {configured_provider()} to {msg['To']} "
            f"from {msg['From']} subject {msg['Subject']!r} ({len(body)} chars)"
        )
        return 0
    send_message(msg)
    print(f"sent status email to {msg['To']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
