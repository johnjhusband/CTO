# Governed OpenClaw Self-Repair

OpenClaw may only directly edit its own install/state under the temporary repair exception when the edit is wrapped by a governed self-repair record.

## Required flow

1. Write a manifest JSON with: `title`, `reason`, `paths`, `verification`, `rollback_plan`, and `owner`.
2. Open a record before editing:

   ```bash
   scripts/repair/governed-self-repair.py begin --manifest /path/to/manifest.json
   ```

3. Make the smallest scoped edit.
4. Run the manifest verification commands.
5. Close the record with verification evidence:

   ```bash
   scripts/repair/governed-self-repair.py close \
     --record logs/repairs/self-repair/<record>.json \
     --verification "<command> -> passed"
   ```

## Scope

Default allowed prefixes are:

- `/usr/lib/node_modules/openclaw`
- `/home/cto/.openclaw`
- `/opt/cto`

The wrapper does not grant new write power. It creates backups for existing files, records git status before/after, rejects secret-shaped manifest/verification text, and preserves rollback evidence under `logs/repairs/self-repair/`.

## When not to use it

- Do not use it for spending money, destructive infrastructure changes, or secret rotation.
- Do not use it to weaken safety policy, gateway auth, credential handling, or secret storage.
- Do not use it to bypass clone-test-replace for material upgrades.

## Compatibility helper

`scripts/openclaw-governed-repair.py` is a lower-level session helper with `begin`, `snapshot`, and `finalize` subcommands. Use it when a repair needs per-file pre-edit snapshots and diff artifacts instead of a single manifest closeout record.
