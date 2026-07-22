---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/thlorenz/doctoc",
    description = "Generates table of contents for markdown files inside local git repository.",
  },
  command = "doctoc",
  stdin = false,
  args = {
    "$FILENAME",
  },
}
