---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_ghdl.github.io/ghdl/",
    description = "Open-source analyzer, compiler, simulator and synthesizer for VHDL.",
  },
  command = "ghdl",
  args = { "fmt", "--std=08", "$FILENAME" },
}
