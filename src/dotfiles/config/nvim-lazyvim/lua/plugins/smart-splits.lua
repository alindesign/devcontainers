return {
  {
    "mrjones2014/smart-splits.nvim",
    event = "VeryLazy",
    keys = {
      -- Resize with Ctrl+Arrow
      { "<C-Up>", function() require("smart-splits").resize_up() end, desc = "Resize Up" },
      { "<C-Down>", function() require("smart-splits").resize_down() end, desc = "Resize Down" },
      { "<C-Left>", function() require("smart-splits").resize_left() end, desc = "Resize Left" },
      { "<C-Right>", function() require("smart-splits").resize_right() end, desc = "Resize Right" },
      -- Swap windows with <leader>w + hjkl
      { "<leader>wh", function() require("smart-splits").swap_buf_left() end, desc = "Swap Left" },
      { "<leader>wj", function() require("smart-splits").swap_buf_down() end, desc = "Swap Down" },
      { "<leader>wk", function() require("smart-splits").swap_buf_up() end, desc = "Swap Up" },
      { "<leader>wl", function() require("smart-splits").swap_buf_right() end, desc = "Swap Right" },
    },
    opts = {
      ignored_buftypes = { "nofile", "quickfix", "prompt" },
      ignored_filetypes = { "NvimTree", "neo-tree", "snacks_dashboard" },
    },
  },
}
