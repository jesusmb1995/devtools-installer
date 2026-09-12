---
name: do-task-from-md
description: Read a task from a markdown file, do it, and keep progress notes in a separate section of that same md. Use when user writes /do-task-from-md <path-to-md> or asks to run a task described in a md file.
---

# do-task-from-md

Read a task out of a .md, execute it, and keep a running progress log in the same file — separate section, never touching the task text.

## Trigger

User writes `/do-task-from-md <path-to-md>`.

## Procedure

1. Read the target .md. The task is the main body; everything else is instructions.
2. Execute the task step by step.
3. After each step (or at meaningful checkpoints), append a progress entry under a clearly separate section in the same file:

```
## Progress — <YYYY-MM-DD HH:MM>

- <step> — <result: done / failed / blocked>
- <step> — <result>
```

4. Never edit or rewrite the task section. Progress goes below it, in its own section.
5. When done, mark the final entry `[complete]` and summarize briefly.

## Rules

- Progress section is append-only. Old entries stay. Date every heading.
- If a step fails, log it as failed with the reason and keep going on the rest.
- If the .md does not exist or has no task, say so and stop.