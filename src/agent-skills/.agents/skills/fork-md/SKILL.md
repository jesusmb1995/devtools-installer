---
name: fork-md
description: Dump the current conversation to a temp .md under a key name. Uncompressed — keep relevant, drop noise. /fork-md [name]
---

# fork-md

Save the convo to `/tmp/fork-<name>.md`. Like `/comp-now` but uncompressed.

## Trigger

`/fork-md [name]`

## Procedure

1. Walk the convo. Drop: tool-call narration, dead-end exploration, "let me look at X" that returned nothing.
2. Keep: goal, decisions + reasons, files touched, commands that matter, errors + fixes, open questions, state to continue.
3. Write `/tmp/fork-<name>.md`. Dense bullets. No filler.
4. Print path + preview.

## Name

- User gave one → slugify (lowercase, spaces→`-`, strip non-alnum).
- None → `fork-YYYYMMDD-HHMM.md`. Tell the user what it is.

## Rules

- Single file. Overwrite same name.
- Verbose is fine. Irrelevant is not.
- Fall back to `$AGENT_TMP/fork-<name>.md` if `/tmp` unwritable — say so.