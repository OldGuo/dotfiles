-- Reserve a space in the gutter
vim.opt.signcolumn = 'yes'

vim.diagnostic.config({
  underline = true,
  virtual_text = { spacing = 4, prefix = '●' },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '✘',
      [vim.diagnostic.severity.WARN] = '▲',
      [vim.diagnostic.severity.HINT] = '⚑',
      [vim.diagnostic.severity.INFO] = '»',
    },
  },
  severity_sort = true,
})

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

local enabled_servers = { 'ts_ls' }
if vim.fn.executable('vscode-eslint-language-server') == 1 then
  vim.lsp.config('eslint', {
    cmd = { 'vscode-eslint-language-server', '--stdio' },
    settings = {
      nodePath = vim.fn.exepath('node'),
      workingDirectories = { mode = 'auto' }
    },
    cmd_env = { NODE_OPTIONS = '--max-old-space-size=8192' }
  })

  table.insert(enabled_servers, 'eslint')
end

vim.lsp.enable(enabled_servers)

local uv = vim.uv or vim.loop

vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.ts', '*.tsx', '*.js', '*.jsx' },
  callback = function(event)
    if vim.fn.exists(':LspEslintFixAll') ~= 2 then
      return
    end

    local eslint_configs = {
      'eslint.config.js',
      'eslint.config.cjs',
      'eslint.config.mjs',
      'eslint.config.ts',
      '.eslintrc',
      '.eslintrc.js',
      '.eslintrc.cjs',
      '.eslintrc.json',
      '.eslintrc.yaml',
      '.eslintrc.yml'
    }
    local config_match = vim.fs.find(eslint_configs, {
      path = vim.api.nvim_buf_get_name(event.buf),
      upward = true,
      stop = uv.os_homedir(),
      limit = 1
    })

    if #config_match == 0 then
      return
    end

    local clients = vim.lsp.get_clients({ bufnr = event.buf, name = 'eslint' })
    if #clients > 0 then
      vim.cmd('silent! LspEslintFixAll')
    end
  end,
})
