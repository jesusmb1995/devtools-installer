local util = require("conform.util")
---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/savonet/liquidsoap-prettier",
    description = "A binary to format Liquidsoap scripts",
  },
  command = util.from_node_modules("liquidsoap-prettier"),
  args = { "-w", "$FILENAME" },
  stdin = false,
}
