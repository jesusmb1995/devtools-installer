---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_hackage.haskell.org/package/ormolu",
    description = "A formatter for Haskell source code.",
  },
  command = "ormolu",
  args = { "--stdin-input-file", "$FILENAME" },
  stdin = true,
}
