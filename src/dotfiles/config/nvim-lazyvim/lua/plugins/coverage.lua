return {
  {
    "andythigpen/nvim-coverage",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "Coverage", "CoverageSummary", "CoverageToggle", "CoverageLoad" },
    keys = {
      { "<leader>tc", "<cmd>CoverageToggle<cr>", desc = "Toggle Coverage" },
      { "<leader>tC", "<cmd>CoverageSummary<cr>", desc = "Coverage Summary" },
    },
    opts = {
      auto_reload = true,
    },
  },
}
