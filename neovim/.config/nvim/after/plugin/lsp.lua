-- NOTE: to make any of this work you need a language server.
-- If you don't know what that is, watch this 5 min video:
-- https://www.youtube.com/watch?v=LaS32vctfOY

-- Reserve a space in the gutter
vim.opt.signcolumn = 'yes'

-- Add cmp_nvim_lsp capabilities settings to lspconfig
-- This should be executed before you configure any language server
local lspconfig_defaults = require('lspconfig').util.default_config
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
  'force',
  lspconfig_defaults.capabilities,
  require('cmp_nvim_lsp').default_capabilities()
)

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

-- You'll find a list of language servers here:
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
-- These are example language servers. 
require('lspconfig').ts_ls.setup({
  root_dir = require('lspconfig').util.root_pattern('pnpm-workspace.yaml', '.git'),
  cmd_env = { NODE_OPTIONS = '--max-old-space-size=8192' },
  init_options = {
    preferences = {
      preferGoToSourceDefinition = true,
    },
    maxTsServerMemory = 8192,
  },
})
require('lspconfig').eslint.setup({
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  settings = {
    nodePath = vim.fn.exepath('node'),
    -- Scope eslint to the nearest package directory, not the whole monorepo
    workingDirectories = { mode = 'auto' },
  },
  on_new_config = function(config)
    -- Increase Node heap for eslint in large monorepos
    config.cmd_env = { NODE_OPTIONS = '--max-old-space-size=8192' }
  end,
})

local cmp = require('cmp')

cmp.setup({
  preselect = 'item',
  completion = {
    completeopt = 'menu,menuone,noinsert'
  },
  sources = {
    {name = 'nvim_lsp'},
    {name = 'buffer'},
  },
  snippet = {
    expand = function(args)
      -- You need Neovim v0.10 to use vim.snippet
      vim.snippet.expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    -- Simple tab complete
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.confirm({ select = true })
      else
	fallback()
      end
    end, {'i', 's'}),

    -- Go to previous item
    ['<CR>'] = cmp.mapping.confirm({select = true}),
  }),
})
