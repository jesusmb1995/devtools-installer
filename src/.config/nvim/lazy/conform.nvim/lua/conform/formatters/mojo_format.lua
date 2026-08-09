---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_docs.modular.com/mojo/cli/format",
    description = "Official Formatter for The Mojo Programming Language",
  },
  command = "mojo",
  args = { "format", "-q", "$FILENAME" },
  stdin = false,
}
