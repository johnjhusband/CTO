#!/usr/bin/env python3
"""Redact secret values from CTO operational logs and chat transcripts.

The script intentionally reports only path/marker/count metadata, never matched values.
Default mode is --check. Use --apply to rewrite matching log files and chat.db rows.
"""
from __future__ import annotations

import argparse
import os
import re
import sqlite3
import tempfile
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[2]
TARGET_DIRS = [ROOT / "logs"]
CHAT_DB = ROOT / "chat.db"

SECRET_ENV_NAMES = [
    "GITHUB_TOKEN",
    "GITHUB_PERSONAL_ACCESS_TOKEN",
    "HETZNER_API_TOKEN",
    "HERMES_API_SERVER_KEY",
    "API_SERVER_KEY",
    "HERMES_A2A_TOKEN",
    "OPENAI_API_KEY",
    "OPENROUTER_API_KEY",
    "BRAVE_API_KEY",
    "PWA_AUTH_TOKEN",
    "VAPID_PRIVATE_KEY",
    "MAILGUN_API_KEY",
    "SMTP_PASSWORD",
    "CTO_EMAIL_SMTP_PASSWORD",
    "NAMECHEAP_PASS",
    "NAMECHEAP_API_KEY",
    "GOOGLE_ACCOUNT_PASSWORD_PENDING",
]

# Keep assignment syntax and redact only the value. Values in logs may be bare,
# single-quoted, or double-quoted. Stop at shell/log separators without consuming
# surrounding prose. Variable names are not secrets, values are.
ENV_ASSIGNMENT_RE = re.compile(
    r"(?P<prefix>\b(?:" + "|".join(map(re.escape, SECRET_ENV_NAMES)) + r")\s*=\s*)"
    r"(?:(?P<quote>['\"])(?P<valueq>.*?)(?P=quote)|(?P<valueb>[^\s'\";]+))",
    re.DOTALL,
)

TOKEN_PATTERNS = [
    ("github_token", re.compile(r"gh[pousr]_[A-Za-z0-9_]{20,}")),
    ("openai_key", re.compile(r"sk-[A-Za-z0-9_-]{20,}")),
    ("private_key_block", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----", re.DOTALL)),
]

TEXT_EXTENSIONS = {
    ".log", ".md", ".json", ".txt", ".env", ".out", ".err", ".yaml", ".yml"
}
MAX_FILE_BYTES = 8 * 1024 * 1024


def iter_files() -> Iterable[Path]:
    for target in TARGET_DIRS:
        if target.is_file():
            yield target
        elif target.exists():
            for dirpath, _, filenames in os.walk(target):
                for filename in filenames:
                    path = Path(dirpath) / filename
                    if path.suffix in TEXT_EXTENSIONS or "log" in path.name.lower():
                        yield path


def redact_text(text: str) -> tuple[str, dict[str, int]]:
    counts: dict[str, int] = {}

    def repl_env(match: re.Match[str]) -> str:
        value = match.group("valueq") if match.group("quote") else match.group("valueb")
        quote = match.group("quote") or ""
        # Already-sanitized values/placeholders are safe and should not keep the check failing.
        safe_values = {"", "REDACTED", "<set>", "<redacted>", "***", "xxxxx"}
        normalized = (value or "").strip()
        if normalized.startswith("REDACTED") or normalized in safe_values:
            return match.group(0)
        name = match.group("prefix").split("=", 1)[0].strip()
        counts[f"env:{name}"] = counts.get(f"env:{name}", 0) + 1
        return f"{match.group('prefix')}{quote}REDACTED{quote}"

    text = ENV_ASSIGNMENT_RE.sub(repl_env, text)

    for marker, pattern in TOKEN_PATTERNS:
        def repl_token(match: re.Match[str], marker: str = marker) -> str:
            counts[marker] = counts.get(marker, 0) + 1
            return "REDACTED"
        text = pattern.sub(repl_token, text)

    return text, counts


def scan_or_apply_file(path: Path, apply: bool) -> dict[str, int]:
    try:
        if path.stat().st_size > MAX_FILE_BYTES:
            return {}
        original = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return {}
    redacted, counts = redact_text(original)
    if apply and counts and redacted != original:
        fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=str(path.parent), text=True)
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(redacted)
        os.replace(tmp_name, path)
    return counts


def scan_or_apply_chat_db(apply: bool) -> list[tuple[int, dict[str, int]]]:
    if not CHAT_DB.exists():
        return []
    conn = sqlite3.connect(CHAT_DB)
    try:
        rows = conn.execute("SELECT id, content FROM messages").fetchall()
        hits: list[tuple[int, dict[str, int]]] = []
        updates: list[tuple[str, int]] = []
        for row_id, content in rows:
            redacted, counts = redact_text(content or "")
            if counts:
                hits.append((int(row_id), counts))
                if apply and redacted != content:
                    updates.append((redacted, int(row_id)))
        if apply and updates:
            conn.executemany("UPDATE messages SET content = ? WHERE id = ?", updates)
            conn.commit()
        return hits
    finally:
        conn.close()


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="report unredacted secret markers (default)")
    mode.add_argument("--apply", action="store_true", help="redact matching values in-place")
    args = parser.parse_args()
    apply = args.apply

    total_hits = 0
    scanned_files = 0
    for path in iter_files():
        scanned_files += 1
        counts = scan_or_apply_file(path, apply)
        if counts:
            total_hits += sum(counts.values())
            markers = ",".join(f"{k}:{v}" for k, v in sorted(counts.items()))
            print(f"{'REDACTED' if apply else 'FOUND'} file={path.relative_to(ROOT)} markers={markers}")

    chat_hits = scan_or_apply_chat_db(apply)
    for row_id, counts in chat_hits:
        total_hits += sum(counts.values())
        markers = ",".join(f"{k}:{v}" for k, v in sorted(counts.items()))
        print(f"{'REDACTED' if apply else 'FOUND'} chat_db_row={row_id} markers={markers}")

    if total_hits:
        action = "redacted" if apply else "found"
        print(f"Operational secret redaction {action} {total_hits} marker(s) across {scanned_files} file(s) plus chat.db.")
        return 0 if apply else 1

    print(f"Operational secret redaction check passed: scanned {scanned_files} file(s) plus chat.db; no unredacted markers found.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
