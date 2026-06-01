return {
  -- Ensure debug adapters are installed via mason-nvim-dap
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      ensure_installed = { "js", "delve", "codelldb" },
    },
  },
  -- JS/TS debug configurations (Go handled by lang.go extra, Rust by rustaceanvim)
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      {
        "jay-babu/mason-nvim-dap.nvim",
        opts = function(_, opts)
          opts.handlers = opts.handlers or {}
          -- Extend JS handler to copy configurations to TypeScript filetypes
          opts.handlers.js = function(config)
            require("mason-nvim-dap").default_setup(config)
            local dap = require("dap")
            -- Ensure TS/JSX/TSX reuse the JS configurations
            for _, lang in ipairs({ "typescript", "typescriptreact", "javascriptreact" }) do
              dap.configurations[lang] = dap.configurations[lang] or dap.configurations.javascript
            end
          end
        end,
      },
    },
  },
}
