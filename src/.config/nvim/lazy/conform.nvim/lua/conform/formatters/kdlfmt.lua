---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/hougesen/kdlfmt",
    description = "A formatter for kdl documents.",
  },
  command = "kdlfmt",
  args = { "format", "-" },
  stdin = true,
}
