---
name: recommend-skills-plan
description: Itemized plan of which skills to use in which order for a given task. Use when user writes /recommend-skills-plan <task>.
---

# recommend-skills-plan

Not one skill — an ordered plan: which skills first, which second, to finish the passed task.

## Trigger

`/recommend-skills-plan <task>`

## Procedure

1. List available skills (`ls ~/.agents/skills/`).
2. Pick only skills that move this task forward. Skip the rest.
3. Output ordered items, first to last:

```
- /skill-one — why now
- /skill-two — why after one
```

4. No skill fits a step? Say "handle directly".
