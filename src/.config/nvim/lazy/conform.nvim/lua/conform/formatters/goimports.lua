---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_pkg.go.dev/golang.org/x/tools/cmd/goimports",
    description = "Updates your Go import lines, adding missing ones and removing unreferenced ones.",
  },
  command = "goimports",
  args = { "-srcdir", "$DIRNAME" },
}
