---
name: proj-resource
description: Resolve the project-resource directory at $HOME/projtmp/<original-workspace> from a jj workspace, git checkout, or nvim project cwd. Use when user writes /proj-resource, asks where project resources live, or needs the shared layout for notes/journal/bookmarks/sibling workspaces.
---

# proj-resource

Resolve identity first, then use the shared resource layout. This is the same
identity nvim uses for `:Journal`, `<leader>qj`, `:ProjResources`, and
`<leader>qr`.

## Trigger

User writes `/proj-resource [path]`, asks for the project-resource directory,
or needs to know which workspace/project a path belongs to.

## Identity

```bash
eval "$(sh .agents/skills/proj-resource/scripts/resolve.sh "[optional path]")"
# prints shell assignments:
# ROOT=/abs/current-workspace-root
# ORIG=original-workspace-basename
# SECONDARY=0|1
# RES=$HOME/projtmp/$ORIG
# JOURNAL_HASH=8-char-sha256-of-canonical-ROOT
# NOTES_STORE=$HOME/.local/share/quicknote/<sha256(ROOT)[:16]>
```

Resolution rules:

1. Start path: argument if given, else:
   - in nvim: current buffer's directory if the buffer has a file, else nvim's
     effective cwd (`:tcd`/tab-aware when available);
   - in shell: `pwd`.
2. Workspace root: nearest ancestor containing `.jj`; else
   `git rev-parse --show-toplevel` from the start path; else the start path.
3. Original workspace: strip one trailing `-secondary` plus optional digits from
   the root basename:
   - `myproj` → `ORIG=myproj`, `SECONDARY=0`
   - `myproj-secondary` / `myproj-secondary2` → `ORIG=myproj`, `SECONDARY=1`
4. Resource directory: `$HOME/projtmp/$ORIG`.
5. Journal hash: canonicalize root with `realpath -m`, remove trailing slash,
   then `sha256(canonical)[:8]`; journal file is
   `$HOME/Documents/journal/*-<hash>.md`.
6. Notes store: `$HOME/.local/share/quicknote/<sha256(ROOT)[:16]>`.

## Shared layout

`$HOME/projtmp/$ORIG` contains:

- `notes` → current workspace's quicknote project store
- `journal.md` → that workspace's `$HOME/Documents/journal/*-<hash>.md`
- `cmd-bookmarks` / `cmd-bookmarks-stats` → central
  `~/.local/share/cmd_bookmarks/<ROOT with / → _>/...` when deployed, else the
  workspace `.local_cmd_bookmarks*` files when present
- `workspaces/` → sibling workspaces' NOTE STORES (`~/.local/share/projnote/<sha256(sibling-root)[:16]>`, keyed by jj workspace name), not the checkouts: this tab aggregates notes. Siblings enumerated authoritatively via `jj workspace list` (any naming; `-secondary*` glob is the non-jj fallback), rebuilt on every open:
  - from a main workspace: every sibling workspace with notes
  - from a secondary workspace: only the main (`default`) workspace with notes
  - siblings with no notes yet are skipped until their first note lands
- `workspace-current` → the workspace root used for this resolution

Do not invent a second resource root. If a path does not resolve under these
rules, report `ROOT`, `ORIG`, and why it is ambiguous instead of guessing.
