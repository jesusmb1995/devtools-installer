--- quicksheet.config — defaults table + deep-merge into config.options.
local M = {}

M.defaults = {
  auto_mapping = true,
  default_mapping = "<leader>?",
  collect = {
    modes = { "n", "i", "v", "x" },
    skip_lhs_prefixes = { "<Plug>", "<SNR>" },
    skip_patterns = {},
    section = "QuickUpdate",
  },
  telescope_mappings = {
    ["<CR>"] = "select_or_fill",
    ["<C-y>"] = "yank",
    ["<C-e>"] = "edit",
  },
}

M.options = {}

--- Deep-merge `opts` over the defaults, storing the result in M.options.
--- Partial overrides never wipe siblings.
--- @param opts table|nil
--- @return nil
function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)
end

-- Ensure M.options always exists, even before the user calls setup().
M.setup()

return M
