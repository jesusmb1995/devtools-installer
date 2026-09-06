---
name: jj-workspace-cleanup
description: Review open jj workspaces; remove stale -agent ones that are no longer needed.
---

# jj-workspace-cleanup

Review existing open workspaces and clean up the ones agents left behind.

## Trigger

User writes `/jj-workspace-cleanup`, or after a `/jj-parallel-workspaces` team task finishes.

## Procedure

1. List open workspaces: `jj workspace list` (shows `<name>: <path> <change> <desc>`).
2. For each workspace with `-agent` in its name, check whether it is still needed:
   - `jj st` inside its path — working-copy changes mean work may be unmerged.
   - Does its change/bookmark already exist in the main workspace (`jj log -r 'bookmarks()'`)?
3. If clean AND merged (or the user confirms), remove it:
   `jj workspace forget <name>` + `rm -rf <path>`.
4. Never remove a workspace with uncommitted changes, a non-`-agent` name (e.g. `default`), or an unclear state without asking first. Report what was kept and why.
