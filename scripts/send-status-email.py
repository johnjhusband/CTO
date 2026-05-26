#!/usr/bin/env python3
"""Send CTO status updates by SMTP when credentials are configured.

Secrets are read only from environment variables and never from repo files:
  CTO_EMAIL_SMTP_HOST, CTO_EMAIL_SMTP_PORT, CTO_EMAIL_SMTP_USER,
  CTO_EMAIL_SMTP_PASSWORD, CTO_EMAIL_FROM, CTO_EMAIL_TO

Use --dry-run to validate message construction without sending.
"""
from __future__ import annotations

import argparse
import os
import smtplib
import sys
from email.message import EmailMessage
from pathlib import Path

DEFAULT_TO = "john@husband.llc"


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


def send_message(msg: EmailMessage) -> None:
    required = ["CTO_EMAIL_SMTP_HOST", "CTO_EMAIL_SMTP_USER", "CTO_EMAIL_SMTP_PASSWORD"]
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise RuntimeError("missing email credentials: " + ", ".join(missing))
    host = os.environ["CTO_EMAIL_SMTP_HOST"]
    port = int(os.environ.get("CTO_EMAIL_SMTP_PORT", "465"))
    with smtplib.SMTP_SSL(host, port, timeout=30) as smtp:
        smtp.login(os.environ["CTO_EMAIL_SMTP_USER"], os.environ["CTO_EMAIL_SMTP_PASSWORD"])
        smtp.send_message(msg)


def main() -> int:
    parser = argparse.ArgumentParser(description="Send CTO status email to John")
    parser.add_argument("--subject", default="CTO status update")
    parser.add_argument("--body-file", help="File to send; defaults to latest logs/digest/digest-*.md or stdin")
    parser.add_argument("--dry-run", action="store_true", help="Build and print metadata without sending")
    args = parser.parse_args()

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
        print(f"dry-run: would send to {msg['To']} from {msg['From']} subject {msg['Subject']!r} ({len(body)} chars)")
        return 0
    send_message(msg)
    print(f"sent status email to {msg['To']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
