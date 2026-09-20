---
name: sub
description: Run the given task in a sub-agent and use its result. Use when user writes /sub <what to do>.
---

# sub

Delegate to a sub-agent. Wait for it. Use the result.

## Trigger

`/sub <what to do>`

## Procedure

1. Spawn one sub-agent with the task (single clear goal + what to return).
2. Wait — no polling, system notifies.
3. Verify the result against real code; drop hallucinations. Continue from there.

## Rules

- One task = one agent. Parallel pieces → `/team-basic`.
- Sub-agent writes scratch only under `$AGENT_TMP` (see `/tmp-agent-skill`).
