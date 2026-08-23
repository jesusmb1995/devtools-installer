local M = {}

local config = nil

local function defaults()
    return {
        bazel_bin = "auto",
        query = { "query", "//..." },
        workspace_markers = { "WORKSPACE", "WORKSPACE.bazel", "MODULE.bazel", "BUILD", "BUILD.bazel" },
        root = nil,
        build_command = nil,
        on_command = nil,
        bookmarks = {
            enabled = true,
            file = ".local_cmd_bookmarks",
            save = { run = true, build = true },
            name = nil,
        },
        terminal = { mode = "horiz" },
        keymaps = { picker = "<leader><A-G>" },
        picker = { theme_opts = {} },
    }
end

M.defaults = defaults

local function is_string_list(v)
    if type(v) ~= "table" then
        return false
    end
    for _, item in ipairs(v) do
        if type(item) ~= "string" then
            return false
        end
    end
    return true
end

local function fail(msg)
    error("bazel-launcher: invalid config: " .. msg)
end

local function validate(opts)
    if opts.bazel_bin ~= nil and type(opts.bazel_bin) ~= "string" then
        fail("bazel_bin must be a string")
    end
    if opts.query ~= nil and type(opts.query) ~= "function" and not is_string_list(opts.query) then
        fail("query must be a list of strings or a function")
    end
    if opts.workspace_markers ~= nil and (not is_string_list(opts.workspace_markers) or #opts.workspace_markers == 0) then
        fail("workspace_markers must be a non-empty list of strings")
    end
    if opts.root ~= nil and type(opts.root) ~= "string" then
        fail("root must be a string")
    end
    if opts.build_command ~= nil and type(opts.build_command) ~= "function" then
        fail("build_command must be a function")
    end
    if opts.on_command ~= nil and type(opts.on_command) ~= "function" then
        fail("on_command must be a function")
    end
    if opts.bookmarks ~= nil then
        if type(opts.bookmarks) ~= "table" then
            fail("bookmarks must be a table")
        end
        local b = opts.bookmarks
        if b.enabled ~= nil and type(b.enabled) ~= "boolean" then
            fail("bookmarks.enabled must be a boolean")
        end
        if b.file ~= nil and type(b.file) ~= "string" then
            fail("bookmarks.file must be a string")
        end
        if b.save ~= nil then
            if type(b.save) ~= "table" then
                fail("bookmarks.save must be a table")
            end
            if b.save.run ~= nil and type(b.save.run) ~= "boolean" then
                fail("bookmarks.save.run must be a boolean")
            end
            if b.save.build ~= nil and type(b.save.build) ~= "boolean" then
                fail("bookmarks.save.build must be a boolean")
            end
        end
        if b.name ~= nil and type(b.name) ~= "function" then
            fail("bookmarks.name must be a function")
        end
    end
    if opts.terminal ~= nil then
        if type(opts.terminal) ~= "table" then
            fail("terminal must be a table")
        end
        local modes = { horiz = true, vert = true, float = true, current = true }
        if opts.terminal.mode ~= nil and not modes[opts.terminal.mode] then
            fail("terminal.mode must be one of horiz, vert, float, current")
        end
    end
    if opts.keymaps ~= nil then
        if type(opts.keymaps) ~= "table" then
            fail("keymaps must be a table")
        end
        if opts.keymaps.picker ~= nil and type(opts.keymaps.picker) ~= "string" then
            fail("keymaps.picker must be a string")
        end
    end
    if opts.picker ~= nil then
        if type(opts.picker) ~= "table" then
            fail("picker must be a table")
        end
        if opts.picker.theme_opts ~= nil and type(opts.picker.theme_opts) ~= "table" then
            fail("picker.theme_opts must be a table")
        end
    end
end

function M.setup(opts)
    opts = opts or {}
    if type(opts) ~= "table" then
        fail("setup() expects a table")
    end
    validate(opts)
    config = vim.tbl_deep_extend("force", defaults(), opts)
    -- list-valued options must replace, not merge by index
    for _, key in ipairs({ "query", "workspace_markers" }) do
        if opts[key] ~= nil then
            config[key] = opts[key]
        end
    end
    return config
end

function M.get()
    if not config then
        config = defaults()
    end
    return config
end

return M
