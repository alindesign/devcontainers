return {
  {
    "ThePrimeagen/refactoring.nvim",
    keys = {
      -- Disable default <leader>r* mappings (conflicts with HTTP requests group)
      { "<leader>rs", false, mode = { "n", "v" } },
      { "<leader>rd", false },
      { "<leader>re", false, mode = "v" },
      { "<leader>rf", false, mode = "v" },
      { "<leader>rv", false, mode = "v" },
      { "<leader>rI", false, mode = "v" },
      { "<leader>ri", false, mode = "v" },
      { "<leader>rb", false },
      { "<leader>rbf", false },
      -- Remapped under code group (<leader>c*)
      {
        "<leader>cR",
        function() require("refactoring").select_refactor() end,
        mode = { "n", "v" },
        desc = "Refactor Menu",
      },
      {
        "<leader>ce",
        function() require("refactoring").refactor("Extract Function") end,
        mode = "v",
        desc = "Extract Function",
      },
      {
        "<leader>cv",
        function() require("refactoring").refactor("Extract Variable") end,
        mode = "v",
        desc = "Extract Variable",
      },
      {
        "<leader>ci",
        function() require("refactoring").refactor("Inline Variable") end,
        mode = { "n", "v" },
        desc = "Inline Variable",
      },
    },
  },
}
