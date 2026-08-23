local config = require("bazel-launcher.config")

local M = {}

local TTL = 300

local root_cache = {}
local list_cache = {}

local function abspath(path)
    -- vim.fs.abspath is 0.11+ only; fnamemodify ":p" works on 0.9+. It
    -- appends a trailing slash for directories -- strip it so dir compare
    -- and dirname walks stay consistent.
    local p = vim.fn.fnamemodify(vim.fs.normalize(path), ":p")
    if p ~= "/" and p:sub(-1) == "/" then
        p = p:sub(1, -2)
    end
    return p
end

function M.resolve_bin()
    local cfg = config.get()
    if cfg.bazel_bin ~= "auto" then
        if vim.fn.executable(cfg.bazel_bin) == 1 then
            return cfg.bazel_bin
        end
        vim.notify("bazel-launcher: bazel_bin is not executable: " .. cfg.bazel_bin, vim.log.levels.ERROR)
        return nil
    end
    for _, candidate in ipairs({ "bazel", "bazelisk" }) do
        if vim.fn.executable(candidate) == 1 then
            return candidate
        end
    end
    vim.notify("bazel-launcher: no bazel binary found (tried bazel, bazelisk)", vim.log.levels.ERROR)
    return nil
end

-- Upward walk from a buffer name or directory to the first dir holding a marker.
function M.find_root(from)
    from = abspath(from or vim.fn.getcwd())
    if vim.fn.isdirectory(from) == 0 then
        from = vim.fs.dirname(from)
    end
    local cached = root_cache[from]
    if cached ~= nil then
        return cached or nil
    end
    local markers = config.get().workspace_markers
    local dir = from
    while dir do
        for _, marker in ipairs(markers) do
            if vim.fn.filereadable(dir .. "/" .. marker) == 1 then
                root_cache[from] = dir
                return dir
            end
        end
        local parent = vim.fs.dirname(dir)
        if parent == dir then
            break
        end
        dir = parent
    end
    root_cache[from] = false
    return nil
end

function M.workspace_root()
    local cfg = config.get()
    if cfg.root then
        return cfg.root
    end
    return M.find_root()
end

local function resolve_query_args(opts, cfg)
    local query = opts.query or cfg.query
    if type(query) == "function" then
        local ok, res = pcall(query)
        if not ok then
            return nil, "query function failed: " .. tostring(res)
        end
        query = res
    end
    if type(query) == "string" then
        local args = {}
        for _, part in ipairs(vim.split(query, "%s+")) do
            if part ~= "" then
                args[#args + 1] = part
            end
        end
        return args
    end
    if type(query) == "table" then
        return query
    end
    return nil, "query must resolve to a string or a list"
end

local function is_junk(line)
    return line == ""
        or line:match("^Loading:")
        or line:match("^INFO:")
        or line:match("^WARNING:")
        or line:match("^Analyzing")
end

local function is_label(line)
    return line:sub(1, 2) == "//" or line:sub(1, 1) == "@"
end

function M.parse_labels(lines)
    local seen = {}
    local labels = {}
    for _, line in ipairs(lines) do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if not is_junk(line) and is_label(line) then
            if not seen[line] then
                seen[line] = true
                labels[#labels + 1] = line
            end
        end
    end
    table.sort(labels)
    return labels
end

function M.list(opts, cb)
    opts = opts or {}
    local cfg = config.get()
    local bin = opts.bazel_bin or M.resolve_bin()
    if not bin then
        cb(nil, "no bazel binary available")
        return
    end
    local args, err = resolve_query_args(opts, cfg)
    if not args then
        cb(nil, err)
        return
    end
    local root = opts.root or cfg.root or M.find_root()
    local key = tostring(root) .. "|" .. bin .. "|" .. table.concat(args, " ")
    local cached = list_cache[key]
    if cached and os.time() - cached.time < TTL then
        cb(vim.deepcopy(cached.labels), nil)
        return
    end
    local argv = { bin }
    for _, arg in ipairs(args) do
        argv[#argv + 1] = arg
    end
    local out_lines = {}
    local err_lines = {}
    local function drain(dest, data)
        for i, line in ipairs(data) do
            if i < #data or line ~= "" then
                dest[#dest + 1] = line
            end
        end
    end
    vim.fn.jobstart(argv, {
        cwd = root,
        on_stdout = function(_, data)
            drain(out_lines, data)
        end,
        on_stderr = function(_, data)
            drain(err_lines, data)
        end,
        on_exit = function(_, code)
            if code ~= 0 then
                local msg = table.concat(err_lines, "\n")
                if msg == "" then
                    msg = bin .. " exited with code " .. code
                end
                cb(nil, msg)
                return
            end
            local labels = M.parse_labels(out_lines)
            list_cache[key] = { labels = labels, time = os.time() }
            cb(vim.deepcopy(labels), nil)
        end,
    })
end

function M.clear_cache()
    list_cache = {}
    root_cache = {}
end

return M
