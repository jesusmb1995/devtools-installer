---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/greglook/cljstyle",
    description = "Formatter for Clojure code.",
  },
  command = "cljstyle",
  args = { "pipe" },
  cwd = require("conform.util").root_file({ ".cljstyle" }),
}
