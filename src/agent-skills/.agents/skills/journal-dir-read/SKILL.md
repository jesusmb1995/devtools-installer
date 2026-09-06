---
name: journal-dir-read
description: Read per-directory journal at $HOME/Documents/journal/*-<hash>.md keyed by directory path hash, read-only. Use when user writes /journal-dir-read, asks to load, recall, or view directory journal.
---

# journal-dir-read

Read-only load of the per-directory journal created by `/journal-dir-update`. Inserts content into context, no writes.

## Trigger

User writes `/journal-dir-read [dir_path]` or asks to load / recall / view directory journal/notes.

## Procedure

1. Resolve target directory: arg `dir_path` if given, else `pwd`. Canonicalize (`realpath -m` fallback `pwd -P`).
2. Compute hash using the same helper as the writer:
   ```bash
   hash=$(sh .agents/skills/journal-dir-update/scripts/hash_dir.sh "$canon")
   # fallback inline:
   # canon=$(realpath -m "$dir"); printf "%s" "$canon" | sha256sum | cut -c1-8
   ```
   Validate `^[0-9a-f]{8}$`.
3. Locate journal file: glob `"$HOME/Documents/journal/"*-"$hash.md"`.
   - 0 matches → report `No journal for <canon> (hash <hash>) at ~/Documents/journal/*-<hash>.md` and suggest `/journal-dir-update`. Stop.
   - 1 match → read it.
   - >1 matches → warn `Multiple journals for hash <hash> — invariant violated`, list them with `ls -l`, read the most recently modified one, and advise running `/journal-dir-update` to deduplicate. Do not delete.
4. Read and display/insert:
   ```bash
   cat "$HOME/Documents/journal/"*-"$hash.md"
   ```
   After reading, summarize key points (goal, last log entry, pending items) and state the source file.
5. Do not modify, create, or rename any file. Read-only.

## Rules

- Never write to `$HOME/Documents/journal/` — this skill only reads.
- Use the exact same hash derivation as `journal-dir-update` (canonical path → sha256 → 8 chars) so reads find what writes created.
- If the hash script is missing, use the inline `printf | sha256sum | cut -c1-8` fallback and note it.
