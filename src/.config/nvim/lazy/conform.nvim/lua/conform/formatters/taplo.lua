---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/tamasfe/taplo",
    description = "A TOML toolkit written in Rust.",
  },
  command = "taplo",
  args = { "format", "--stdin-filepath", "$FILENAME", "-" },
}
