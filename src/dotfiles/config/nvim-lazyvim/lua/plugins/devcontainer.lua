return {
  {
    "https://codeberg.org/esensar/nvim-dev-container",
    cmd = {
      "DevcontainerStart",
      "DevcontainerAttach",
      "DevcontainerExec",
      "DevcontainerStop",
      "DevcontainerStopAll",
      "DevcontainerRemoveAll",
      "DevcontainerLogs",
      "DevcontainerEditNearestConfig",
    },
    keys = {
      { "<leader>Cu", "<cmd>DevcontainerStart<cr>", desc = "Devcontainer Up/Start" },
      { "<leader>Ca", "<cmd>DevcontainerAttach<cr>", desc = "Devcontainer Attach" },
      { "<leader>Cx", "<cmd>DevcontainerExec<cr>", desc = "Devcontainer Exec" },
      { "<leader>Cs", "<cmd>DevcontainerStop<cr>", desc = "Devcontainer Stop" },
      { "<leader>CS", "<cmd>DevcontainerStopAll<cr>", desc = "Devcontainer Stop All" },
      { "<leader>CR", "<cmd>DevcontainerRemoveAll<cr>", desc = "Devcontainer Remove All" },
      { "<leader>Cl", "<cmd>DevcontainerLogs<cr>", desc = "Devcontainer Logs" },
      { "<leader>Ce", "<cmd>DevcontainerEditNearestConfig<cr>", desc = "Devcontainer Edit Config" },
    },
    opts = {
      autocommands = {
        init = true,
        clean = false,
        update = true,
      },
      generate_commands = true,
      nvim_installation_commands_provider = nil,
    },
    config = function(_, opts)
      require("devcontainer").setup(opts)
    end,
  },
}
