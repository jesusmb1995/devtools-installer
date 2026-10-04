---
name: cleanup-old-workspaces
description: Dry-run-first cleanup of old workspaces — flag ones unused for days and already merged/pushed in sync, prove no data loss, delete only after user confirms. Use when the user writes /cleanup-old-workspaces.
---

# Cleanup Old Workspaces

Delete stale workspaces safely: dry-run analysis first, removal only after the user says go.

## Trigger

User writes `/cleanup-old-workspaces [--dry-run]` (default IS a dry run until the user confirms).

## Procedure

1. List workspaces: `jj workspace list` (name, path, change, description).
2. For each candidate, check all three:
   - Unused for several days (working-copy commit timestamp / last activity).
   - Already merged or pushed: its change/bookmark exists in the main workspace (`jj log -r 'bookmarks()'`) or its remote is in sync.
   - No data loss possible: `jj st` inside its path is clean — no uncommitted changes, no shelved work.
3. Report a table: workspace | last used | merged/pushed proof | safe to delete yes/no + why. Same safety bar as `/jj-workspace-cleanup`: never touch `default`, non-`-agent` names, or unclear states without asking.
4. Propose the exact removal commands (`jj workspace forget <name>` + `rm -rf <path>`). Run them ONLY after the user confirms.

## Rules

- Dry-run output first, always. `--dry-run` just prints the table and stops.
- One unsafe candidate never blocks the safe ones — delete what is proven safe, keep the rest with reasons.
