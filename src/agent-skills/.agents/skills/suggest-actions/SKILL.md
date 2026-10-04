---
name: suggest-actions
description: Give step-by-step UI actions (click, open, type, select) to achieve what the user wants; use an exact command whenever one replaces the clicks. Use when the user writes /suggest-actions.
---

# Suggest Actions

The user wants concrete steps, not an explanation. Tell them exactly where to click/type, in order.

## Trigger

User writes `/suggest-actions <what they want to do>`.

## Procedure

1. Prefer an exact command when one achieves the goal (terminal command, URL, palette action). Put it first.
2. Otherwise list numbered steps: open X → click Y → type Z → select W. One action per step, in click order.
3. One line of expected result per step or at the end (what they should see if it worked).

## Rules

- Steps, not prose. No background, no alternatives unless the first path can fail.
- Name UI elements exactly as labeled. Never invent menu names.
