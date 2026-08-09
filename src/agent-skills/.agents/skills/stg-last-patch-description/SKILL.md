---
name: stg-last-patch-description
description: Rewrite the top StGit patch description only. Use when the user asks to improve, shorten, polish, or normalize the last/current StGit patch message, patch description, short description, or long description.
compatibility: Requires StGit with the `stg` command available.
---

# StGit Last Patch Description

## Goal

Review only the top applied StGit patch and update its message with concise text:

- Short description: one imperative subject, usually 50 characters or less.
- Long description: 1-3 short paragraphs or bullets explaining why the patch exists.
- No verbose summaries, file inventories, or obvious restatements of the diff.

## Workflow

1. Confirm the repository uses StGit:
   ```bash
   stg series
   ```
2. Select exactly one patch:
   - If the user names a patch, use that patch.
   - Otherwise use the top applied patch:
     ```bash
     stg top
     ```
3. Inspect both the message and diff:
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
- Do not rewrite more than one patch in one pass.

## If Context Is Unclear

Ask before editing if the patch intent cannot be inferred from `stg show`, or if the selected patch appears to need squashing, splitting, or reordering.
