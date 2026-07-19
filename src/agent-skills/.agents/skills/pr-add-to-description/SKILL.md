---
name: pr-add-to-description
description: Update PR/MR description with additive changes only — appends or inserts content without removing existing text. Use when asked to add, append, or update a PR/MR description with new info.
compatibility: Read `system_assets` skill (`forge.md`) for body fetch/edit recipes.
---

# PR/MR Add to Description

**Forge commands:** `system_assets` skill (`forge.md`) (post/edit PR body).

## Goal

Append or insert content into a PR/MR description without removing any existing text. You can use `/humanizer` skill as well if available.

## Workflow

1. Fetch current description via forge asset.
2. Determine what to add (from user prompt or context).
3. Build new body = existing body + new content (append, or insert at logical position if instructed).
4. Show diff of what will be added before applying.
5. On confirmation: update body via forge asset (full body rewrite that still contains all prior text).

## Rules

- Never remove or rewrite existing text.
- Only add. Existing sentences/sections stay intact.
- If inserting mid-description, place at the most logical section boundary.
- Show the user what will be added before posting.
