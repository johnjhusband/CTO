import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "security" / "clone-candidate-watchdog.py"
spec = importlib.util.spec_from_file_location("clone_candidate_watchdog", MODULE_PATH)
watchdog = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = watchdog
spec.loader.exec_module(watchdog)


def test_only_exact_clone_candidate_labels_are_safe():
    assert watchdog.is_safe_clone_candidate(
        {"labels": {"purpose": "cto", "role": "clone-candidate", "test_mode": "true", "version": "v2"}}
    )
    assert not watchdog.is_safe_clone_candidate({"labels": {"purpose": "cto", "version": "v1"}})
    assert not watchdog.is_safe_clone_candidate(
        {"labels": {"purpose": "cto", "role": "clone-candidate", "test_mode": "false"}}
    )


def test_failed_parity_summary_is_destroy_plan_when_server_labels_match():
    summary = watchdog.CandidateSummary(
        path="logs/clone/candidates/cto-v2-132825157-summary.json",
        server_id=132825157,
        name="cto-candidate-202605250519",
        status="failed_destroying",
        failure_phase="parity_clone_repeatability",
        reason="failed parity",
    )
    server = {
        "id": 132825157,
        "name": "cto-v2",
        "status": "running",
        "labels": {"purpose": "cto", "role": "clone-candidate", "test_mode": "true"},
    }
    assert watchdog.build_plan([server], [summary]) == [
        {
            "server_id": 132825157,
            "name": "cto-v2",
            "action": "destroy",
            "reason": "failed clone/parity summary status=failed_destroying phase=parity_clone_repeatability",
            "summary": "logs/clone/candidates/cto-v2-132825157-summary.json",
        }
    ]


def test_production_label_mismatch_blocks_destroy_even_with_failed_summary():
    summary = watchdog.CandidateSummary(
        path="logs/clone/candidates/bad.json",
        server_id=130627001,
        name="cto-v1",
        status="failed",
        failure_phase="parity_clone_repeatability",
        reason="bad data",
    )
    production = {
        "id": 130627001,
        "name": "cto-v1",
        "status": "running",
        "labels": {"purpose": "cto", "version": "v1"},
    }
    plan = watchdog.build_plan([production], [summary])
    assert plan[0]["action"] == "blocked_label_mismatch"


def test_absent_failed_candidate_is_reported_not_destroyed():
    summary = watchdog.CandidateSummary(
        path="logs/clone/candidates/old.json",
        server_id=1,
        name="old-candidate",
        status="failed_destroying",
        failure_phase="parity_clone_repeatability",
        reason="already requested deletion",
    )
    assert watchdog.build_plan([], [summary])[0]["action"] == "already_absent"
