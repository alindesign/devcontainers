return {
  -- Modify Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      -- Add nvim-ts-autotag
      { "windwp/nvim-ts-autotag" },
    },
    event = { "BufReadPre" },
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "angular",
        "bash",
        "css",
        "csv",
        "dockerfile",
        "go",
        "gomod",
        "gowork",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "rust",
        "scss",
        "terraform",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      })
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
}
