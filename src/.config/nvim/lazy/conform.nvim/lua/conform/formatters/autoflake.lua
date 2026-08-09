---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/PyCQA/autoflake",
    description = "Removes unused imports and unused variables as reported by pyflakes.",
  },
  command = "autoflake",
  args = { "--stdin-display-name", "$FILENAME", "-" },
}
