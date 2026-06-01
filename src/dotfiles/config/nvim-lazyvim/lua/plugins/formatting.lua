-- Smart formatter detection: use Biome when project has biome config, Prettier otherwise
return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      -- Detect biome config in project root
      local function has_biome_config()
        local root = vim.fn.getcwd()
        local biome_files = { "biome.json", "biome.jsonc" }
        for _, file in ipairs(biome_files) do
          if vim.fn.filereadable(root .. "/" .. file) == 1 then
            return true
          end
        end
        return false
      end

      opts.formatters_by_ft = opts.formatters_by_ft or {}

      -- JS/TS: Biome if project uses it, Prettier otherwise
      local js_ts_fts = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "json",
        "jsonc",
      }
      for _, ft in ipairs(js_ts_fts) do
        opts.formatters_by_ft[ft] = function()
          if has_biome_config() then
            return { "biome" }
          end
          return { "prettier" }
        end
      end

      -- CSS/SCSS: always Prettier
      opts.formatters_by_ft["css"] = { "prettier" }
      opts.formatters_by_ft["scss"] = { "prettier" }

      -- Shell scripts: shfmt
      opts.formatters_by_ft["sh"] = { "shfmt" }
      opts.formatters_by_ft["bash"] = { "shfmt" }
      opts.formatters_by_ft["zsh"] = { "shfmt" }
    end,
  },
}
