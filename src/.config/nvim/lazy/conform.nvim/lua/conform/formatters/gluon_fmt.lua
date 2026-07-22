---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/gluon-lang/gluon",
    description = "Code formatting for the gluon programming language.",
  },
  command = "gluon",
  args = { "fmt", "$FILENAME" },
  stdin = false,
}
