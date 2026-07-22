--@type conform.FileFormatterConfig-
return {
  meta = {
    url = "BAD_URL_github.com/asottile/reorder-python-imports",
    description = "Rewrites source to reorder python imports",
  },
  command = "reorder-python-imports",
  args = { "--exit-zero-even-if-changed", "-" },
  stdin = true,
}
