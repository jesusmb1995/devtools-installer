local util = require("conform.util")
---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/BlankSpruce/gersemi",
    description = "A formatter to make your CMake code the real treasure.",
  },
  command = "gersemi",
  args = { "--quiet", "-" },
  cwd = util.root_file({ ".gersemirc" }),
}
