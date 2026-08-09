function GET_INIT_CONFIG()
  local _languages = require "languages"
  if vim.env.NVIM_MINIMAL == nil then
    return {
      {
        "stevearc/conform.nvim",
        opts = require "configs.conform",
      },

      {
        "neovim/nvim-lspconfig",
        config = function()
          require "configs.lspconfig"
        end,
      },


      -- Prefetch mode: nvim 12+ ships its own highlight queries;
      -- no nvim-treesitter plugin needed. Parsers are compiled at
      -- runtime from vendored grammar source (configs/treesitter_bootstrap).
      -- enabled=false overrides NvChad's own spec that pulls it in.
      { "nvim-treesitter/nvim-treesitter", enabled = false },





    }
  else
    return {
      {
        "stevearc/conform.nvim",
        enabled = false,
      },

      {
        "neovim/nvim-lspconfig",
        enabled = false,
      },

      {
        "nvim-treesitter/nvim-treesitter",
        enabled = false,
      },
    }
  end
end

return GET_INIT_CONFIG()
