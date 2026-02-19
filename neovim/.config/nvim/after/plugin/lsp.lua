-- Reserve a space in the gutter
vim.opt.signcolumn = 'yes'

-- blink.cmp auto-injects capabilities on nvim 0.11 via its plugin file

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    local opts = {buffer = event.buf}
    vim.keymap.set('n', '<C-]>', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
    vim.keymap.set('n', 'gh', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
    vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
  end,
})

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
vim.lsp.config('ts_ls', {
  root_markers = { 'pnpm-workspace.yaml', '.git' },
  cmd_env = { NODE_OPTIONS = '--max-old-space-size=8192' },
  init_options = {
    preferences = {
      preferGoToSourceDefinition = true,
    },
    maxTsServerMemory = 8192,
  },
})

vim.lsp.config('eslint', {
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  settings = {
    nodePath = vim.fn.exepath('node'),
    workingDirectories = { mode = 'auto' },
  },
  cmd_env = { NODE_OPTIONS = '--max-old-space-size=8192' },
})

vim.lsp.enable({ 'ts_ls', 'eslint' })
