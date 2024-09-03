require("config.lazy")
require("lazy").setup("plugins")

-- vim settings
vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.wrap = true
vim.o.cursorline = true
vim.o.clipboard = 'unnamedplus'
vim.o.updatetime = 300
vim.o.timeoutlen = 500
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true
vim.o.hlsearch = true
vim.o.termguicolors = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.scrolloff = 8
vim.o.signcolumn = 'yes'
vim.o.background = 'dark'

-- telescope
local telescope = require('telescope.builtin')
vim.keymap.set('n', '<C-p>', telescope.find_files, {})
vim.keymap.set('n', '<C-f>', telescope.live_grep, {})

-- nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
local nvim_tree = require('nvim-tree.api')
vim.keymap.set('n', '<leader>e', nvim_tree.tree.toggle, {})
