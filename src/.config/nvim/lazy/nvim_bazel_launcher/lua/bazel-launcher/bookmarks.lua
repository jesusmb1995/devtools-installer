local config = require("bazel-launcher.config")
local targets = require("bazel-launcher.targets")

local M = {}

local function bookmark_path(root)
    return root .. "/" .. config.get().bookmarks.file
end

local function stats_path(root)
    return bookmark_path(root) .. "_stats"
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
function M.maybe_save(type, target, command)
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
        local ok, res = pcall(cfg.name, type, target)
        if not ok then
            vim.notify("bazel-launcher: bookmarks.name error: " .. tostring(res), vim.log.levels.ERROR)
            return false
        end
        raw_name = res
    else
        raw_name = M.default_name(type, target)
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
