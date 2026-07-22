---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/nushell/nufmt",
    description = "The nushell formatter.",
  },
  command = "nufmt",
  args = { "$FILENAME" },
  stdin = false,
}
