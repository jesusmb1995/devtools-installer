---
name: jjws
description: Do the current task in another jj workspace instead of the main one. Switch or create it first, work there, leave main untouched.
---

# jjws

Even when sitting in the main workspace, complete the task in a different workspace so the main working copy stays clean.

## Trigger

User writes `/jjws [<workspace-name or path>]`.

## Procedure

1. If a name/path was given and `jj workspace list` shows it, go there (`cd <path>`) and work.
2. If it does not exist, create it first: `jj workspace add --name <name> <path>`, then go there.
3. If nothing was given, ask which workspace (or create `<repo>-task` via `jj workspace add`).
4. Complete the task in that workspace only. Never touch the main working copy.
5. Report the workspace path and what changed there when done.
