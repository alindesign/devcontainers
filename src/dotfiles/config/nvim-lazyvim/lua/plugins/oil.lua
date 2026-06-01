return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open Parent Directory" },
    },
    opts = {
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        ["q"] = "actions.close",
        ["<C-s>"] = false, -- free up for save
        ["<C-h>"] = false, -- free up for window navigation
      },
      float = {
        padding = 4,
      },
    },
  },
}
