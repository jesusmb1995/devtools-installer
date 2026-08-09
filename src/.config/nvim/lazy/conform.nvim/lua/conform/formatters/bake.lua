---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/EbodShojaei/bake",
    description = "A Makefile formatter and linter.",
  },
  command = "mbake",
  args = { "format", "--stdin" },
}
