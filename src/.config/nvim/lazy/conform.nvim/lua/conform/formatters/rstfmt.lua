---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/dzhu/rstfmt",
    description = "A formatter for reStructuredText.",
  },
  command = "rstfmt",
  args = { "$FILENAME" },
  stdin = false,
}
