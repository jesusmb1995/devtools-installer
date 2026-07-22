local options = {
  formatters_by_ft = {

    lua = { "stylua" },


    css = { "prettier" },


    html = { "prettier" },


    javascript = { "standardjs", "biome" },



    python = { "black" },



    cpp = { "clang-format" },
    c = { "clang-format" },


    yaml = { "yamlfmt" },


    json = { "prettier" },


    jsonnet = { "jsonnetfmt" },


    markdown = { "prettier" },


    cmake = { "cmakelang" },


    bash = { "beautysh" },


    zsh = { "beautysh" },

  },


  -- format_on_save = {
  --   -- These options will be passed to conform.format()
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

return options
