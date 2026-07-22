---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/mikefarah/yq",
    description = "YAML/JSON processor",
  },
  command = "yq",
  args = { "-P", "-" },
  stdin = true,
}
