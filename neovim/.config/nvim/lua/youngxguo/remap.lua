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
vim.keymap.set("n", "<leader>gd", function()
  local ok, lib = pcall(require, "diffview.lib")
  if ok and lib then
    if lib.get_current_view and lib.get_current_view() then
      return
    end

    if type(lib.views) == "table" then
      for _, view in ipairs(lib.views) do
        if view and view.tabpage and vim.api.nvim_tabpage_is_valid(view.tabpage) then
          vim.api.nvim_set_current_tabpage(view.tabpage)
          return
        end
      end
    end
  end

  vim.cmd("DiffviewOpen")
end, { silent = true })
vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewClose<CR>", { silent = true })
vim.keymap.set("n", "<leader>gs", "<cmd>Gdiffsplit<CR>", { silent = true })
vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<CR>", { silent = true })
vim.keymap.set("n", "<leader>gl", function()
  local log_view = require("neogit.buffers.log_view")
  if log_view.is_open() and log_view.instance then
    log_view.instance:close()
  end

  require("neogit").action("log", "log_all_references", { "--graph", "--decorate", "--color" })()
end, { silent = true })
