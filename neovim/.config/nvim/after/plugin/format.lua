local ok, conform = pcall(require, 'conform')
if not ok then
  return
end

conform.setup({
  notify_on_error = false,
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
    timeout_ms = 1500,
    lsp_format = 'fallback'
  }
})

vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
  conform.format({
    lsp_format = 'fallback',
    timeout_ms = 1500
  })
end, { desc = 'Format buffer' })
