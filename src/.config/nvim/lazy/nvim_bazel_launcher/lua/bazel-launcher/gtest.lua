local config = require("bazel-launcher.config")
local targets = require("bazel-launcher.targets")

local M = {}

-- GoogleTest case macros, one per line: TEST(Suite, Name),
-- TEST_F(Fixture, Name), TEST_P(Fixture, Name).
local CASE_F_PATTERN = "^%s*TEST_[FP]%s*%(%s*([%w_]+)%s*,%s*([%w_]+)"
local CASE_PATTERN = "^%s*TEST%s*%(%s*([%w_]+)%s*,%s*([%w_]+)"

-- Parse case list from raw lines: { { suite, name, lnum } }.
function M.cases(lines)
    local out = {}
    for i, line in ipairs(lines or {}) do
        local suite, name = line:match(CASE_F_PATTERN)
        if not suite then
            suite, name = line:match(CASE_PATTERN)
        end
        if suite and name then
            out[#out + 1] = { suite = suite, name = name, lnum = i }
        end
    end
    return out
end

function M.cases_in_buffer(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if vim.api.nvim_get_option_value("buftype", { buf = bufnr }) ~= "" then
        return {}
    end
    return M.cases(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
end

function M.has_tests(bufnr)
    return #M.cases_in_buffer(bufnr) > 0
end

-- Owning cc_test targets of the current file, async via the shared cached
-- query path. cb(labels, err). same_pkg_direct_rdeps avoids preloading the
-- universe (owner()/rdeps over //... choke on external repos); the file
-- label comes from the file's own package, so subpackages work too.
function M.owner_targets(cb)
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.api.nvim_get_option_value("buftype", { buf = bufnr }) ~= "" then
        cb(nil, "not a file buffer")
        return
    end
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
        cb(nil, "buffer has no file")
        return
    end
    local pkg = targets.package_for(name)
    if not pkg then
        cb(nil, "file is not in a bazel package (no BUILD)")
        return
    end
    local root = config.get().root or targets.find_root(name)
    local filelabel = pkg .. ":" .. vim.fs.basename(name)
    targets.list({
        query = { "query", "kind(cc_test, same_pkg_direct_rdeps(" .. filelabel .. "))" },
        root = root,
    }, cb)
end

local function pick(entries, prompt, cb)
    vim.ui.select(entries, {
        prompt = prompt,
        format_item = function(e)
            return e.label
        end,
    }, cb)
end

-- Test source files belonging to a target, as absolute paths. Uses the
-- target's srcs attribute so no open buffer is needed (this is the whole
-- point of C-s from the picker).
function M.sources_for_target(target, cb)
    targets.list({
        query = { "query", "labels(srcs, " .. target .. ")" },
    }, function(labels, err)
        if err then
            cb(nil, err)
            return
        end
        local root = config.get().root or targets.workspace_root()
        if not root then
            cb(nil, "no workspace root")
            return
        end
        local files = {}
        for _, l in ipairs(labels or {}) do
            local pkg, base = l:match("^//([^:]*):(.+)$")
            if base then
                local path = pkg == "" and (root .. "/" .. base) or (root .. "/" .. pkg .. "/" .. base)
                if vim.fn.filereadable(path) == 1 then
                    files[#files + 1] = path
                end
            end
        end
        cb(files, nil)
    end)
end

-- Cases across a target's sources (empty when none declare any).
function M.cases_for_target(target, cb)
    M.sources_for_target(target, function(files, err)
        if err then
            cb(nil, err)
            return
        end
        local out = {}
        for _, path in ipairs(files or {}) do
            local ok, lines = pcall(vim.fn.readfile, path)
            if ok then
                for _, c in ipairs(M.cases(lines)) do
                    out[#out + 1] = c
                end
            end
        end
        cb(out, nil)
    end)
end

-- Subtest picker for an explicit target. Uses pre-parsed cases when given,
-- otherwise resolves them from the target's own sources (no open buffer
-- needed).
function M.run_target_subtests(target, cases)
    if not target or target == "" then
        vim.notify("bazel-launcher: missing target", vim.log.levels.ERROR)
        return
    end
    local function open_picker(resolved)
        if not resolved or #resolved == 0 then
            vim.notify("bazel-launcher: no GoogleTest cases in " .. target, vim.log.levels.WARN)
            return
        end
        local items = { { label = "All tests (" .. #resolved .. ")", filter = nil } }
        for _, c in ipairs(resolved) do
            items[#items + 1] = {
                label = c.suite .. "." .. c.name,
                filter = c.suite .. "." .. c.name,
            }
        end
        pick(items, "GoogleTest (" .. target .. "):", function(choice)
            if not choice then
                return
            end
            local extra = choice.filter and { "--test_filter=" .. choice.filter } or nil
            require("bazel-launcher.launch").launch("test", target, extra)
        end)
    end
    if cases and #cases > 0 then
        open_picker(cases)
        return
    end
    M.cases_for_target(target, function(resolved, err)
        if err then
            vim.notify("bazel-launcher: sources query failed: " .. tostring(err), vim.log.levels.ERROR)
            return
        end
        open_picker(resolved)
    end)
end

function M.run_current_buffer()
    local cases = M.cases_in_buffer()
    if #cases == 0 then
        vim.notify("bazel-launcher: no GoogleTest TEST()/TEST_F() cases in buffer", vim.log.levels.WARN)
        return
    end
    M.owner_targets(function(labels, err)
        if err then
            vim.notify("bazel-launcher: owner query failed: " .. tostring(err), vim.log.levels.ERROR)
            return
        end
        if not labels or #labels == 0 then
            vim.notify("bazel-launcher: no owning cc_test target (check the BUILD file)", vim.log.levels.WARN)
            return
        end
        local function with_target(target)
            M.run_target_subtests(target, cases)
        end
        if #labels == 1 then
            with_target(labels[1])
            return
        end
        local items = {}
        for _, l in ipairs(labels) do
            items[#items + 1] = { label = l, target = l }
        end
        pick(items, "Owning test targets:", function(choice)
            if choice then
                with_target(choice.target)
            end
        end)
    end)
end

return M
