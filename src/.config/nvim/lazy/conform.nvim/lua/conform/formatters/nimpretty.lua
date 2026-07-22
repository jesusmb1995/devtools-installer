---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/nim-lang/nim",
    description = "nimpretty is a Nim source code beautifier that follows the official style guide.",
  },
  command = "nimpretty",
  args = { "$FILENAME" },
  stdin = false,
}
