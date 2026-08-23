local config = require("bazel-launcher.config")
local targets = require("bazel-launcher.targets")
local bookmarks = require("bazel-launcher.bookmarks")

local M = {}

M.last = nil

local function valid_command(cmd)
    if type(cmd) == "string" then
        return cmd ~= ""
    end
    if type(cmd) ~= "table" then
        return false
    end
    if #cmd == 0 then
        return false
    end
    for _, part in ipairs(cmd) do
        if type(part) ~= "string" or part == "" then
            return false
        end
    end
    return true
end

local function resolve_command(launch_type, target)
    local cfg = config.get()
    if cfg.build_command then
        local ok, res = pcall(cfg.build_command, launch_type, target)
        if not ok then
            vim.notify("bazel-launcher: build_command error: " .. tostring(res), vim.log.levels.ERROR)
            return nil, tostring(res)
        end
        if not valid_command(res) then
            return nil, "build_command must return a non-empty string or a list of non-empty strings"
        end
        return res, nil
    end
    local bin = targets.resolve_bin()
    if not bin then
        return nil, "no bazel binary available"
    end
    return string.format("%s %s %s", bin, launch_type, target), nil
end

function M.build_command_string(launch_type, target)
    local cmd, err = resolve_command(launch_type, target)
    if not cmd then
        return nil, err
    end
    if type(cmd) == "table" then
        return table.concat(cmd, " "), nil
    end
    return cmd, nil
end

local function open_float()
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = "rounded",
    })
end

local function open_window(mode)
    if mode == "float" then
        open_float()
        return
    end
    if mode == "vert" then
        vim.cmd("botright 80vsplit")
    elseif mode == "current" then
        -- stay in the current window
    else
        vim.cmd("botright 15split")
    end
    -- Splits inherit the current (possibly modified) buffer and "current"
    -- reuses it directly; termopen refuses modified buffers
    -- ("requires unmodified buffer"). Always switch the window to a fresh
    -- scratch buffer before termopen.
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
end

local function safe_startinsert()
    if #vim.api.nvim_list_uis() == 0 then
        return
    end
    local mode = vim.api.nvim_get_mode().mode
    if mode:find("i") or mode:find("R") or mode == "t" then
        return
    end
    pcall(vim.cmd, "startinsert")
end

-- Horizontal launches go through the nvim config's shared WARM horizontal
-- terminal — the same inner-tmux (Ctrl+B) bottom panel the <C-g>/<A-g>
-- toggle, cmd bookmarks (LaunchHoriz) and the shell/ctest runner use — so
-- everything runs in ONE bottom panel. Falls back to nvchad's plain
-- htoggleTerm runner when that module is unavailable (standalone setups /
-- unit tests), and to a private window without nvchad. Returns true when a
-- shared path handled the launch.
local function launch_via_shared_panel(cmd_string, cfg)
    if cfg.terminal.mode == "float" or cfg.terminal.mode == "vert" or cfg.terminal.mode == "current" then
        return false
    end
    local ok_warm, warm = pcall(require, "mappings.terminal")
    if ok_warm and type(warm) == "table" and type(warm.run_in_horizontal_warm) == "function" then
        local run_cmd = cmd_string
        local root = targets.workspace_root()
        if root and root ~= "" and vim.fn.getcwd() ~= root then
            run_cmd = "cd " .. vim.fn.shellescape(root) .. " && " .. cmd_string
        end
        warm.run_in_horizontal_warm(run_cmd)
        return true
    end
    local ok, term = pcall(require, "nvchad.term")
    if not ok or type(term) ~= "table" or type(term.runner) ~= "function" then
        return false
    end
    local run_cmd = cmd_string
    local root = targets.workspace_root()
    if root and root ~= "" and vim.fn.getcwd() ~= root then
        run_cmd = "cd " .. vim.fn.shellescape(root) .. " && " .. cmd_string
    end
    term.runner {
        pos = "sp",
        cmd = run_cmd,
        id = "htoggleTerm",
        clear_cmd = false,
    }
    return true
end

function M.launch(launch_type, target)
    if launch_type ~= "run" and launch_type ~= "build" then
        vim.notify("bazel-launcher: invalid launch type: " .. tostring(launch_type), vim.log.levels.ERROR)
        return nil
    end
    if not target or target == "" then
        vim.notify("bazel-launcher: missing target", vim.log.levels.ERROR)
        return nil
    end
    local cmd, err = resolve_command(launch_type, target)
    if not cmd then
        vim.notify("bazel-launcher: " .. tostring(err or "cannot build command"), vim.log.levels.ERROR)
        return nil
    end
    local cmd_string = type(cmd) == "table" and table.concat(cmd, " ") or cmd
    local ctx = { type = launch_type, target = target, command = cmd_string }
    local cfg = config.get()
    if cfg.on_command then
        local ok, res = pcall(cfg.on_command, cmd_string, ctx)
        if not ok then
            vim.notify("bazel-launcher: on_command error: " .. tostring(res), vim.log.levels.ERROR)
        end
    end
    bookmarks.maybe_save(launch_type, target, cmd_string)
    M.last = { type = launch_type, target = target, command = cmd_string }
    if launch_via_shared_panel(cmd_string, cfg) then
        safe_startinsert()
        return cmd_string
    end
    open_window(cfg.terminal.mode)
    -- string commands run via sh -c, list commands exec directly
    vim.fn.termopen(cmd, { cwd = targets.workspace_root() })
    vim.cmd("setlocal nonumber")
    safe_startinsert()
    return cmd_string
end

function M.launch_last()
    if not M.last then
        vim.notify("bazel-launcher: no previous command to launch", vim.log.levels.WARN)
        return nil
    end
    return M.launch(M.last.type, M.last.target)
end

return M
