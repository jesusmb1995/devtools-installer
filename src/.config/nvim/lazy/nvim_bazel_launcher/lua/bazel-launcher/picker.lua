local config = require("bazel-launcher.config")
local targets = require("bazel-launcher.targets")

local M = {}

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
    targets.list(opts, function(labels, err)
        if not labels then
            vim.notify("bazel-launcher: target query failed: " .. tostring(err), vim.log.levels.ERROR)
            return
        end
        if #labels == 0 then
            vim.notify("bazel-launcher: no targets found in workspace", vim.log.levels.WARN)
        end
        local picker_opts = vim.tbl_deep_extend("force", theme, {
            prompt_title = "Bazel Targets",
            finder = require("telescope.finders").new_table({
                results = labels,
                entry_maker = function(label)
                    return { value = label, display = label, ordinal = label }
                end,
            }),
            sorter = require("telescope.sorters").get_generic_fuzzy_sorter(),
            attach_mappings = function(prompt_bufnr, map)
                local function dispatch(launch_type)
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    if selection and selection.value then
                        require("bazel-launcher.launch").launch(launch_type, selection.value)
                    end
                end
                local function refresh()
                    actions.close(prompt_bufnr)
                    targets.clear_cache()
                    M.open()
                end
                map("i", "<CR>", function()
                    dispatch("run")
                end)
                map("n", "<CR>", function()
                    dispatch("run")
                end)
                map("i", "<C-d>", function()
                    dispatch("build")
                end)
                map("n", "<C-d>", function()
                    dispatch("build")
                end)
                map("i", "<C-r>", refresh)
                map("n", "<C-r>", refresh)
                actions.select_default:replace(function()
                    dispatch("run")
                end)
                return true
            end,
        })
        require("telescope.pickers").new({}, picker_opts):find()
    end)
end

return M
