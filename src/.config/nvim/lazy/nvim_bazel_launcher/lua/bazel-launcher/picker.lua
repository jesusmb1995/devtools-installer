local config = require("bazel-launcher.config")
local targets = require("bazel-launcher.targets")
local gtest = require("bazel-launcher.gtest")

local M = {}

-- Full target label as written in BUILD files, docs or shell commands.
local LABEL_PATTERN = "//[A-Za-z0-9_/.+@~-]*:[A-Za-z0-9_/.+@~-]+"
local NAME_RULE_DQ = 'name%s*=%s*"([A-Za-z0-9_/.+@~-]+)"'
local NAME_RULE_SQ = "name%s*=%s*'([A-Za-z0-9_/.+@~-]+)'"

-- Prompt text to pre-type for one buffer line and the cursor's 1-based
-- byte column on it:
--   a. the full label whose byte range contains the cursor; a lone label
--      on the line counts even with the cursor beside it (hovering is
--      fuzzy)
--   b. a `name = "x"` rule anywhere on the line, package-qualified when
--      `pkg` is known, bare otherwise
--   c. nil
function M.default_text_for(line, col, pkg)
    local labels = {}
    local init = 1
    while true do
        local s, e = string.find(line, LABEL_PATTERN, init)
        if not s then
            break
        end
        labels[#labels + 1] = { text = line:sub(s, e), from = s, to = e }
        init = e + 1
    end
    if #labels > 0 then
        for _, m in ipairs(labels) do
            if col >= m.from and col <= m.to then
                return m.text
            end
        end
        if #labels == 1 then
            return labels[1].text
        end
    end
    local name = string.match(line, NAME_RULE_DQ) or string.match(line, NAME_RULE_SQ)
    if name then
        if pkg and pkg ~= "" then
            return pkg .. ":" .. name
        end
        return name
    end
    return nil
end

function M.open(opts)
    local ok, telescope = pcall(require, "telescope")
    if not ok then
        vim.notify("bazel-launcher: telescope.nvim required", vim.log.levels.ERROR)
        return
    end
    opts = opts or {}
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    -- telescope's main module does NOT export .themes in all versions;
    -- the theme module is require("telescope.themes").
    local theme = require("telescope.themes").get_dropdown()
    theme = vim.tbl_deep_extend("force", theme, config.get().picker.theme_opts or {})

    -- Scope the listing to the current file's package when detectable;
    -- opts.package forces it, and an explicit opts.query wins over the
    -- package override.
    local pkg = opts.package or targets.package_for()
    local use_pkg = pkg and not opts.query

    -- GoogleTest cases of the buffer under the cursor at open time, for the
    -- C-s subtest binding below (only meaningful with a test file open).
    local buf_cases = {}
    do
        local okb, bbuf = pcall(vim.api.nvim_get_current_buf)
        if okb and bbuf then
            local okc, found = pcall(gtest.cases_in_buffer, bbuf)
            if okc and type(found) == "table" then
                buf_cases = found
            end
        end
    end

    -- Pre-fill the prompt with the target under the cursor, derived BEFORE
    -- the async query starts. refresh() re-opens through here and simply
    -- re-derives from wherever the cursor sits by then.
    local default_text
    if targets.current_file() then
        local okc, cursor = pcall(vim.api.nvim_win_get_cursor, 0)
        if okc and cursor then
            -- win_get_cursor columns are 0-based; label byte ranges above
            -- are 1-based.
            default_text = M.default_text_for(vim.api.nvim_get_current_line(), cursor[2] + 1, pkg)
        end
    end

    -- Subtest rows for the open test file's owning targets, prepended ahead
    -- of the plain target list. Resolved before fetch() so the picker shows
    -- the full picture at once (owner query is cached, usually instant).
    local function with_subtests(open_picker)
        if #buf_cases == 0 then
            open_picker(nil)
            return
        end
        gtest.owner_targets(function(labels, err)
            if err then
                vim.notify("bazel-launcher: owner query failed: " .. tostring(err), vim.log.levels.WARN)
            end
            local rows = {}
            for _, target in ipairs(labels or {}) do
                if target:match("_test") ~= nil then
                    for _, c in ipairs(buf_cases) do
                        local display = target .. " :: " .. c.suite .. "." .. c.name
                        rows[#rows + 1] = {
                            target = target,
                            filter = c.suite .. "." .. c.name,
                            display = display,
                        }
                    end
                end
            end
            open_picker(rows)
        end)
    end

    local function show(labels, subtest_rows)
        -- default_text prefills the prompt box, but telescope's prefill path
        -- (Picker:find -> set_prompt -> reset_prompt) only writes the buffer
        -- text — the sorter never runs, so the list below stays UNFILTERED
        -- and the first highlighted entry is just the alphabetically-first
        -- label. Enter would launch that instead of the hovered target.
        -- Hoist the prefilled target to rank 1 so the initial highlight (and
        -- plain Enter) is exactly it; typing further filters as usual.
        if default_text and default_text ~= "" then
            local suffix = ":" .. default_text
            for i, label in ipairs(labels) do
                if type(label) == "string"
                    and (label == default_text or label:sub(-#suffix) == suffix) then
                    table.remove(labels, i)
                    table.insert(labels, 1, label)
                    break
                end
            end
        end
        local results = {}
        for _, row in ipairs(subtest_rows or {}) do
            results[#results + 1] = row
        end
        for _, label in ipairs(labels) do
            results[#results + 1] = label
        end
        local picker_opts = vim.tbl_deep_extend("force", theme, {
            prompt_title = (pkg and ("Bazel Targets (" .. pkg .. ")") or "Bazel Targets") .. " [C-s subtests]",
            default_text = default_text,
            finder = require("telescope.finders").new_table({
                results = results,
                entry_maker = function(item)
                    if type(item) == "table" then
                        return { value = item, display = item.display, ordinal = item.display }
                    end
                    return { value = item, display = item, ordinal = item }
                end,
            }),
            sorter = require("telescope.sorters").get_generic_fuzzy_sorter(),
            attach_mappings = function(prompt_bufnr, map)
                local function is_test_target(label)
                    return type(label) == "string" and label:match("_test") ~= nil
                end
                -- Split a selection into target + optional test filter.
                -- Subtest rows carry { target, filter }; plain rows are bare
                -- label strings.
                local function selected_target_filter()
                    local selection = action_state.get_selected_entry()
                    if not (selection and selection.value) then
                        return nil, nil
                    end
                    if type(selection.value) == "table" then
                        return selection.value.target, selection.value.filter
                    end
                    return selection.value, nil
                end
                local function filter_args(filter)
                    return filter and { "--test_filter=" .. filter } or nil
                end
                local function dispatch(launch_type, keep_filter)
                    -- Read the selection BEFORE closing: close tears down the
                    -- picker state on some telescope versions, and Enter must
                    -- launch exactly the highlighted row. Forced run drops
                    -- the filter (runs the binary as-is).
                    local target, filter = selected_target_filter()
                    actions.close(prompt_bufnr)
                    if target then
                        if keep_filter == false then
                            filter = nil
                        end
                        require("bazel-launcher.launch").launch(launch_type, target, filter_args(filter))
                    end
                end
                local function dispatch_heuristic()
                    local target, filter = selected_target_filter()
                    actions.close(prompt_bufnr)
                    if target then
                        local lt = (filter or is_test_target(target)) and "test" or "run"
                        require("bazel-launcher.launch").launch(lt, target, filter_args(filter))
                    end
                end
                local function dispatch_subtests()
                    local selection = action_state.get_selected_entry()
                    if not (selection and selection.value) then
                        return
                    end
                    local target = selection.value
                    if type(target) == "table" then
                        target = target.target
                    end
                    if not is_test_target(target) then
                        vim.notify("bazel-launcher: C-s needs a test target", vim.log.levels.WARN)
                        return
                    end
                    actions.close(prompt_bufnr)
                    gtest.run_target_subtests(target, buf_cases)
                end
                local function refresh()
                    actions.close(prompt_bufnr)
                    targets.clear_cache()
                    M.open()
                end
                map("i", "<CR>", function()
                    dispatch_heuristic()
                end)
                map("n", "<CR>", function()
                    dispatch_heuristic()
                end)
                map("i", "<C-d>", function()
                    dispatch("build")
                end)
                map("n", "<C-d>", function()
                    dispatch("build")
                end)
                map("i", "<C-t>", function()
                    dispatch("test")
                end)
                map("n", "<C-t>", function()
                    dispatch("test")
                end)
                map("i", "<C-g>", function()
                    dispatch("run", false)
                end)
                map("n", "<C-g>", function()
                    dispatch("run", false)
                end)
                map("i", "<C-r>", refresh)
                map("n", "<C-r>", refresh)
                map("i", "<C-s>", dispatch_subtests)
                map("n", "<C-s>", dispatch_subtests)
                actions.select_default:replace(function()
                    dispatch_heuristic()
                end)
                return true
            end,
        })
        require("telescope.pickers").new({}, picker_opts):find()
    end

    local function fetch(list_opts, scoped_pkg, subtest_rows)
        targets.list(list_opts, function(labels, err)
            -- A package-scoped listing that errors or comes back empty
            -- retries exactly once with the workspace-wide query; pkg is
            -- cleared so the picker shown stays global. Past that the
            -- normal error/empty handling applies.
            if scoped_pkg and (not labels or #labels == 0) then
                pkg = nil
                vim.notify(
                    "bazel-launcher: no targets in " .. scoped_pkg .. ", showing workspace targets",
                    vim.log.levels.WARN
                )
                fetch(opts, nil, subtest_rows)
                return
            end
            if not labels then
                vim.notify("bazel-launcher: target query failed: " .. tostring(err), vim.log.levels.ERROR)
                return
            end
            if #labels == 0 then
                vim.notify("bazel-launcher: no targets found in workspace", vim.log.levels.WARN)
            end
            show(labels, subtest_rows)
        end)
    end

    local fetch_opts, fetch_pkg = opts, nil
    if use_pkg then
        fetch_opts = vim.tbl_extend("force", opts, {
            query = { "query", pkg == "//" and "//*" or (pkg .. ":*") },
        })
        fetch_pkg = pkg
    end
    with_subtests(function(subtest_rows)
        fetch(fetch_opts, fetch_pkg, subtest_rows)
    end)
end

return M
