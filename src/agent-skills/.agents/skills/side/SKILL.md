---
name: side
description: Run a side-task in a sub-agent while you keep focus on the current task. Use when user writes /side <what to do>.
---

# side

Side-note in a sub-agent. You stay on the current task — no deviation.

## Trigger

`/side <what to do>` (combines: `/side /add_ai_permissions ...`)

## Procedure

1. Spawn one background sub-agent with the side-task (goal + where to write result under `$AGENT_TMP`, see `/tmp-agent-skill`).
2. Immediately continue your current task. Do not wait, do not poll.
3. Pick up the side result when notified; merge it in one line.

## Rules

- Side-task must not touch your working files. Read-only, or its own workspace.
- Main task always wins on conflict.
