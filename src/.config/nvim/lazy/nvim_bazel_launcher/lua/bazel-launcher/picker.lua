local config = require("bazel-launcher.config")
local targets = require("bazel-launcher.targets")

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

    local function show(labels)
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
                if label == default_text or label:sub(-#suffix) == suffix then
                    table.remove(labels, i)
                    table.insert(labels, 1, label)
                    break
                end
            end
        end
        local picker_opts = vim.tbl_deep_extend("force", theme, {
            prompt_title = pkg and ("Bazel Targets (" .. pkg .. ")") or "Bazel Targets",
            default_text = default_text,
            finder = require("telescope.finders").new_table({
                results = labels,
                entry_maker = function(label)
                    return { value = label, display = label, ordinal = label }
                end,
            }),
            sorter = require("telescope.sorters").get_generic_fuzzy_sorter(),
            attach_mappings = function(prompt_bufnr, map)
                local function is_test_target(label)
                    return label:match("_test") ~= nil
                end
                local function dispatch(launch_type)
                    -- Read the selection BEFORE closing: close tears down the
                    -- picker state on some telescope versions, and Enter must
                    -- launch exactly the highlighted row.
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    if selection and selection.value then
                        require("bazel-launcher.launch").launch(launch_type, selection.value)
                    end
                end
                local function dispatch_heuristic()
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    if selection and selection.value then
                        local lt = is_test_target(selection.value) and "test" or "run"
                        require("bazel-launcher.launch").launch(lt, selection.value)
                    end
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
                    dispatch("run")
                end)
                map("n", "<C-g>", function()
                    dispatch("run")
                end)
                map("i", "<C-r>", refresh)
                map("n", "<C-r>", refresh)
                actions.select_default:replace(function()
                    dispatch_heuristic()
                end)
                return true
            end,
        })
        require("telescope.pickers").new({}, picker_opts):find()
    end

    local function fetch(list_opts, scoped_pkg)
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
                fetch(opts, nil)
                return
            end
            if not labels then
                vim.notify("bazel-launcher: target query failed: " .. tostring(err), vim.log.levels.ERROR)
                return
            end
            if #labels == 0 then
                vim.notify("bazel-launcher: no targets found in workspace", vim.log.levels.WARN)
            end
            show(labels)
        end)
    end

    if use_pkg then
        fetch(vim.tbl_extend("force", opts, {
            query = { "query", pkg == "//" and "//*" or (pkg .. ":*") },
        }), pkg)
    else
        fetch(opts, nil)
    end
end

return M
