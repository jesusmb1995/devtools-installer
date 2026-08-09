---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/mihaimaruseac/hindent",
    description = "Haskell pretty printer.",
  },
  command = "hindent",
  args = { "$FILENAME" },
  stdin = false,
}
