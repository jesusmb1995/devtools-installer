---
name: use-fitting-skill
description: Pick the skill that best fits the given task and apply it immediately (like /recommend-skill, but executes instead of just suggesting). Use when the user writes /use-fitting-skill.
---

# Use Fitting Skill

Same lookup as `/recommend-skill`, then do the work instead of stopping at the suggestion.

## Trigger

User writes `/use-fitting-skill <task here>`.

## Procedure

1. List available skills (`ls ~/.agents/skills/`) and pick the one that best fits the task — exactly like `/recommend-skill` would.
2. Say which skill you picked and in one line why (`/skill-name — why`).
3. Follow that skill's procedure immediately on the task. No separate confirmation round.
4. No skill fits? Say "no skill — handling directly" and do the task without one.

## Rules

- One skill per task. If the task needs several in order, say so up front (see `/recommend-skills-plan`) and start with the first.
- The pick is part of the answer, never silent.
