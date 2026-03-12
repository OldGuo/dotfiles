local ok, conform = pcall(require, 'conform')
if not ok then
  return
end

conform.setup({
  notify_on_error = true,
  formatters_by_ft = {
    javascript = { 'prettier' },
    javascriptreact = { 'prettier' },
    typescript = { 'prettier' },
    typescriptreact = { 'prettier' },
    json = { 'prettier' },
    css = { 'prettier' },
    markdown = { 'prettier' }
  },
  format_on_save = {
    timeout_ms = 5000,
    lsp_format = 'never'
  }
})

-- Run ESLint fix-all on save via the ESLint LSP (like VSCode's source.fixAll.eslint).
-- This is fast because the ESLint LSP keeps the TS project loaded in memory.
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function(args)
    local clients = vim.lsp.get_clients({ bufnr = args.buf, name = 'eslint' })
    if #clients > 0 then
      vim.lsp.buf.code_action({
        context = { only = { 'source.fixAll.eslint' }, diagnostics = {} },
        apply = true,
      })
    end
  end,
})

vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
  conform.format({
    lsp_format = 'never',
    timeout_ms = 5000
  })
end, { desc = 'Format buffer' })
