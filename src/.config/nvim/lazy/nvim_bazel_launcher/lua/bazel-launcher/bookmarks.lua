local config = require("bazel-launcher.config")
local targets = require("bazel-launcher.targets")

local M = {}

-- Store layout mirrors cmd_bookmarks (savecmd-nvim.lua): when its central
-- store is deployed (~/.local/share/cmd_bookmarks/savecmd.zsh exists),
-- per-project subdirs there are the live store the UI reads; otherwise
-- files stay legacy-style in the workspace root. Writing anywhere else
-- makes launches invisible to the bookmarks UI.
local function store_paths(root)
    local central_root = vim.fn.expand("~/.local/share/cmd_bookmarks")
    if vim.fn.filereadable(central_root .. "/savecmd.zsh") == 1 then
        local dir = central_root .. "/" .. root:gsub("/", "_")
        vim.fn.mkdir(dir, "p")
        return dir .. "/.local_cmd_bookmarks", dir .. "/.local_cmd_bookmarks_stats"
    end
    return root .. "/" .. config.get().bookmarks.file,
        root .. "/" .. config.get().bookmarks.file .. "_stats"
end

local function bookmark_path(root)
    local path = store_paths(root)
    return path
end

local function stats_path(root)
    local _, stats = store_paths(root)
    return stats
end

-- Short label: text after the last ':' in //pkg/path:name, or after the last
-- '/' when the label is omitted (//pkg/path == //pkg/path:path). "_build"
-- suffix distinguishes build bookmarks from run ones.
function M.default_name(type, target)
    local label = target:match(":(.+)$")
    if not label then
        label = target:match("/([^/]+)$") or target
    end
    if type == "build" then
        label = label .. "_build"
    elseif type == "test" then
        label = label .. "_test"
    end
    return label
end

-- Replace the raw_name| line in place (keeping file order), or append it.
-- Other lines are never touched.
function M.save_bookmark(root, raw_name, command)
    if not root or not raw_name or not command then
        return false
    end
    local path = bookmark_path(root)
    local lines = {}
    if vim.fn.filereadable(path) == 1 then
        lines = vim.fn.readfile(path)
    end
    local prefix = raw_name .. "|"
    local found = false
    for i, line in ipairs(lines) do
        if line:sub(1, #prefix) == prefix then
            lines[i] = prefix .. command
            found = true
        end
    end
    if not found then
        lines[#lines + 1] = prefix .. command
    end
    vim.fn.writefile(lines, path)
    return true
end

-- Mirror of cmd_bookmarks _update_cmd_stats: drop the name| line and append
-- name|<timestamp> at the end.
function M.update_stats(root, name)
    if not root or not name then
        return false
    end
    local path = stats_path(root)
    local lines = {}
    if vim.fn.filereadable(path) == 1 then
        lines = vim.fn.readfile(path)
    end
    local prefix = name .. "|"
    local kept = {}
    for _, line in ipairs(lines) do
        if line:sub(1, #prefix) ~= prefix then
            kept[#kept + 1] = line
        end
    end
    kept[#kept + 1] = prefix .. os.time()
    vim.fn.writefile(kept, path)
    return true
end

-- Gated auto-save: bookmarks.enabled AND bookmarks.save[type] AND a
-- workspace root was found. Silently skipped otherwise (launch still works).
-- extra carries launch extras (e.g. {"--test_filter=Suite.Name"}); a
-- filtered run gets its own bookmark name so it never overwrites the
-- whole-target one (or vice versa).
function M.filter_suffix(extra)
    if type(extra) ~= "table" then
        return ""
    end
    for _, part in ipairs(extra) do
        local filter = type(part) == "string" and part:match("^%-%-test_filter=(.+)$")
        if filter and filter ~= "" then
            return "__" .. filter:gsub("[^%w%._%+-]", "_")
        end
    end
    return ""
end

function M.maybe_save(type, target, command, extra)
    local cfg = config.get().bookmarks
    if not cfg.enabled then
        return false
    end
    if not (cfg.save and cfg.save[type]) then
        return false
    end
    local root = targets.workspace_root()
    if not root then
        return false
    end
    local raw_name
    if cfg.name then
        local ok, res = pcall(cfg.name, type, target, extra)
        if not ok then
            vim.notify("bazel-launcher: bookmarks.name error: " .. tostring(res), vim.log.levels.ERROR)
            return false
        end
        raw_name = res
    else
        raw_name = M.default_name(type, target) .. M.filter_suffix(extra)
    end
    if not raw_name or raw_name == "" then
        return false
    end
    M.save_bookmark(root, raw_name, command)
    -- stats are keyed by the display name (last '+' segment of raw_name)
    M.update_stats(root, raw_name:match("([^+]+)$") or raw_name)
    return true
end

return M
