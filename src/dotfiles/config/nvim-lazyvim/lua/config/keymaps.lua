-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local map = vim.keymap.set

-- Save / Undo (macOS Cmd keys for GUI terminals)
map({ "i", "x", "n", "s" }, "<D-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map({ "i", "n" }, "<D-z>", "<cmd>undo<cr><esc>", { desc = "Undo" })

-- Makefile runner
map("n", "<leader>cb", "<cmd>MakeitOpen<cr>", { desc = "Makefile" })

-- Buffer management
map("n", "<leader>q", function()
  Snacks.bufdelete()
end, { desc = "Close Buffer" })
map("n", "<leader>Q", "<cmd>qa<cr>", { desc = "Quit All" })

-- LSP actions
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>co", function()
  vim.lsp.buf.code_action({
    apply = true,
    context = { only = { "source.organizeImports" }, diagnostics = {} },
  })
end, { desc = "Organize Imports" })

-- Terminal (Neovim built-in)
map("n", "<C-/>", function()
  Snacks.terminal()
end, { desc = "Toggle Terminal" })
map("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit Terminal Mode" })

-- Task runner
map("n", "<leader>R", "<cmd>OverseerRun<cr>", { desc = "Run Task" })

-- Search & Replace (grug-far)
map("n", "<leader>sr", function()
  require("grug-far").open()
end, { desc = "Search & Replace" })
map("v", "<leader>sr", function()
  require("grug-far").with_visual_selection()
end, { desc = "Search & Replace (selection)" })

-- Scratch files
map("n", "<leader>.", function()
  Snacks.scratch()
end, { desc = "Scratch Buffer" })
map("n", "<leader>S", function()
  Snacks.scratch.select()
end, { desc = "Select Scratch Buffer" })

-- Notification history
map("n", "<leader>N", function()
  Snacks.notifier.show_history()
end, { desc = "Notification History" })

-- Go to test file
map("n", "gt", function()
  local file = vim.fn.expand("%:t:r")
  local ext = vim.fn.expand("%:e")
  local dir = vim.fn.expand("%:p:h")

  local patterns = {
    dir .. "/" .. file .. "_test." .. ext, -- Go: foo_test.go
    dir .. "/" .. file .. ".test." .. ext, -- JS/TS: foo.test.ts
    dir .. "/" .. file .. ".spec." .. ext, -- JS/TS: foo.spec.ts
    dir .. "/__tests__/" .. file .. "." .. ext, -- Jest: __tests__/foo.ts
  }

  for _, pattern in ipairs(patterns) do
    if vim.fn.filereadable(pattern) == 1 then
      vim.cmd("edit " .. pattern)
      return
    end
  end

  vim.notify("No test file found", vim.log.levels.WARN)
end, { desc = "Go to Test File" })
