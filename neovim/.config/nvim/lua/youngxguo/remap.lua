vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
-- buffers
vim.api.nvim_set_keymap("n", "<leader>bh", ":BufferLineCycleNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>bl", ":BufferLineCyclePrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>bd", ":bdelete<CR>", { noremap = true, silent = true })
-- splits
vim.api.nvim_set_keymap("n", "<leader>%", ":vsplit<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", '<leader>"', ":split<CR>", { noremap = true, silent = true })

-- yank file path (relative to cwd)
vim.keymap.set("n", "<leader>yf", function()
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
  vim.fn.setreg("+", path)
  vim.notify(path)
end, { silent = true })

-- yank remote git URL for current file
vim.keymap.set("n", "<leader>yu", function()
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
  local line = vim.fn.line(".")
  local remote = vim.fn.trim(vim.fn.system("git remote get-url origin"))
  if vim.v.shell_error ~= 0 then
    vim.notify("Not a git repo or no remote", vim.log.levels.ERROR)
    return
  end
  -- normalize to https URL
  local url = remote:gsub("git@([^:]+):", "https://%1/"):gsub("%.git$", "")
  local branch = vim.fn.trim(vim.fn.system("git rev-parse --abbrev-ref HEAD"))
  url = url .. "/blob/" .. branch .. "/" .. path .. "#L" .. line
  vim.fn.setreg("+", url)
  vim.notify(url)
end, { silent = true })

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
-- octo (GitHub PR review)
vim.keymap.set("n", "<leader>ol", "<cmd>Octo pr search review-requested:@me is:open<CR>", { silent = true })
vim.keymap.set("n", "<leader>om", "<cmd>Octo pr search author:@me is:open<CR>", { silent = true })
vim.keymap.set("n", "<leader>oa", "<cmd>Octo pr search assignee:@me is:open<CR>", { silent = true })
vim.keymap.set("n", "<leader>os", "<cmd>Octo pr search<CR>", { silent = true })
vim.keymap.set("n", "<leader>oc", "<cmd>Octo pr checkout<CR>", { silent = true })
vim.keymap.set("n", "<leader>or", "<cmd>Octo review start<CR>", { silent = true })
vim.keymap.set("n", "<leader>od", "<cmd>Octo pr diff<CR>", { silent = true })

vim.keymap.set("n", "<leader>gl", function()
  local log_view = require("neogit.buffers.log_view")
  if log_view.is_open() and log_view.instance then
    log_view.instance:close()
  end

  require("neogit").action("log", "log_all_references", { "--graph", "--decorate", "--color" })()
end, { silent = true })
