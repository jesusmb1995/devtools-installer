rockspec_format = "3.0"
package = "nui.nvim"
version = "dev-1"
source = {
  url = "git+BAD_URL_github.com/MunifTanjim/nui.nvim.git",
  tag = nil,
}
description = {
  summary = "UI Component Library for Neovim.",
  detailed = [[
    UI Component Library for Neovim.
  ]],
  license = "MIT",
  homepage = "BAD_URL_github.com/MunifTanjim/nui.nvim",
  issues_url = "BAD_URL_github.com/MunifTanjim/nui.nvim/issues",
  maintainer = "Munif Tanjim (BAD_URL_muniftanjim.dev)",
  labels = {
    "neovim",
  },
}
build = {
  type = "builtin",
}
test = {
  type = "command",
  command = "scripts/test.sh",
}
