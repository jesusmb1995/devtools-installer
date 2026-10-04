---
name: search-convos
description: Search previous conversations for what the user asks and show the command to resume the relevant one. Use when the user writes /search-convos.
---

# Search Convos

Find the earlier conversation about X and tell the user how to get back into it.

## Trigger

User writes `/search-convos <what to find>`.

## Procedure

1. Search persisted conversation snapshots: `/tmp/fork-*.md`, `$AGENT_TMP/fork-*.md`, and compaction files (`/comp-now`, `/comp-use` targets). Grep for the user's keywords.
2. For each hit, show: one-line topic match + the exact resume command (`/fork-md-use <name>` or `/comp-use`).
3. Best match first. No match? Say so in one line — do not invent a convo.

## Rules

- Only persisted snapshots are searchable. Anything never dumped with `/fork-md` or `/comp-now` cannot be found — say that plainly.
- Resume commands, not summaries. The user wants back in, not a retelling.
