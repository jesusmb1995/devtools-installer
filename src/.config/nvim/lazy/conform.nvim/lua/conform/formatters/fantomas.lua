---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/fsprojects/fantomas",
    description = "F# source code formatter.",
  },
  command = "fantomas",
  args = { "$FILENAME" },
  stdin = false,
}
