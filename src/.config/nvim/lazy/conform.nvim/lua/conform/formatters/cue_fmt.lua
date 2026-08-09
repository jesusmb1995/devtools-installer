---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_cuelang.org",
    description = "Format CUE files using `cue fmt` command.",
  },
  command = "cue",
  args = { "fmt", "-" },
  stdin = true,
}
