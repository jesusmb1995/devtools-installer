---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_hackage.haskell.org/package/fourmolu",
    description = "A fork of ormolu that uses four space indentation and allows arbitrary configuration.",
  },
  command = "fourmolu",
  args = { "--stdin-input-file", "$FILENAME" },
  stdin = true,
}
