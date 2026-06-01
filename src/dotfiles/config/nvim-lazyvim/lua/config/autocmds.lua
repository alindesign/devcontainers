-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Auto-save on focus lost / buffer leave
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  group = vim.api.nvim_create_augroup("AutoSave", { clear = true }),
  callback = function(event)
    local buf = event.buf
    if vim.bo[buf].modified and vim.bo[buf].buftype == "" and vim.fn.expand("%") ~= "" then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent! write")
      end)
    end
  end,
})

-- Use tabs in Makefiles
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("Makefile Settings", { clear = true }),
  pattern = { "make" },
  callback = function()
    vim.opt_local.expandtab = false
  end,
})
