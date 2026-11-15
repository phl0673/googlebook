return {
  -- 1. Assure l'installation automatique via Mason
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "bash-language-server",
        "shellcheck",
        "shfmt",
      },
    },
  },
  -- 2. Active le serveur LSP bashls
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},
      },
    },
  },
  -- 3. Active le formatage automatique avec shfmt sur sh et zsh
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
        zsh = { "shfmt" },
      },
    },
  },
}
