---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/protocolbuffers/txtpbfmt",
    description = "txtpbfmt parses, edits and formats text proto files in a way that preserves comments.",
  },
  command = "txtpbfmt",
  args = { "-stdin_display_path", "$FILENAME" },
}
