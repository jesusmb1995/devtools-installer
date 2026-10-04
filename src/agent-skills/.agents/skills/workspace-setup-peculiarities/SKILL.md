---
name: workspace-setup-peculiarities
description: In-depth guide to this box's peculiarities — command bookmarks, tmux layers, jj workspaces, shared notes. Use when user writes /workspace-setup-peculiarities, asks how something works here, or something behaves unexpectedly.
---

# Workspace setup peculiarities

AGENT.md summarizes; this file explains. Read the section you need, skip the rest.

## Command bookmarks

Never retype long commands. `cmdsave [name]` stores the last shell command; `cmdrun [name]` replays it (`-d` resolves `dep+name` chains first). Storage is centralized: `~/.local/share/cmd_bookmarks/<cwd-with-/-as-_>/.local_cmd_bookmarks` (plus `_stats`), auto-imported once from a legacy in-cwd file. In nvim the same store backs `<leader><A-h>`/`<A-v>` runners and the bazel launcher.

## Tmux layers

Two sockets, never mix them. Agent shells live on the **default** socket (warm daemon) — bare `tmux` commands land there, which is correct. The outer window-manager layer lives on **`-L wm`** with Alt-chord bindings; do not send agent commands to it. Sessions named `warm-*` with 0 attached clients are reusable scratch. Always `kill-session` what you spawn.

## jj workspaces

Repos use jj, not git. Parallel work happens in sibling workspaces: main checkout plus `-agent` (ephemeral) or `-secondary` (durable) siblings. Never edit across workspaces in one task — pick one (`/jjws`), merge via `/per_patch`. Stale `-agent` workspaces: `/jj-workspace-cleanup`; old ones generally: `/cleanup-old-workspaces` (dry-run first, confirm before delete).

## Shared notes and resources

Notes live outside repos: per-line/file notes via `<leader>q*` (projnote store `~/.local/share/projnote/`), per-directory journal via `/journal-dir-update` (same file `:Journal` opens in nvim). `~/projtmp/<project>/` aggregates one project's notes, journal, bookmarks, and sibling-workspace links — open with `<leader>qr`, resolve identity with `/proj-resource`.

## Nvim

`<leader>?` opens the quicksheet (all keymaps, `<C-s>` filters by section). `<C-n>` toggles the file tree rooted at the tab cwd. Agent terminals: `<leader><C-l>`; attach context with `<C-l>`. Drive a live instance via `/nvim-control`, never kill it. Approval needed: noice-notify that instance with tab number + instance id, skip when it is focused (`rules/nvim.md`).
