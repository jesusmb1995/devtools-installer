---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/chipsalliance/verible/blob/master/verilog/tools/formatter/README.md",
    description = "The SystemVerilog formatter.",
  },
  command = "verible-verilog-format",
  args = { "--stdin_name", "$FILENAME", "-" },
}
