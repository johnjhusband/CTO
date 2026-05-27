#!/usr/bin/env python3
"""Governed OpenClaw self-repair session helper.

This is the replacement path for the temporary direct-edit exception in AGENTS.md.
It does not edit files by itself; it creates auditable repair sessions, enforces
allowed/denied paths for snapshots, preserves rollback copies, and records the
verification command/result used before a repair is considered complete.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

DEFAULT_ALLOWED_ROOTS = [
    Path("/opt/cto"),
    Path("/usr/lib/node_modules/openclaw"),
    Path.home() / ".openclaw",
]
DENY_PARTS = {
    ".env",
    ".env.local",
    ".env.production",
    ".vapid",
    ".engram",
    ".cache",
    "auth-profiles",
    "chat.db",
    "private.pem",
    "id_rsa",
    "id_ed25519",
}
SESSION_ROOT = Path("/opt/cto/logs/openclaw-governed-repairs")


def utc_now() -> str:
    return dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def slug(value: str) -> str:
    clean = "".join(ch.lower() if ch.isalnum() else "-" for ch in value).strip("-")
    while "--" in clean:
        clean = clean.replace("--", "-")
    return clean[:64] or "repair"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def allowed_roots() -> list[Path]:
    raw = os.environ.get("OPENCLAW_GOVERNED_REPAIR_ALLOWED_ROOTS")
    if raw:
        return [Path(p).expanduser().resolve() for p in raw.split(os.pathsep) if p]
    return [p.expanduser().resolve() for p in DEFAULT_ALLOWED_ROOTS]


def ensure_allowed(path: Path) -> Path:
    resolved = path.expanduser().resolve()
    parts = set(resolved.parts)
    denied = sorted(DENY_PARTS & parts)
    if denied:
        raise SystemExit(f"Refusing sensitive path {resolved}: contains denied component(s) {', '.join(denied)}")
    for root in allowed_roots():
        if resolved == root or root in resolved.parents:
            return resolved
    raise SystemExit(f"Refusing path outside governed repair roots: {resolved}")


def load_manifest(session: Path) -> dict[str, Any]:
    manifest = session / "manifest.json"
    if not manifest.exists():
        raise SystemExit(f"Session manifest not found: {manifest}")
    return json.loads(manifest.read_text())


def save_manifest(session: Path, data: dict[str, Any]) -> None:
    (session / "manifest.json").write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def begin(args: argparse.Namespace) -> int:
    SESSION_ROOT.mkdir(parents=True, exist_ok=True)
    stamp = dt.datetime.now(dt.UTC).strftime("%Y%m%dT%H%M%SZ")
    session = SESSION_ROOT / f"{stamp}-{slug(args.ticket)}-{slug(args.reason)}"
    session.mkdir()
    (session / "backups").mkdir()
    manifest = {
        "id": session.name,
        "started_at": utc_now(),
        "ticket": args.ticket,
        "reason": args.reason,
        "scope": args.scope,
        "allowed_roots": [str(p) for p in allowed_roots()],
        "guardrails": [
            "smallest plausible patch",
            "no weakening safety/auth/secret handling",
            "snapshot before editing",
            "diff and verification before finalization",
        ],
        "snapshots": [],
        "finalized_at": None,
        "verification": None,
    }
    save_manifest(session, manifest)
    print(session)
    return 0


def snapshot(args: argparse.Namespace) -> int:
    session = Path(args.session).expanduser().resolve()
    manifest = load_manifest(session)
    target = ensure_allowed(Path(args.path))
    if not target.exists() or not target.is_file():
        raise SystemExit(f"Can only snapshot existing regular files: {target}")
    root = next(root for root in allowed_roots() if target == root or root in target.parents)
    rel = target.relative_to(root)
    backup = session / "backups" / slug(str(root)) / rel
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(target, backup)
    entry = {
        "path": str(target),
        "allowed_root": str(root),
        "backup": str(backup),
        "sha256_before": sha256(target),
        "size_before": target.stat().st_size,
        "snapshotted_at": utc_now(),
    }
    manifest["snapshots"].append(entry)
    save_manifest(session, manifest)
    print(json.dumps(entry, indent=2, sort_keys=True))
    return 0


def run_verify(command: str, cwd: Path) -> dict[str, Any]:
    completed = subprocess.run(
        command,
        shell=True,
        cwd=str(cwd),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=900,
    )
    output = completed.stdout[-12000:]
    return {
        "command": command,
        "cwd": str(cwd),
        "returncode": completed.returncode,
        "output_tail": output,
        "passed": completed.returncode == 0,
        "ran_at": utc_now(),
    }


def finalize(args: argparse.Namespace) -> int:
    session = Path(args.session).expanduser().resolve()
    manifest = load_manifest(session)
    if not manifest.get("snapshots"):
        raise SystemExit("Refusing to finalize without at least one pre-edit snapshot")
    verify = None
    if args.verify:
        verify = run_verify(args.verify, Path(args.cwd).expanduser().resolve())
        if not verify["passed"]:
            (session / "verification-failed.log").write_text(verify["output_tail"])
            save_manifest(session, {**manifest, "verification": verify})
            raise SystemExit(f"Verification failed with exit {verify['returncode']}; see {session / 'verification-failed.log'}")
    elif not args.no_verify:
        raise SystemExit("Provide --verify '<command>' or explicit --no-verify")

    diffs: list[dict[str, str]] = []
    for snap in manifest["snapshots"]:
        current = Path(snap["path"])
        backup = Path(snap["backup"])
        if current.exists():
            after = sha256(current)
            if after != snap["sha256_before"]:
                diff_path = session / ("diff-" + slug(snap["path"]) + ".diff")
                diff = subprocess.run(
                    ["diff", "-u", str(backup), str(current)],
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    check=False,
                ).stdout
                diff_path.write_text(diff)
                diffs.append({"path": snap["path"], "diff": str(diff_path), "sha256_after": after})
    manifest["diffs"] = diffs
    manifest["verification"] = verify or {"passed": True, "command": None, "note": "explicit --no-verify"}
    manifest["finalized_at"] = utc_now()
    save_manifest(session, manifest)
    print(json.dumps({"session": str(session), "diff_count": len(diffs), "verification_passed": manifest["verification"]["passed"]}, indent=2))
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("begin", help="start an auditable repair session")
    p.add_argument("--ticket", required=True, help="backlog/decision identifier, e.g. BACKLOG-002")
    p.add_argument("--reason", required=True, help="short human-readable reason")
    p.add_argument("--scope", required=True, choices=["cto-workspace", "openclaw-install", "openclaw-state"])
    p.set_defaults(func=begin)

    p = sub.add_parser("snapshot", help="backup a file before editing")
    p.add_argument("--session", required=True)
    p.add_argument("--path", required=True)
    p.set_defaults(func=snapshot)

    p = sub.add_parser("finalize", help="record diffs and verification result")
    p.add_argument("--session", required=True)
    p.add_argument("--verify", help="verification command to run")
    p.add_argument("--cwd", default="/opt/cto")
    p.add_argument("--no-verify", action="store_true", help="explicitly finalize without running verification")
    p.set_defaults(func=finalize)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
