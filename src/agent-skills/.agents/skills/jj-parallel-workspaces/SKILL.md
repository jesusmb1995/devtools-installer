---
name: jj-parallel-workspaces
description: Run several agents in parallel, each in its own jj workspace. Create per-agent workspaces, merge back when done, clean up.
---

# jj-parallel-workspaces

When parallel agents (see `/team-basic`) edit code in the same jj repo, give each agent its own `jj workspace` so they never step on each other's working copy.

## Trigger

User writes `/jj-parallel-workspaces`, or a team task needs parallel editing in one jj repo.

## Procedure

1. From the repo root, create one workspace per agent (name contains `-agent` so `/jj-workspace-cleanup` can find it later):
   `jj workspace add --name <task>-agent<N> ../<repo>-<task>-agent<N>`
2. Point each subagent at its workspace path. Agents work, commit (`jj describe`), and write their summary as usual.
3. When a piece is done, move its changes back (e.g. `jj squash --from <agent-change> --into <target>` or push its bookmark), like `/per_patch`.
4. When no longer needed, remove the workspace: `jj workspace forget <task>-agent<N>` + `rm -rf ../<repo>-<task>-agent<N>` (see `/jj-workspace-cleanup`). Never forget a workspace with uncommitted changes unless the user explicitly says so.
