---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/scalameta/scalafmt",
    description = "Code formatter for Scala.",
  },
  command = "scalafmt",
  args = { "--stdin" },
}
