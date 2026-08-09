---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/natefaubion/purescript-tidy",
    description = "A syntax tidy-upper for PureScript.",
  },
  command = "purs-tidy",
  args = { "format" },
  stdin = true,
}
