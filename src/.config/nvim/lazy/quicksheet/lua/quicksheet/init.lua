--- quicksheet — entry point: setup(), get_cheats(), show(), edit(), update().
local M = {}

local config = require("quicksheet.config")
local parse = require("quicksheet.parse")

--- Apply user options over the defaults.
--- @param opts table|nil
function M.setup(opts)
  config.setup(opts)
end

local function sheet_path()
  return vim.fn.stdpath("config") .. "/quicksheet.txt"
end

--- Read quicksheet.txt and parse it into cheat entries.
--- @return table
function M.get_cheats()
  local path = sheet_path()
  local lines = {}
  local f = io.open(path, "r")
  if f then
    for line in f:lines() do
      lines[#lines + 1] = line
    end
    f:close()
  end
  return parse.parse_lines(lines)
end

--- Open the Telescope picker over the parsed cheats.
--- @param opts table|nil
function M.show(opts)
  require("quicksheet.telescope").pick(opts)
end

--- Open quicksheet.txt in a buffer for editing, optionally at a given line.
--- @param lineno number|nil 1-based line to jump to
function M.edit(lineno)
  local path = sheet_path()
  if lineno and lineno > 0 then
    vim.cmd("edit +" .. lineno .. " " .. vim.fn.fnameescape(path))
  else
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  end
end

--- QuickUpdate flow: gather -> filter_new -> build_append_block -> append -> notify.
function M.update()
  local update = require("quicksheet.update")
  local collect = config.options.collect
  local path = sheet_path()

  local existing = M.get_cheats()
  local candidates = update.gather(collect)
  local new = update.filter_new(existing, candidates, collect)
  local block = update.build_append_block(new, collect.section)

  if block == "" then
    vim.notify("[quicksheet] nothing to add")
    return
  end

  local f = io.open(path, "a")
  if f then
    f:write(block)
    f:close()
  end
  vim.notify(("[quicksheet] added %d entries"):format(#new))
end

return M
