# projnote

In-place project notes for Neovim: a note at the current line (`qn`),
a project-wide note (`qN`), pickers to jump between them, and sign-column
marks. Standalone local plugin — no network dependency, no plenary, no
migration, no legacy filename support.

Notes live outside the repo so they follow you across `jj` patches and
rebases (keyed by project root, never by branch):

```
~/.local/share/projnote/<sha256(root)[:16]>/<stem>_<line>_<hash4>.md
~/.local/share/projnote/<sha256(root)[:16]>/project.md   (project note)
~/.local/share/projnote/<sha256(root)[:16]>/index        (<filename> <relpath>)
```

Note files are readable and flat: `examplefile:1` becomes
`examplefile_1_dn5f.md`, where the 4-char suffix is the tail of the sha1 of
the project-relative path (same-named files in different dirs stay apart).
Dotfiles are de-hidden, e.g. `.env:3` becomes `_env_3_<hash4>.md`. The `index`
file maps each note filename back to its project-relative path, so
project-wide listing never scans the tree.

Sibling workspaces (same jj repo, any naming) join in via `qw`/`qW`:
each workspace keeps its own store, sources resolve from each store's own
index, and items are tagged `[wsname]`. The project root is resolved from
the buffer's directory, so one nvim session across several workspaces files
every note in the right store.

## Install (lazy.nvim, staged `dir=` plugin)

```lua
{
    dir = vim.fn.stdpath("data") .. "/lazy/projnote",
    name = "projnote",
    lazy = true,
    config = function()
        require("projnote").setup({})
    end,
}
```

In this monorepo the spec (`nvim/projnote.lua`) and body (`lua/`) are
staged by `generate_nvim_projnote.ab` / `generate_nvim_projnote_postrender.ab`
for bundles that enable the `projnote` repo.

## Keymaps

| Mode | Keymap       | Behavior                                              |
|------|--------------|-------------------------------------------------------|
| n    | `<leader>qn` | New note at current line (also records the index entry) |
| n    | `<leader>qN` | Go to the project note (create if missing, no prompt) |
| n    | `<leader>qo` | Open the note at the current line                     |
| n    | `<leader>qd` | Delete the note at the current line                   |
| n    | `<leader>ql` | List project notes — `<CR>` jump, `<C-e>` open note   |
| n    | `<leader>qL` | List this file's notes — `<CR>` jump, `<C-e>` open note |
| n    | `<leader>qw` | List all notes incl. other workspaces (tagged `[wsname]`) |
| n    | `<leader>qW` | List this file's notes incl. other workspaces           |
| n    | `<leader>q]` | Jump to next note in file (wraps around)              |
| n    | `<leader>q[` | Jump to previous note in file (wraps around)          |
| n    | `<leader>qt` | Toggle note signs (on by default)                     |

Without [snacks.nvim](https://github.com/folke/snacks.nvim) the pickers fall
back to printing the list. Line notes sort numerically, named notes
alphabetically; the preview shows the first 60 lines as markdown.

## Options

All options are optional:

```lua
require("projnote").setup({
    -- Note store root (default ~/.local/share/projnote).
    base = nil,
    -- Sign-column glyph (default U+F0AE, same as vim-bookmarks).
    sign_text = nil,
})
```

## Modules

| Module              | Owns                                              |
|---------------------|---------------------------------------------------|
| `projnote.filename` | Readable stems, `<stem>_<line>_<hash4>.md` names + parsing/splitting |
| `projnote.storage`  | Store layout formulas + 4-char suffix             |
| `projnote.index`    | Note-filename to relpath index file               |
| `projnote.lines`    | Line extraction + next/prev cycling               |
| `projnote.journal`  | Per-directory journal identity (same formula as the nvim `notes-resources` mappings) |

## Tests

```sh
bash user/repos/projnote/test/run_tests.sh
```

Runs every spec in `test/spec/` with `nvim --headless` (no dependencies).
