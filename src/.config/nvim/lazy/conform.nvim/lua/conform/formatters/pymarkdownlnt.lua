---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/jackdewinter/pymarkdown",
    description = "A markdown linter and formatter.",
  },
  command = "pymarkdownlnt",
  args = { "--return-code-scheme", "minimal", "fix", "$FILENAME" },
  stdin = false,
}
