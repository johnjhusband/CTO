from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INSTALL = ROOT / "scripts" / "install.sh"


def test_install_wrapper_preserves_summary_and_deletes_failed_candidate():
    text = INSTALL.read_text()
    assert "retire_failed_candidate()" in text
    assert "logs/clone/candidates/${VPS_NAME}-${VPS_ID}-summary.json" in text
    assert '"status": os.environ["SUMMARY_STATUS"]' in text
    assert 'SUMMARY_STATUS="failed_destroying"' in text
    assert 'hcloud_api DELETE "/servers/${VPS_ID}"' in text
    assert 'trap on_error ERR' in text


def test_install_wrapper_only_arms_retirement_after_provision_and_disarms_on_success():
    text = INSTALL.read_text()
    provision_idx = text.index('VPS_ID=$(echo "${RESP}"')
    armed_idx = text.index('CANDIDATE_PROVISIONED=1')
    complete_idx = text.index('section "Install complete"')
    disarm_idx = text.index('CANDIDATE_PROVISIONED=0', complete_idx)
    assert provision_idx < armed_idx < complete_idx < disarm_idx
