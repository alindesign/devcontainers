return {
  {
    "uga-rosa/ccc.nvim",
    cmd = { "CccPick", "CccConvert", "CccHighlighterToggle" },
    keys = {
      { "<leader>uC", "<cmd>CccPick<cr>", desc = "Color Picker" },
    },
    opts = {
      highlighter = {
        auto_enable = false, -- mini-hipatterns handles color highlighting
        lsp = true,
      },
    },
  },
}
