local M = {}

M.enabled_tools = {
}

M.tool_info = {
}

function M.get_installed_enabled_tools()
  local installed = {}
  for _, tool_key in ipairs(M.enabled_tools) do
    local info = M.tool_info[tool_key]
    if info and vim.fn.executable(info.cmd) == 1 then
      table.insert(installed, info)
    end
  end
  return installed
end

function M.get_enabled_tools()
  local tools = {}
  for _, tool_key in ipairs(M.enabled_tools) do
    local info = M.tool_info[tool_key]
    if info then
      table.insert(tools, info)
    end
  end
  return tools
end

-- Default agent CLI tool = highest-priority ENABLED tool, decided directly
-- here (config priority) so the agent terminal works before :AiSelect or kv
-- have been used. Reorder these branches to change the default.
M.default_tool = nil

return M
