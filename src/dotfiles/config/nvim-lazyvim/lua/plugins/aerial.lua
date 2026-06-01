return {
  -- Code outline sidebar
  {
    "stevearc/aerial.nvim",
    event = "LazyFile",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      backends = { "treesitter", "lsp", "markdown", "man" },
      layout = {
        min_width = 30,
        default_direction = "prefer_right",
      },
      show_guides = true,
      attach_mode = "global",
      filter_kind = false,
    },
    keys = {
      { "<leader>cs", "<cmd>AerialToggle<cr>", desc = "Code Outline (Aerial)" },
      { "<leader>cS", "<cmd>AerialNavToggle<cr>", desc = "Code Outline Nav" },
    },
  },
  -- Breadcrumbs in winbar
  {
    "utilyre/barbecue.nvim",
    event = "LazyFile",
    dependencies = {
      "SmiteshP/nvim-navic",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      attach_navic = false,
    },
  },
}
