return {
  { -- This plugin
    "Zeioth/makeit.nvim",
    cmd = { "MakeitOpen", "MakeitToggleResults", "MakeitRedo" },
    dependencies = { "stevearc/overseer.nvim" },
    opts = {},
  },
  { -- The task runner we use
    "stevearc/overseer.nvim",
    cmd = { "MakeitOpen", "MakeitToggleResults", "MakeitRedo", "OverseerRun", "OverseerToggle" },
    opts = {
      task_list = {
        direction = "bottom",
        min_height = 25,
        max_height = 25,
        default_detail = 1,
      },
      templates = {
        "builtin",
        "make",
        "npm",
        "shell",
        "go",
        "docker",
      },
    },
  },
}
