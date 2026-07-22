---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/rvben/rumdl",
    description = "Markdown Linter and Formatter written in Rust.",
  },
  command = "rumdl",
  args = { "fmt", "-" },
  stdin = true,
}
