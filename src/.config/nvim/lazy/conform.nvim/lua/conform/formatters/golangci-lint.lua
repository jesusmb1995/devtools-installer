---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_golangci-lint.run/usage/configuration/#fmt",
    description = "Fast linters runner for Go (with formatter).",
  },
  command = "golangci-lint",
  args = { "fmt", "--stdin" },
}
