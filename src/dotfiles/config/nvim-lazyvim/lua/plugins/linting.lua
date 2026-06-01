return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Go
        "gopls",
        "goimports",
        "gofumpt",
        "golangci-lint",
        -- TypeScript / Web
        "vtsls",
        "angular-language-server",
        "prettier",
        "biome",
        "eslint-lsp",
        "tailwindcss-language-server",
        "html-lsp",
        "json-lsp",
        -- Docker
        "dockerfile-language-server",
        "docker-compose-language-service",
        "hadolint",
        -- Terraform
        "terraform-ls",
        "tflint",
        -- CSS
        "css-lsp",
        -- Shell
        "shellcheck",
        "shfmt",
        -- Python
        "pyright",
        "ruff",
        -- Lua (neovim config)
        "lua-language-server",
        "stylua",
        -- Markdown
        "marksman",
        "markdownlint-cli2",
        -- Emmet
        "emmet-language-server",
        -- Go tools
        "gomodifytags",
        "impl",
        -- Other
        "yaml-language-server",
        "taplo",
      },
    },
  },
  -- Linting
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        dockerfile = { "hadolint" },
      },
    },
  },
}
