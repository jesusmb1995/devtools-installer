---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_gn.googlesource.com/gn/",
    description = "gn build system.",
  },
  command = "gn",
  args = { "format", "--stdin" },
}
