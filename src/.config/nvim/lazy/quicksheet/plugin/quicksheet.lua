--- quicksheet runtime plugin: user commands, default mapping, highlights.
local quicksheet = require("quicksheet")
local config = require("quicksheet.config")

vim.api.nvim_create_user_command("QuickSheet", function(opts)
  quicksheet.show(opts.args)
end, { desc = "Open the quicksheet Telescope picker", nargs = "*" })

vim.api.nvim_create_user_command("QuickEdit", function()
  quicksheet.edit()
end, { desc = "Edit quicksheet.txt" })

vim.api.nvim_create_user_command("QuickUpdate", function()
  quicksheet.update()
end, { desc = "Append newly discovered keymaps/commands to quicksheet" })

-- Default highlight links.
local function link(name, target)
  vim.api.nvim_set_hl(0, name, { default = true, link = target })
end
link("quickDescription", "String")
link("quickCode", "Statement")
link("quickSection", "Structure")
link("quickSeparator", "Keyword")

-- Optional default mapping <leader>? -> :QuickSheet, only if the key is free.
if config.options.auto_mapping then
  local key = config.options.default_mapping
  local free = true
  for _, mapping in ipairs(vim.api.nvim_get_keymap("n")) do
    if mapping.lhs == key then
      free = false
      break
    end
  end
  if free then
    vim.keymap.set("n", key, "<Cmd>QuickSheet<CR>", { desc = "QuickSheet" })
  end
end
