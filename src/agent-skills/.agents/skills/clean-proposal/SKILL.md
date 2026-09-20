---
name: clean-proposal
description: Short in-chat fix proposal plus a straight-to-point detail file under tmp. Use when user writes /clean-proposal <issue>.
---

# clean-proposal

Short fix in chat. Details in a file. Both straight to the point.

Load `/tmp-agent-skill` for the scratch root (`$AGENT_TMP`).

## Trigger

`/clean-proposal <issue>`

## Procedure

1. Chat: 3-5 lines — cause, fix, files touched. Code only if it fits in 5 lines.
2. File `$AGENT_TMP/proposal-<slug>.md`: cause, change list with short snippets, how to verify. No filler, no background essay.
3. Stop. Apply nothing until user says so.
