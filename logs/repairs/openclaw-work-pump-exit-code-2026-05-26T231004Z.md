# OpenClaw work-pump false-failure repair — 2026-05-26T23:10:04Z

Selected item: hemisphere health / continuous work-pump reliability.

Evidence:
- `cto-openclaw-work-pump.service` was failed with process status 127 after the OpenClaw CLI had already emitted a complete JSON response containing final assistant text and stop reason `stop`.
- The journal showed OpenClaw completed a backlog-closure work item, but systemd still marked the unit failed, causing the timer health surface to report a broken left-hemisphere work pump.

Repair:
- Updated `/opt/cto/scripts/openclaw-work-pump.sh` to capture OpenClaw JSON output through `tee`.
- If OpenClaw exits zero, behavior is unchanged.
- If OpenClaw exits non-zero but the captured JSON contains a final assistant response and stop reason `stop`, the wrapper logs the CLI status and exits zero so completed work is not treated as a failed service tick.
- Malformed output or non-stop responses still return the original non-zero status.

Verification:
- Bash syntax check: passed (`bash -n scripts/openclaw-work-pump.sh`).
- JSON classifier smoke tests: passed for complete stop response, nested stop response, timeout response, and missing-visible-text response.
- Systemd health check: `cto-openclaw-work-pump.timer` is active and the current pump tick is running through the repaired wrapper, with OpenClaw MCP servers launched using the repaired commands.
- A2A full-path smoke test: passed through `a2a-delegate__a2a_delegate`, returning `status: ok` with compact task-scoped session id `a2a-f77b47def4c54cd2989df23570b5a2a9`.
- Repository hygiene: `git diff --check` passed.

Secrets: none recorded.
