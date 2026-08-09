---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_www.gnu.org/software/gawk/manual/gawk.html",
    description = "Format awk programs with gawk.",
  },
  command = "gawk",
  args = { "-f", "-", "-o-" },
}
