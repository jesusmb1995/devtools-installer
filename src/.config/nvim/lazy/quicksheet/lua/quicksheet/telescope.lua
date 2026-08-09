--- quicksheet.telescope — Telescope picker + actions.
-- The module is guarded so it only fails at runtime if telescope is missing:
-- all `require("telescope.*")` calls happen inside functions, not at load time.
local M = {}

M.actions = {}

--- Entry maker: shows section | description | code.
local function make_entry(entry)
  return {
    value = entry,
    display = entry.section .. " | " .. entry.description .. " | " .. entry.code,
    ordinal = entry.section .. " " .. entry.description .. " " .. entry.code,
    description = entry.description,
    code = entry.code,
    section = entry.section,
    lineno = entry.lineno,
  }
end

--- Action: fill the command line with a `:command` entry WITHOUT executing it.
--- Non-command entries just notify.
function M.actions.select_or_fill(prompt_bufnr)
  local action_state = require("telescope.actions.state")
  local actions = require("telescope.actions")
  local entry = action_state.get_selected_entry()
  if not entry then
    return
  end
  local code = entry.code
  if code:sub(1, 1) == ":" then
    actions.close(prompt_bufnr)
    local cmd = code
    local stop = cmd:find("[%[{]")
    if stop then
      cmd = cmd:sub(1, stop - 1)
    end
    vim.api.nvim_feedkeys(cmd, "n", false)
  else
    vim.notify("[quicksheet] this entry is not a runnable command")
  end
end

--- Action: yank the entry code into register 0.
function M.actions.yank(prompt_bufnr)
  local action_state = require("telescope.actions.state")
  local entry = action_state.get_selected_entry()
  if not entry then
    return
  end
  vim.fn.setreg("0", entry.code)
  vim.notify("[quicksheet] yanked: " .. entry.code)
end

--- Action: close the picker and open quicksheet.txt at the entry's line.
function M.actions.edit(prompt_bufnr)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local entry = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  require("quicksheet").edit(entry and entry.lineno)
end

--- Action: close the picker and execute the entry (run a `:command` or feed a key).
function M.actions.select_or_execute(prompt_bufnr)
  local action_state = require("telescope.actions.state")
  local actions = require("telescope.actions")
  local entry = action_state.get_selected_entry()
  if not entry then
    return
  end
  actions.close(prompt_bufnr)
  local code = entry.code
  if code:sub(1, 1) == ":" then
    vim.api.nvim_feedkeys(code .. "\n", "n", false)
  else
    vim.api.nvim_feedkeys(code, "n", false)
  end
end

--- Open a Telescope picker over the quicksheet cheats.
--- @param opts table|nil
function M.pick(opts)
  opts = type(opts) == "table" and opts or {}
  local config = require("quicksheet.config")
  local cheats = require("quicksheet").get_cheats()

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  pickers
    .new(opts, {
      prompt_title = "QuickSheet",
      finder = finders.new_table({
        results = cheats,
        entry_maker = make_entry,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        for key, action_name in pairs(config.options.telescope_mappings or {}) do
          local fn = M.actions[action_name]
          if fn then
            map("i", key, function()
              fn(prompt_bufnr)
            end)
          end
        end
        return true
      end,
    })
    :find()
end

return M
