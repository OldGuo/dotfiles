local ok, lint = pcall(require, 'lint')
if not ok then
  return
end

lint.linters_by_ft = {
  javascript = { 'oxlint' },
  ['javascript.jsx'] = { 'oxlint' },
  javascriptreact = { 'oxlint' },
  typescript = { 'oxlint' },
  ['typescript.tsx'] = { 'oxlint' },
  typescriptreact = { 'oxlint' }
}

local function resolve_oxlint(bufnr)
  local config_markers = {
    '.oxlintrc.json',
    '.oxlintrc',
    '.oxlintrc.js',
    '.oxlintrc.cjs',
    '.oxlintrc.mjs'
  }
  local config_match = vim.fs.find(config_markers, {
    path = vim.api.nvim_buf_get_name(bufnr),
    upward = true,
    stop = (vim.uv or vim.loop).os_homedir(),
    limit = 1
  })

  if #config_match == 0 then
    return nil, nil
  end

  local root = vim.fs.dirname(config_match[1])

  local local_bin = root .. '/node_modules/.bin/oxlint'
  if vim.fn.executable(local_bin) == 1 then
    return local_bin, root
  end

  local global_bin = vim.fn.exepath('oxlint')
  if global_bin ~= '' then
    return global_bin, root
  end

  return nil, root
end

local function run_lint(bufnr)
  local oxlint = lint.linters.oxlint
  if not oxlint then
    return
  end

  local cmd, root = resolve_oxlint(bufnr)
  if not cmd then
    return
  end

  oxlint.cmd = cmd
  oxlint.cwd = root

  lint.try_lint('oxlint')
end

local lint_group = vim.api.nvim_create_augroup('nvim_lint_oxlint', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
  group = lint_group,
  callback = function(args)
    run_lint(args.buf)
  end
})

vim.api.nvim_create_user_command('Lint', function()
  run_lint(vim.api.nvim_get_current_buf())
end, { desc = 'Run oxlint on current buffer' })
