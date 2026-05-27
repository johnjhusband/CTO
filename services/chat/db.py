"""
Shared chat persistence for CTO.

Schema is intentionally minimal — every message is one row. Senders are agents
or "john". Kinds distinguish chat messages from A2A protocol traffic so the PWA
frontend can render them with distinct affordances (different icons/colors)
without losing observability per the v1.1 chat model.

This module is imported by:
  - services/a2a_delegate/server.py   (OpenClaw's MCP tool logs delegations)
  - services/hermes_a2a_sidecar/server.py (logs incoming delegations + responses)
  - services/pwa/backend/server.py    (reads + tails for WebSocket streaming)

The DB file is single-writer-multi-reader; SQLite WAL mode handles concurrency.
"""
from __future__ import annotations
import os
import sqlite3
import time
import json
import re
from typing import Optional, Iterable
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path

CHAT_DB_PATH = os.environ.get("CHAT_DB", "/opt/cto/chat.db")
CTO_ROOT = os.environ.get("CTO_ROOT", "/opt/cto")
CTO_INSTANCE_ID = os.environ.get("CTO_INSTANCE_ID", "production")
PRODUCTION_INSTANCE_IDS = {"production", "prod", "live"}
CHAT_LOG_DIR = Path(os.environ.get("PWA_CHAT_LOG_DIR", "/opt/cto/logs/pwa-chat"))
CHAT_LOG_ENABLED = os.environ.get("PWA_CHAT_LOG_ENABLED", "1").lower() not in {"0", "false", "no"}


def clone_chat_isolation_error(
    *,
    instance_id: str | None = None,
    chat_db: str | None = None,
    cto_root: str | None = None,
) -> str | None:
    """Return an error if a non-production clone is pointed at production chat.

    Clone-test-replace candidates may reuse code and credentials, but they must
    not read from or append to the production PWA chat database. Promotion is the
    explicit moment that flips CTO_INSTANCE_ID/CHAT_DB back to production.
    """
    iid = (instance_id if instance_id is not None else os.environ.get("CTO_INSTANCE_ID", CTO_INSTANCE_ID) or "production").strip()
    root = cto_root if cto_root is not None else os.environ.get("CTO_ROOT", CTO_ROOT) or "/opt/cto"
    db = chat_db if chat_db is not None else os.environ.get("CHAT_DB", CHAT_DB_PATH) or "/opt/cto/chat.db"
    if iid.lower() in PRODUCTION_INSTANCE_IDS:
        return None
    production_db = os.path.abspath(os.path.join(root, "chat.db"))
    actual_db = os.path.abspath(db)
    if actual_db == production_db:
        return (
            f"Candidate clone '{iid}' is configured to use production PWA chat DB "
            f"{production_db}. Set CHAT_DB to an isolated candidate path before startup."
        )
    return None


def assert_clone_chat_isolation(path: str = CHAT_DB_PATH) -> None:
    error = clone_chat_isolation_error(chat_db=path)
    if error:
        raise RuntimeError(error)

SCHEMA = """
CREATE TABLE IF NOT EXISTS messages (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    ts          REAL    NOT NULL,
    sender      TEXT    NOT NULL,    -- 'john' | 'openclaw' | 'hermes' | 'system'
    recipient   TEXT,                 -- target sender if directed; null = broadcast/observable
    kind        TEXT    NOT NULL,    -- 'chat' | 'a2a_request' | 'a2a_response' | 'system_event'
    correlation TEXT,                 -- task_id for A2A traffic; links request<->response
    content     TEXT    NOT NULL     -- body; JSON-encoded for a2a_*, plain text for chat
);
CREATE INDEX IF NOT EXISTS idx_messages_ts ON messages(ts);
CREATE INDEX IF NOT EXISTS idx_messages_correlation ON messages(correlation);
"""

def _init(conn: sqlite3.Connection) -> None:
    try:
        conn.execute("PRAGMA journal_mode=WAL")
    except sqlite3.OperationalError as exc:
        # WAL improves concurrent readers, but a short-lived test or helper can
        # briefly hold a SQLite lock while a fresh process initializes the same
        # DB. Do not fail initialization solely because the WAL toggle could not
        # acquire the lock; the schema creation below is still idempotent and the
        # connection remains usable with SQLite's current journal mode.
        if "locked" not in str(exc).lower():
            raise
    conn.execute("PRAGMA synchronous=NORMAL")
    conn.executescript(SCHEMA)

@contextmanager
def connection(path: str = CHAT_DB_PATH):
    assert_clone_chat_isolation(path)
    parent = os.path.dirname(os.path.abspath(path))
    if parent:
        os.makedirs(parent, exist_ok=True)
    new = not os.path.exists(path)
    conn = sqlite3.connect(path, timeout=30, isolation_level=None)
    try:
        if new:
            _init(conn)
        else:
            # cheap: ensure schema present on existing DBs too (idempotent)
            conn.executescript(SCHEMA)
        yield conn
    finally:
        conn.close()

