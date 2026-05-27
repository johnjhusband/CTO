#!/usr/bin/env python3
"""List binary or large blobs reachable from git history without printing contents.

Metadata-only helper for public-repo audits. It prints object id prefixes, byte
sizes, and paths only; it never emits blob contents.
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class Blob:
    oid: str
    path: str
    size: int
    binary: bool


def git_bytes(*args: str, input_data: bytes | None = None) -> bytes:
    return subprocess.check_output(["git", *args], cwd=ROOT, input=input_data)


def iter_objects() -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for raw in git_bytes("rev-list", "--objects", "--all").decode("utf-8", "replace").splitlines():
        if not raw.strip():
            continue
        oid, _, path = raw.partition(" ")
        rows.append((oid, path or "<no-path>"))
    return rows


def object_types_and_sizes(oids: list[str]) -> dict[str, tuple[str, int]]:
    if not oids:
        return {}
    query = "".join(f"{oid}\n" for oid in oids).encode()
    out = git_bytes("cat-file", "--batch-check=%(objectname) %(objecttype) %(objectsize)", input_data=query)
    result: dict[str, tuple[str, int]] = {}
    for line in out.decode().splitlines():
        oid, typ, size = line.split(" ", 2)
        result[oid] = (typ, int(size))
    return result


def is_binary_blob(oid: str, sample_limit: int = 8192) -> bool:
    # Metadata-only: inspect bytes in memory, never print them.
    data = subprocess.check_output(["git", "cat-file", "blob", oid], cwd=ROOT)[:sample_limit]
    if b"\0" in data:
        return True
    try:
        data.decode("utf-8")
        return False
    except UnicodeDecodeError:
        return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--min-size", type=int, default=256 * 1024, help="Also report blobs at least this many bytes")
    parser.add_argument("--limit", type=int, default=200, help="Maximum rows to print after the summary")
    args = parser.parse_args()

    objects = iter_objects()
    meta = object_types_and_sizes([oid for oid, _ in objects])
    rows: list[Blob] = []
    total_blobs = 0
    for oid, path in objects:
        typ_size = meta.get(oid)
        if not typ_size or typ_size[0] != "blob":
            continue
        total_blobs += 1
        size = typ_size[1]
        binary = is_binary_blob(oid)
        if binary or size >= args.min_size:
            rows.append(Blob(oid=oid, path=path, size=size, binary=binary))

    rows.sort(key=lambda r: (not r.binary, -r.size, r.path))
    binary_count = sum(1 for r in rows if r.binary)
    large_text_count = sum(1 for r in rows if not r.binary)
    print(
        "history_blob_inventory "
        f"total_blobs={total_blobs} flagged={len(rows)} binary={binary_count} "
        f"large_text={large_text_count} min_size={args.min_size}"
    )
    for row in rows[: args.limit]:
        kind = "binary" if row.binary else "large_text"
        print(f"{kind} oid={row.oid[:12]} size={row.size} path={row.path}")
    if len(rows) > args.limit:
        print(f"truncated remaining={len(rows) - args.limit}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
