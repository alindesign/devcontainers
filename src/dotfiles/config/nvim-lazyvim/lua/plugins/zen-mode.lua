return {
  {
    "folke/zen-mode.nvim",
    dependencies = { "folke/twilight.nvim" },
    cmd = "ZenMode",
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
    },
    opts = {
      window = {
        width = 120,
        options = {
          signcolumn = "no",
          number = false,
          relativenumber = false,
          cursorline = false,
          foldcolumn = "0",
        },
      },
      plugins = {
        twilight = { enabled = true },
        gitsigns = { enabled = false },
      },
    },
  },
  {
    "folke/twilight.nvim",
    cmd = "Twilight",
    opts = {},
  },
}
