local config = require("bazel-launcher.config")

local M = {}

M.config = config
M.targets = require("bazel-launcher.targets")
M.launch = require("bazel-launcher.launch")
M.bookmarks = require("bazel-launcher.bookmarks")

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function open_picker()
    require("bazel-launcher.picker").open()
end

local function launch_command(launch_type, args)
    local target = trim(args or "")
    if target == "" then
        open_picker()
    else
        M.launch.launch(launch_type, target)
    end
end

function M.setup(opts)
    config.setup(opts)
    vim.api.nvim_create_user_command("BazelTargets", open_picker, {
        desc = "Pick a bazel target",
    })
    vim.api.nvim_create_user_command("BazelRun", function(args)
        launch_command("run", args.args)
    end, {
        nargs = "?",
        desc = "Bazel run [target] (no arg opens picker)",
    })
    vim.api.nvim_create_user_command("BazelBuild", function(args)
        launch_command("build", args.args)
    end, {
        nargs = "?",
        desc = "Bazel build [target] (no arg opens picker)",
    })
    vim.api.nvim_create_user_command("BazelTest", function(args)
        launch_command("test", args.args)
    end, {
        nargs = "?",
        desc = "Bazel test [target] (no arg opens picker)",
    })
    vim.api.nvim_create_user_command("BazelLast", function()
        M.launch.launch_last()
    end, {
        desc = "Re-launch last bazel command",
    })
    local lhs = config.get().keymaps.picker
    if lhs and lhs ~= "" and vim.fn.maparg(lhs, "n") == "" then
        vim.keymap.set("n", lhs, "<cmd>BazelTargets<cr>", { desc = "Bazel targets", silent = true })
    end
    return M
end

return M
