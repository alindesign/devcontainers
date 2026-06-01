-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local opt = vim.opt

opt.scrolloff = 5
opt.relativenumber = true
opt.cursorline = true

-- Use system clipboard
opt.clipboard = "unnamedplus"

-- Tabs: 2 spaces default (languages override via ftplugin)
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true

-- Disable netrw (snacks.explorer is used on demand via <leader>e)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
