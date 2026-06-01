return {
  {
    "folke/edgy.nvim",
    opts = function(_, opts)
      -- Prevent edgy from managing the Claude Code terminal
      for _, pos in ipairs({ "right", "bottom", "left", "top" }) do
        opts[pos] = opts[pos] or {}
        for i, view in ipairs(opts[pos]) do
          if type(view) == "table" and view.ft == "snacks_terminal" then
            local orig_filter = view.filter
            opts[pos][i].filter = function(buf, win)
              local name = vim.api.nvim_buf_get_name(buf)
              if name:lower():match("claude") then
                return false
              end
              if orig_filter then
                return orig_filter(buf, win)
              end
              return true
            end
          end
        end
      end
    end,
  },
}