def append(
    sender: str,
    content: str,
    *,
    recipient: Optional[str] = None,
    kind: str = "chat",
    correlation: Optional[str] = None,
    path: str = CHAT_DB_PATH,
) -> int:
    """Append one message. Returns inserted row id."""
    with connection(path) as conn:
        ts = time.time()
        cur = conn.execute(
            "INSERT INTO messages (ts, sender, recipient, kind, correlation, content) VALUES (?, ?, ?, ?, ?, ?)",
            (ts, sender, recipient, kind, correlation, content),
        )
        row_id = int(cur.lastrowid or 0)
    _mirror_human_chat_log(
        row_id=row_id,
        ts=ts,
        sender=sender,
        recipient=recipient,
        kind=kind,
        correlation=correlation,
        content=content,
    )
    return row_id


def _chat_log_path_for_ts(ts: float) -> Path:
    day = datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%Y-%m-%d")
    return CHAT_LOG_DIR / f"{day}.md"


def _markdown_escape_line(text: str) -> str:
    # Keep the file readable markdown while preserving exact user/agent text.
    return (text or "").replace("\r\n", "\n").replace("\r", "\n")


def _human_log_content(kind: str, content: str) -> str | None:
    if kind.startswith("a2a_"):
        return None
    if kind == "system_event":
        try:
            payload = json.loads(content)
        except Exception:
            return content
        if isinstance(payload, dict):
            event = payload.get("event")
            if event:
                details = []
                for key in ("job_id", "error", "status", "endpoint_host"):
                    if payload.get(key):
                        details.append(f"{key}={payload[key]}")
                suffix = f" ({', '.join(details)})" if details else ""
                return f"system_event: {event}{suffix}"
        return "system_event"
    return content


def _mirror_human_chat_log(
    *,
    row_id: int,
    ts: float,
    sender: str,
    recipient: Optional[str],
    kind: str,
    correlation: Optional[str],
    content: str,
) -> None:
    """Append a human-readable daily markdown mirror for PWA review.

    chat.db remains the source of truth. This best-effort mirror intentionally
    skips structured A2A JSON rows so John gets a durable readable transcript
    rather than protocol envelopes.
    """
    if not CHAT_LOG_ENABLED:
        return
    human_content = _human_log_content(kind, content)
    if human_content is None:
        return
    try:
        path = _chat_log_path_for_ts(ts)
        path.parent.mkdir(parents=True, exist_ok=True)
        dt = datetime.fromtimestamp(ts, tz=timezone.utc)
        if not path.exists():
            path.write_text(
                f"# CTO PWA chat log — {dt.strftime('%Y-%m-%d')}\n\n"
                "Timezone: UTC. This is a human-readable mirror of chat.db; "
                "structured A2A JSON rows are omitted by default.\n\n",
                encoding="utf-8",
            )
        route = f" → {recipient}" if recipient else ""
        corr = f" [{correlation}]" if correlation else ""
        body = _markdown_escape_line(human_content)
        with path.open("a", encoding="utf-8") as fh:
            fh.write(f"## {dt.strftime('%H:%M:%S')}Z — {sender}{route} — {kind} — #{row_id}{corr}\n\n")
            fh.write(body.rstrip() + "\n\n")
    except Exception:
        # Logging must never break chat delivery.
        return

def tail(since_id: int = 0, limit: int = 200, path: str = CHAT_DB_PATH) -> list[dict]:
    """Return messages with id > since_id, oldest first. Caller polls or uses WS."""
    with connection(path) as conn:
        rows = conn.execute(
            "SELECT id, ts, sender, recipient, kind, correlation, content "
            "FROM messages WHERE id > ? ORDER BY id ASC LIMIT ?",
            (since_id, limit),
        ).fetchall()
    return [
        {"id": r[0], "ts": r[1], "sender": r[2], "recipient": r[3],
         "kind": r[4], "correlation": r[5], "content": r[6]}
        for r in rows
    ]

def log_a2a_request(*, task_id: str, sender: str, recipient: str, payload: dict, path: str = CHAT_DB_PATH) -> int:
    return append(sender=sender, recipient=recipient, kind="a2a_request",
                  correlation=task_id, content=json.dumps(payload), path=path)

def log_a2a_response(*, task_id: str, sender: str, recipient: str, payload: dict, path: str = CHAT_DB_PATH) -> int:
    return append(sender=sender, recipient=recipient, kind="a2a_response",
                  correlation=task_id, content=json.dumps(payload), path=path)

if __name__ == "__main__":
    # smoke test
    with connection() as c:
        c.executescript(SCHEMA)
    print(f"chat DB ready at {CHAT_DB_PATH}")
