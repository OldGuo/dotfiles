vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
-- buffers
vim.api.nvim_set_keymap("n", "<leader>bh", ":BufferLineCycleNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>bl", ":BufferLineCyclePrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>bd", ":bdelete<CR>", { noremap = true, silent = true })
-- splits
vim.api.nvim_set_keymap("n", "<leader>%", ":vsplit<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", '<leader>"', ":split<CR>", { noremap = true, silent = true })

-- git diff workflow
vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { silent = true })
vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewClose<CR>", { silent = true })
vim.keymap.set("n", "<leader>gs", "<cmd>Gdiffsplit<CR>", { silent = true })
