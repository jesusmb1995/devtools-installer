# quicksheet

A small, self-contained Neovim plugin that turns a single `quicksheet.txt` file
(in your config dir) into a fuzzy-searchable cheat sheet — browsable via
[Telescope](https://github.com/nvim-telescope/telescope.nvim), editable in a
buffer, and auto-populated with the keymaps and user commands you have defined
but never wrote down. It never duplicates existing entries.

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "https://github.com/jesusmb1995/quicksheet",
  cmd = { "QuickSheet", "QuickEdit", "QuickUpdate" },
  keys = { "<leader>?" },
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("quicksheet").setup()
    require("telescope").load_extension("quicksheet")
  end,
}
```

## quicksheet.txt format

Lives at `vim.fn.stdpath("config") .. "/quicksheet.txt"`.

```
# lines starting with a single # are comments and are ignored
Find files | <leader>ff
Lazy plugin manager | :Lazy

## Telescope @fuzzy
Live grep | <leader>fg
```

- `## name @tag1 @tag2` — a section header. `name` is the text after `## ` up to
  the first ` @tag`; the `@word` tokens become the section's tags. A header
  resets the current section/tags for the entries that follow.
- `# ...` (single `#`) — comment, ignored.
- Blank lines are ignored.
- Any other line containing `|` is one entry: everything before the **first**
  `|` is the description, everything after is the code. Both are trimmed. Lines
  without `|` are skipped.

## Commands

| Command       | Action                                                        |
| ------------- | ------------------------------------------------------------ |
| `:QuickSheet` | Open the Telescope picker over `quicksheet.txt`.             |
| `:QuickEdit`  | Open `quicksheet.txt` in a buffer to edit.                    |
| `:QuickUpdate`| Scan defined keymaps (modes `n i v x`) and user commands, append the ones not already listed under a `## QuickUpdate` section, and report the count added (or "nothing to add"). Never duplicates. |

When `auto_mapping` is `true` (the default) and `<leader>?` is unmapped, it is
mapped to `:QuickSheet`.

## In-picker shortcuts

| Key       | Action                                                            |
| --------- | ---------------------------------------------------------------- |
| `<CR>`    | Fill the command line with a `:` entry (stop at `[` or `{`), without executing it. Non-command entries notify. |
| `<C-y>`   | Yank the entry code into register `0`.                           |
| `<C-e>`   | Close the picker and open `quicksheet.txt` for editing.          |

`select_or_execute` (run the entry instead of filling) is also available; bind it
in `setup({ telescope_mappings = { ["<A-CR>"] = "select_or_execute" } })`.

You can also launch the picker as `:Telescope quicksheet`.
