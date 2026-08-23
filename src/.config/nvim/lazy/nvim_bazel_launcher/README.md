# nvim_bazel_launcher

A Neovim plugin (Lua, Telescope picker) to list, run and build
[bazel](https://bazel.build) targets of the current workspace.

- `<leader><A-G>` opens a dropdown picker with every target in the workspace.
- `<CR>` on a target runs it, `<C-d>` builds it, `<C-r>` refreshes the target cache.
- Launched commands are auto-bookmarked to `.local_cmd_bookmarks`
  (compatible with the `cmd_bookmarks` repo format).

## Requirements

- Neovim >= 0.9
- [telescope.nvim](https://github.com/nvchad/telescope.nvim) (any recent version)
- A bazel binary on `PATH`: `bazel` or `bazelisk`

## Install (lazy.nvim, staged `dir=` plugin)

```lua
{
    "nvim_bazel_launcher",
    dir = vim.fn.stdpath("data") .. "/lazy/nvim_bazel_launcher",
    lazy = true,
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
        require("bazel-launcher").setup()
    end,
}
```

## Commands

| Command             | Behavior                                              |
|---------------------|-------------------------------------------------------|
| `:BazelTargets`     | Open the target picker                                |
| `:BazelRun [target]`| Run `target`, or open the picker when no arg is given |
| `:BazelBuild [target]` | Build `target`, or open the picker when no arg is given |
| `:BazelLast`        | Re-launch the last launched target                    |

## Keymaps

| Mode | Keymap      | Picker action                              |
|------|-------------|--------------------------------------------|
| n    | `<leader><A-G>` | Open the picker (set in `setup()` only if unmapped) |
| i/n  | `<CR>`      | Run the selected target                    |
| i/n  | `<C-d>`     | Build the selected target                  |
| i/n  | `<C-r>`     | Clear the target cache and reopen the picker |

## Binary resolution

`bazel_bin = "auto"` (default) resolves at query/launch time to the first
executable found on `PATH` among `bazel`, `bazelisk` — in that order.
An explicit string (e.g. `"bazelisk"` or an absolute path) always wins. When no
binary is found the plugin notifies an error and does nothing else.

## Options

All options are optional and deep-merged over the defaults:

```lua
require("bazel-launcher").setup({
    -- "auto" picks the first executable among bazel, bazelisk.
    bazel_bin = "auto",
    -- Args appended to the binary for target discovery. A function returning
    -- a string or a list gives full control.
    query = { "query", "//..." },
    -- Upward search (from the buffer cwd) for the workspace root; the root is
    -- used as cwd for the query job and to locate .local_cmd_bookmarks.
    workspace_markers = { "WORKSPACE", "WORKSPACE.bazel", "MODULE.bazel", "BUILD", "BUILD.bazel" },
    -- Explicit workspace root; overrides marker detection.
    root = nil,
    -- function(type, target) -> string|list. type is "run" or "build".
    -- Default: string.format("%s %s %s", resolved_bin, type, target).
    build_command = nil,
    -- function(cmd, ctx) fired right before launch with
    -- ctx = { type = "run"|"build", target = "<label>", command = cmd }.
    -- Errors inside it are reported but never abort the launch.
    on_command = nil,
    bookmarks = {
        enabled = true,
        file = ".local_cmd_bookmarks",
        save = { run = true, build = false },
        name = nil, -- function(type, target) -> raw bookmark name
    },
    terminal = { mode = "horiz" }, -- "horiz" | "vert" | "float" | "current"
    keymaps = { picker = "<leader><A-G>" },
    picker = { theme_opts = {} }, -- merged over telescope.themes.get_dropdown()
})
```

String commands are launched with `vim.fn.jobstart(cmd_string, { term = true })`
semantics (run via `sh -c`); list commands are executed directly without a
shell.

### Example 1: custom command lambda

```lua
require("bazel-launcher").setup({
    build_command = function(type, target)
        return "myalias runfast --flag " .. target
    end,
})
```

Selecting `//pkg/demo:demo_bin` and pressing `<CR>` now launches
`myalias runfast --flag //pkg/demo:demo_bin` instead of `bazel run ...`.
Returning a list (`{ "myalias", "runfast", target }`) skips the shell entirely.

### Example 2: auto-bookmarking to `.local_cmd_bookmarks`

Bookmarks integrate with the `cmd_bookmarks` repo. Each line is
`raw_name|command`; `raw_name` may contain `+`-separated dependency segments
(`dep1+dep2+name`) — the last segment is the display name, the rest are other
bookmark names that cmd_bookmarks chains before it.

By default every **run** launch appends/replaces a line in
`.local_cmd_bookmarks` at the workspace root, and updates the
`.local_cmd_bookmarks_stats` sidecar (`name|<unix_ts>`, mirroring the zsh
`_update_cmd_stats`). The bookmark name is the short target label — the text
after the last `:` in `//pkg/path:name` (or after the last `/` when the label
equals the directory name) — with a `_build` suffix for build launches:

```
demo_bin|bazel run //pkg/demo:demo_bin
demo_bin_build|bazel build //pkg/demo:demo_bin
```

Re-launching the same target replaces its line in place (no duplicates, file
order preserved); other lines are never touched. When no workspace root can be
found the launch still works, only the bookmark/stats write is skipped.

The `bookmarks.save` matrix controls which launch types are saved:

| `save.run` | `save.build` | run launch        | build launch        |
|------------|--------------|-------------------|---------------------|
| `true`     | `false`      | saved (default)   | skipped             |
| `true`     | `true`       | saved             | saved (with `_build`) |
| `false`    | `true`       | skipped           | saved               |
| `false`    | `false`      | skipped           | skipped             |

`bookmarks.enabled = false` disables all bookmark writes, and
`bookmarks.name` overrides the generated name:

```lua
require("bazel-launcher").setup({
    bookmarks = {
        enabled = true,
        save = { run = true, build = true },
        name = function(type, target)
            -- raw_name may reference other bookmarks as dependencies:
            -- "build_demo+demo_bin" runs bookmark "build_demo" first.
            local label = target:match(":([^:]+)$") or target
            if type == "build" then
                return "build_" .. label .. "+" .. label
            end
            return label
        end,
    },
})
```

Use `on_command` for fully custom side effects (it receives the final command
string and a context table) — for example writing to an unrelated history
file. The built-in bookmark integration covers the `.local_cmd_bookmarks` case.

## Tests

```sh
bash test/run_tests.sh
```

Runs every spec in `test/spec/` with `nvim --headless` against a fake `bazel`
binary (no bazel installation required).
