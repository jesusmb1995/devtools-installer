---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/stedolan/jq",
    description = "Command-line JSON processor.",
  },
  command = "jq",
  args = function(_, ctx)
    return { "--indent", math.max(-1, math.min(7, ctx.shiftwidth)) }
  end,
}
