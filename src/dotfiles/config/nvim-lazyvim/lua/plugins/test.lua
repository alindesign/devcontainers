return {
  { "nvim-neotest/neotest-jest" },
  { "fredrikaverpil/neotest-golang" },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-jest",
      "fredrikaverpil/neotest-golang",
    },
    opts = {
      adapters = {
        ["neotest-jest"] = {
          jestCommand = "npx jest",
          cwd = function()
            return vim.fn.getcwd()
          end,
        },
        ["neotest-golang"] = {},
      },
    },
  },
}
