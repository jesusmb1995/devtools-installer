---
name: ontop
description: Do the task on top of the current patch/change (@) without touching it — new change stacked above, @ stays intact. Use when the user writes /ontop or says "on top of current patch".
---

# Ontop

Work stacked above the current change, never inside it.

## Trigger

User writes `/ontop <task>`, or says the work goes on top of the current patch.

## Procedure

1. Show where you start: `jj st` + `jj log -r @` (change id, description, touched files). One glance, no deep review.
2. Do the task as a NEW change stacked on top of `@` (`jj new @` first, then work there).
3. Never amend, evolve, or reword `@`. If the task turns out to require touching `@`, stop and ask.

## Rules

- `@` is read-only. Parent untouched, descriptions untouched.
- stg equivalent: new patch on top of the stack instead of `--append`/`refresh` into the current one.
