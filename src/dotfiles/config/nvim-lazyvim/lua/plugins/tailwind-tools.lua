return {
  {
    "luckasRanarison/tailwind-tools.nvim",
    name = "tailwind-tools",
    build = ":UpdateRemotePlugins",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = {
      "html",
      "css",
      "scss",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "vue",
      "svelte",
      "astro",
    },
    opts = {
      server = {
        override = false,
      },
      document_color = {
        enabled = true,
        kind = "inline",
      },
      conceal = {
        enabled = false,
      },
    },
  },
}
