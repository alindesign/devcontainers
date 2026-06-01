return {
  {
    "mistweaverco/kulala.nvim",
    ft = "http",
    keys = {
      { "<leader>rr", function() require("kulala").run() end, desc = "Run Request", ft = "http" },
      { "<leader>ra", function() require("kulala").run_all() end, desc = "Run All Requests", ft = "http" },
      { "<leader>rp", function() require("kulala").jump_prev() end, desc = "Previous Request", ft = "http" },
      { "<leader>rn", function() require("kulala").jump_next() end, desc = "Next Request", ft = "http" },
      { "<leader>ri", function() require("kulala").inspect() end, desc = "Inspect Request", ft = "http" },
      { "<leader>re", function() require("kulala").set_selected_env() end, desc = "Select Environment", ft = "http" },
    },
    opts = {},
  },
}
