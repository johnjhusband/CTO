#!/usr/bin/env python3
"""
Anomaly watcher (Approach A from 3h-B decision — INFORMATIONAL ONLY).

Runs every minute via systemd timer. Collects CPU/RAM/disk/network samples,
maintains a rolling 7-day baseline, computes z-scores, writes anomalies to
/opt/cto/logs/anomaly.log.

This file NEVER triggers action. Per 3h-B, only the health watcher (outcome-
driven, Approach C) triggers repairs. Anomaly data is context that an
investigation consults — "while OpenClaw was hanging, was CPU also red-lined?"

Implementation: stdlib only. Baseline persisted as JSON. Z-score threshold
configurable; default 3.0 (one anomaly in ~370 minutes of normal operation).
"""
from __future__ import annotations
import json
import math
import os
import statistics
import sys
import time
from pathlib import Path

BASELINE_FILE = Path(os.environ.get("ANOMALY_BASELINE", "/opt/cto/.cache/anomaly-baseline.json"))
ANOMALY_LOG = Path(os.environ.get("ANOMALY_LOG", "/opt/cto/logs/anomaly.log"))
WINDOW_DAYS = int(os.environ.get("ANOMALY_WINDOW_DAYS", "7"))
Z_THRESHOLD = float(os.environ.get("ANOMALY_Z_THRESHOLD", "3.0"))


def _read_loadavg() -> float:
    try:
        with open("/proc/loadavg") as f:
            return float(f.read().split()[0])
    except Exception:
        return 0.0


def _read_meminfo_used_pct() -> float:
    try:
        info = {}
        with open("/proc/meminfo") as f:
            for line in f:
                k, _, v = line.partition(":")
                info[k.strip()] = int(v.strip().split()[0])
        total = info.get("MemTotal", 1)
        avail = info.get("MemAvailable", info.get("MemFree", 0))
        return ((total - avail) / total) * 100
    except Exception:
        return 0.0


def _read_disk_used_pct(path: str = "/opt") -> float:
    try:
        s = os.statvfs(path)
        used = (s.f_blocks - s.f_bavail) * s.f_frsize
        total = s.f_blocks * s.f_frsize
        return (used / total) * 100 if total else 0.0
    except Exception:
        return 0.0


def _read_netbytes() -> int:
    """Sum rx+tx across non-loopback interfaces."""
    total = 0
    try:
        with open("/proc/net/dev") as f:
            lines = f.read().splitlines()[2:]
        for line in lines:
            iface, _, rest = line.partition(":")
            iface = iface.strip()
            if iface == "lo":
                continue
            fields = rest.split()
            if len(fields) >= 9:
                total += int(fields[0]) + int(fields[8])  # rx_bytes + tx_bytes
    except Exception:
        pass
    return total


def _load_baseline() -> dict:
    BASELINE_FILE.parent.mkdir(parents=True, exist_ok=True)
    if BASELINE_FILE.exists():
        try:
            return json.loads(BASELINE_FILE.read_text())
        except Exception:
            return {"samples": {}}
    return {"samples": {}}


def _save_baseline(state: dict) -> None:
    BASELINE_FILE.write_text(json.dumps(state))


def _append_anomaly_log(entry: dict) -> None:
    ANOMALY_LOG.parent.mkdir(parents=True, exist_ok=True)
    with open(ANOMALY_LOG, "a") as f:
        f.write(json.dumps(entry) + "\n")


def _z(value: float, samples: list[float]) -> float:
    if len(samples) < 30:  # need ~30 samples for stable stats
        return 0.0
    mu = statistics.mean(samples)
    try:
        sigma = statistics.stdev(samples)
    except statistics.StatisticsError:
        return 0.0
    if sigma < 1e-6:
        return 0.0
    return (value - mu) / sigma


def main() -> None:
    metrics = {
        "loadavg_1min": _read_loadavg(),
        "mem_used_pct": _read_meminfo_used_pct(),
        "disk_used_pct": _read_disk_used_pct(),
        "net_bytes_total": _read_netbytes(),
    }
    state = _load_baseline()
    samples = state.setdefault("samples", {})
    cutoff = time.time() - (WINDOW_DAYS * 86400)
    now = time.time()
    anomalies = []
    for k, v in metrics.items():
        bucket = samples.setdefault(k, [])
        # Prune old samples — list of [ts, value] pairs
        bucket[:] = [(ts, val) for (ts, val) in bucket if ts > cutoff]
        z = _z(v, [val for (_ts, val) in bucket])
        bucket.append((now, v))
        if abs(z) > Z_THRESHOLD:
            anomalies.append({"metric": k, "value": v, "z_score": round(z, 2),
                              "baseline_mean": round(statistics.mean([val for (_ts, val) in bucket]), 2),
                              "baseline_n": len(bucket)})
    _save_baseline(state)
    if anomalies:
        _append_anomaly_log({"ts": now, "anomalies": anomalies, "metrics": metrics})


if __name__ == "__main__":
    main()
