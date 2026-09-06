---
name: journal-dir-update
description: Update or create per-directory journal at $HOME/Documents/journal/<title>-<hash>.md keyed by directory path hash. Use when user writes /journal-dir-update, asks to save notes, journal a directory, or persist directory context.
---

# journal-dir-update

Create or update the per-directory journal file `$HOME/Documents/journal/<optional_humanreadable_title>-<hash>.md`. One file per hash — enforce uniqueness.

## Trigger

User writes `/journal-dir-update [optional_title] [dir_path]` or asks to journal / save notes for a directory.

## Hash script

Bundled helper: `scripts/hash_dir.sh` (also at `hash_dir.sh` for legacy path). Calculates stable 8-char hex hash of the canonical absolute directory path.

```bash
# from skill root:
sh .agents/skills/journal-dir-update/scripts/hash_dir.sh "/absolute/or/relative/path"
# prints: <hash>
# or inline without script:
# canon=$(realpath -m "$dir"); printf "%s" "$canon" | sha256sum | cut -c1-8
```

`hash_dir.sh` contract:
- Input: directory path (default: `pwd`).
- Canonicalizes via `realpath -m` (fallback `pwd -P`).
- Hash: `printf "%s" "$canon" | sha256sum | cut -c1-8` (fallback `shasum -a 256` / `openssl dgst -sha256`).
- Output: 8-char lowercase hex to stdout, no newline noise.

## Procedure

1. Resolve target directory:
   - If user supplied `dir_path`, use it; else `pwd`.
   - Canonicalize to absolute path for hashing: `canon=$(realpath -m "$dir")` (fallback `cd "$dir" && pwd -P`).
   - Compute hash: `hash=$(sh .agents/skills/journal-dir-update/scripts/hash_dir.sh "$canon")` or inline equivalent. Verify `[[ "$hash" =~ ^[0-9a-f]{8}$ ]]`.

2. Resolve title:
   - If user supplied `optional_title`, slugify it (`a-z0-9-`, spaces→`-`, trim leading/trailing `-`, lowercase). Empty → omit title part.
   - If no title supplied and a journal for this hash already exists (`$HOME/Documents/journal/*-$hash.md`), reuse its existing title prefix.
   - If no title and no existing file, use directory basename slugified or just `<hash>` as filename.

3. Ensure journal dir: `mkdir -p "$HOME/Documents/journal"`.

4. Enforce one-file-per-hash invariant (critical):
   ```bash
   hash="abc12345"
   existing=( "$HOME/Documents/journal/"*-"$hash.md" )  # glob
   # If 0 matches → will create new file
   # If 1 match and it equals the desired path → update in place
   # If 1 match but title differs → mv old to new (preserve content) or if --title given, rename
   # If >1 matches → keep newest (or the one with desired title if present), merge content if needed, rm the rest
   ```
   Steps:
   - Glob `*-$hash.md`. For each match, `ls -t`.
   - If multiple files share the hash, keep exactly one: prefer the file whose title matches the requested title; otherwise keep the most recently modified. If contents differ, concatenate unique sections into the survivor before deleting duplicates. Then `rm` the others and log what was removed.
   - If a single stale title exists and a new title was requested, `mv "$old" "$new"` (atomic rename), keeping history.

5. Create or update the journal file `$HOME/Documents/journal/<title>-<hash>.md` (or `$hash.md` if no title):
   ```markdown
   # <human readable title or basename> — `canon`
   Hash: `<hash>`  Path: `canon`

   ## Summary
   <concise context, decisions, TODOs for this directory>

   ## Details
   <whatever the user asked to persist>

   ## Log
   - YYYY-MM-DD HH:MM — <entry>
   ```

   - If file exists, update relevant sections and append a dated `Log` entry rather than overwriting blindly. Preserve prior content.
   - If new, write full template above.

6. After write, verify invariant: `ls -1 "$HOME/Documents/journal/"*-"$hash.md" | wc -l` must be `1`. Print `Journal: ~/Documents/journal/<file> (hash <hash> for <canon>)`.

## Rules

- Never leave two `*-<hash>.md` files for the same hash. Always deduplicate.
- Hash is derived from canonical absolute path, not title — title changes must not create a second file.
- Append, don't clobber: updates preserve history via `## Log`.
- Use `sha256sum` → `cut -c1-8`; document truncation length in the file header if you deviate.
