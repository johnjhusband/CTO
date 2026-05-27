#!/usr/bin/env python3
"""Retire failed Hetzner clone candidates without touching production.

Default mode is dry-run. Destructive deletion requires --destroy and only applies to
servers labelled purpose=cto, role=clone-candidate, test_mode=true.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any

HCLOUD_BASE = "https://api.hetzner.cloud/v1"
SAFE_CANDIDATE_LABELS = {
    "purpose": "cto",
    "role": "clone-candidate",
    "test_mode": "true",
}
FAILED_SUMMARY_STATUSES = {"failed", "failed_destroying", "destroy_requested"}
FAILED_SERVER_STATUSES = {"off", "unknown"}


@dataclass(frozen=True)
class CandidateSummary:
    path: str
    server_id: int
    name: str
    status: str
    failure_phase: str
    reason: str


def is_safe_clone_candidate(server: dict[str, Any]) -> bool:
    labels = server.get("labels") or {}
    return all(labels.get(key) == value for key, value in SAFE_CANDIDATE_LABELS.items())


def summary_indicates_failed_parity(summary: dict[str, Any]) -> bool:
    status = str(summary.get("status", "")).strip().lower()
    phase = str(summary.get("failure_phase", "")).strip().lower()
    return status in FAILED_SUMMARY_STATUSES or bool(phase and "parity" in phase)


def load_failed_summaries(root: Path) -> list[CandidateSummary]:
    candidates_dir = root / "logs" / "clone" / "candidates"
    summaries: list[CandidateSummary] = []
    if not candidates_dir.is_dir():
        return summaries
    for path in sorted(candidates_dir.glob("*.json")):
        try:
            data = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError):
            continue
        if not summary_indicates_failed_parity(data):
            continue
        server_id = data.get("id")
        if not isinstance(server_id, int):
            continue
        summaries.append(
            CandidateSummary(
                path=str(path.relative_to(root)),
                server_id=server_id,
                name=str(data.get("name", "")),
                status=str(data.get("status", "")),
                failure_phase=str(data.get("failure_phase", "")),
                reason=str(data.get("reason", "")),
            )
        )
    return summaries


def hcloud_request(method: str, path: str, token: str) -> dict[str, Any] | None:
    request = urllib.request.Request(
        HCLOUD_BASE + path,
        headers={"Authorization": f"Bearer {token}"},
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            return None
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Hetzner API {method} {path} failed: HTTP {exc.code}: {body}") from exc
    return json.loads(payload) if payload else {}


def build_plan(servers: list[dict[str, Any]], summaries: list[CandidateSummary]) -> list[dict[str, Any]]:
    by_id = {int(server["id"]): server for server in servers if "id" in server}
    summary_ids = {summary.server_id for summary in summaries}
    actions: list[dict[str, Any]] = []

    for summary in summaries:
        server = by_id.get(summary.server_id)
        if server is None:
            actions.append(
                {
                    "server_id": summary.server_id,
                    "name": summary.name,
                    "action": "already_absent",
                    "reason": "failed parity summary exists but server is not present in Hetzner inventory",
                    "summary": summary.path,
                }
            )
            continue
        if not is_safe_clone_candidate(server):
            actions.append(
                {
                    "server_id": summary.server_id,
                    "name": server.get("name", summary.name),
                    "action": "blocked_label_mismatch",
                    "reason": "server does not have the exact safe clone-candidate labels",
                    "summary": summary.path,
                }
            )
            continue
        actions.append(
            {
                "server_id": summary.server_id,
                "name": server.get("name", summary.name),
                "action": "destroy",
                "reason": f"failed clone/parity summary status={summary.status} phase={summary.failure_phase}",
                "summary": summary.path,
            }
        )

    for server in servers:
        server_id = int(server.get("id", 0))
        if server_id in summary_ids or not is_safe_clone_candidate(server):
            continue
        status = str(server.get("status", "")).lower()
        if status in FAILED_SERVER_STATUSES:
            actions.append(
                {
                    "server_id": server_id,
                    "name": server.get("name", ""),
                    "action": "destroy",
                    "reason": f"safe clone-candidate label set with unhealthy server status={status}",
                    "summary": None,
                }
            )
    return actions


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default="/opt/cto", help="CTO checkout root")
    parser.add_argument("--destroy", action="store_true", help="delete eligible failed clone candidates")
    parser.add_argument("--json", action="store_true", help="emit JSON only")
    args = parser.parse_args()

    root = Path(args.root)
    token = os.environ.get("HETZNER_API_TOKEN") or os.environ.get("HCLOUD_TOKEN")
    if not token:
        print("FAIL: HETZNER_API_TOKEN/HCLOUD_TOKEN is required", file=sys.stderr)
        return 2

    server_payload = hcloud_request("GET", "/servers?per_page=50", token) or {"servers": []}
    servers = server_payload.get("servers", [])
    summaries = load_failed_summaries(root)
    plan = build_plan(servers, summaries)

    destroyed: list[int] = []
    if args.destroy:
        for item in plan:
            if item["action"] != "destroy":
                continue
            hcloud_request("DELETE", f"/servers/{item['server_id']}", token)
            destroyed.append(int(item["server_id"]))

    result = {
        "mode": "destroy" if args.destroy else "dry_run",
        "safe_label_selector": SAFE_CANDIDATE_LABELS,
        "actions": plan,
        "destroyed_server_ids": destroyed,
    }
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"mode={result['mode']}")
        if not plan:
            print("No failed clone candidates found.")
        for item in plan:
            print(f"{item['action']}: {item['server_id']} {item['name']} — {item['reason']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
