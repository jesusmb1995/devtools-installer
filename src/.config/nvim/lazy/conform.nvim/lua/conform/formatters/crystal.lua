---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_crystal-lang.org/",
    description = "Format Crystal code.",
  },
  command = "crystal",
  args = { "tool", "format", "-" },
  stdin = true,
}
