---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/FlamingTempura/bibtex-tidy",
    description = "Cleaner and Formatter for BibTeX files.",
  },
  command = "bibtex-tidy",
  stdin = true,
  args = { "--quiet" },
}
