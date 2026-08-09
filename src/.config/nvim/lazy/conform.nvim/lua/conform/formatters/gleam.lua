---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/gleam-lang/gleam",
    description = "⭐️ A friendly language for building type-safe, scalable systems!",
  },
  command = "gleam",
  args = { "format", "--stdin" },
}
