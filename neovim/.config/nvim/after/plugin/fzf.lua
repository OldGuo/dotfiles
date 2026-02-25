local fzf = require("fzf-lua")

local function live_grep_project()
  fzf.live_grep({
    hidden = true,
  })
end

vim.keymap.set("n", "<leader>pf", fzf.files, { desc = "FzfLua find files" })
vim.keymap.set("n", "<leader>pg", fzf.git_files, { desc = "FzfLua git files" })
vim.keymap.set("n", "<leader>/", live_grep_project, { desc = "FzfLua live grep (project)" })
vim.keymap.set("n", "<leader>po", fzf.lsp_document_symbols, { desc = "FzfLua document symbols" })
vim.keymap.set("n", "<leader>ps", function()
  local search = vim.fn.input("Grep > ")
  if search == nil or search == "" then
    return
  end
  fzf.grep({ search = search })
end, { desc = "FzfLua grep prompt" })
