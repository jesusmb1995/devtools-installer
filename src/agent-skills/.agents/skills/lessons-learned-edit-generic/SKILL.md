---
name: lessons-learned-edit-generic
description: Capture a learning from review comments or user-provided text into a skill file — draft the entry, filter noise, write only after user confirms. Generic version, works with any skill. Use when the user writes /lessons-learned-edit-generic.
---

# Lessons Learned Edit (Generic)

Document a learning in a skill file, but only what is worth keeping, and only after the user says yes.

## Trigger

User writes `/lessons-learned-edit-generic <review comments or lesson text> [+ target skill]`.

## Procedure

1. Read the input (review comments, pasted lesson, or described mistake).
2. Filter it yourself first:
   - Keep: actionable, generalizable rules that prevent a repeat.
   - Drop: one-off noise, style nits already covered elsewhere, anything contradicting existing skill content.
3. Draft the summary: 1-3 sentence lesson + the exact lines to add, and to which skill file (user-named, or propose the best-fit existing skill, or a new skill when none fits).
4. Show the draft and the diff-to-be. Write NOTHING until the user confirms with yes.
5. On yes, append/edit the skill file minimally, keeping its existing format.

## Rules

- No silent writes. Proposal first, edit only after explicit yes.
- Small entries. A lesson is a rule, not an essay.
