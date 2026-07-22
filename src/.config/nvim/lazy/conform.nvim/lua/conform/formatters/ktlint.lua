---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_ktlint.github.io/",
    description = "An anti-bikeshedding Kotlin linter with built-in formatter.",
  },
  command = "ktlint",
  args = { "--format", "--stdin", "--log-level=none" },
}
