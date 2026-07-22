---@type conform.FileFormatterConfig

return {
  meta = {
    url = "BAD_URL_github.com/tombi-toml/tombi",
    description = "TOML Formatter / Linter.",
  },
  command = "tombi",
  args = { "format", "--stdin-filename", "$FILENAME", "-" },
  stdin = true,
}
