---
name: stg-series-descriptions
description: Rewrite StGit patch descriptions for the current stack. Use when the user asks to improve, shorten, polish, or normalize stg series commit messages, patch descriptions, short descriptions, or long descriptions.
compatibility: Requires StGit with the `stg` command available.
---

# StGit Series Descriptions

## Goal

Review the current StGit stack and update at most five patches with concise messages:

- Short description: one imperative subject, usually 50 characters or less.
- Long description: 1-3 short paragraphs or bullets explaining why the patch exists.
- No verbose summaries, file inventories, or obvious restatements of the diff.

## Workflow

1. Confirm the repository uses StGit:
   ```bash
   stg series
   ```
2. Select patches to review:
   - If the user names patches, use those, capped at five.
   - Otherwise use the top applied patches from `stg series --applied`, capped at five.
3. For each selected patch, inspect both the message and diff:
   ```bash
   stg show <patch>
   ```
4. Write the replacement message as:
   ```text
   Short imperative subject

   Concise body explaining intent, tradeoffs, or user-visible behavior.
   ```
5. Apply it with `stg edit`:
   ```bash
   message="$(printf '%s\n\n%s\n' \
     'Short imperative subject' \
     'Concise body explaining intent, tradeoffs, or user-visible behavior.')"
   stg edit <patch> --message "$message"
   ```
6. Verify the result:
   ```bash
   stg show <patch>
   ```

## Message Rules

- Preserve technical terms from the patch when they matter.
- Prefer "fix", "add", "update", "remove", "refactor", or "document" as the first word.
- Mention tests only when the patch changes tests or testability is central.
- Do not include trailers unless they already exist and should be preserved.
- Do not rewrite more than five patches in one pass.

## If Context Is Unclear

Ask before editing if the patch intent cannot be inferred from `stg show`, or if multiple patches appear to need squashing, splitting, or reordering.
