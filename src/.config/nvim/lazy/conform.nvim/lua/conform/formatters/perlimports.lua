---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/perl-ide/App-perlimports",
    description = "Make implicit Perl imports explicit.",
  },
  command = "perlimports",
  args = {
    "--read-stdin",
    "--filename",
    "$FILENAME",
  },
}
