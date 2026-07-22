local util = require("conform.util")
---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/hadialqattan/pycln",
    description = "A Python formatter for finding and removing unused import statements.",
  },
  command = "pycln",
  args = {
    "--silence",
    "-",
  },
  cwd = util.root_file({
    "pyproject.toml",
    "setup.cfg",
  }),
}
