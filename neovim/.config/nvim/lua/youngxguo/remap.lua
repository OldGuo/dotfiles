vim.g.mapleader = " "
-- file tree sidebar (vscode-like Ctrl+B)
vim.keymap.set("n", "<leader>b", "<cmd>NvimTreeToggle<CR>", { silent = true })

local function fzf_supports_global()
  if vim.fn.executable("fzf") ~= 1 then
    return false
  end

  local version = (vim.fn.systemlist({ "fzf", "--version" })[1] or "")
  local major, minor = version:match("^(%d+)%.(%d+)")
  major = tonumber(major)
  minor = tonumber(minor)

  if not major or not minor then
    return false
  end

  return major > 0 or minor >= 59
end

local function fzf_global_or_files()
  local fzf = require("fzf-lua")
  if fzf_supports_global() then
    fzf.global()
    return
  end

  vim.notify_once("[fzf-lua] fzf < 0.59, using files for <C-p>", vim.log.levels.WARN)
  fzf.files()
end

-- single picker entry point (files by default, `$` buffers, `@`/`#` symbols)
vim.keymap.set("n", "<C-p>", function()
  fzf_global_or_files()
end, { silent = true })
-- splits
vim.api.nvim_set_keymap("n", "<leader>%", ":vsplit<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", '<leader>"', ":split<CR>", { noremap = true, silent = true })

-- search: center + open folds after jumping (neoscroll animates the zz)
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- tabs
vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<CR>", { silent = true })
vim.keymap.set("n", "<leader>tc", "<cmd>tabclose<CR>", { silent = true })

-- yank to system clipboard and notify
local function yank_and_notify(text)
  vim.fn.setreg("+", text)
  -- ensure OSC 52 copy is triggered directly
  local osc52 = vim.g.clipboard and vim.g.clipboard.copy and vim.g.clipboard.copy["+"]
  if osc52 then osc52({ text }) end
  vim.notify(text)
end

-- yank file path (relative to cwd)
vim.keymap.set("n", "<leader>yf", function()
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
  yank_and_notify(path)
end, { silent = true })

-- yank remote line link
local function git_remote_url(path, line_suffix)
  local remote = vim.fn.trim(vim.fn.system("git remote get-url origin"))
  if vim.v.shell_error ~= 0 then
    vim.notify("Not a git repo or no remote", vim.log.levels.ERROR)
    return
  end
  local url = remote:gsub("git@([^:]+):", "https://%1/"):gsub("%.git$", "")
  local commit = vim.fn.trim(vim.fn.system("git rev-parse master"))
  url = url .. "/blob/" .. commit .. "/" .. path .. line_suffix
  yank_and_notify(url)
end

vim.keymap.set({ "n", "v" }, "<leader>yl", function()
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local start = vim.fn.line("v")
    local finish = vim.fn.line(".")
    if start > finish then start, finish = finish, start end
    git_remote_url(path, "#L" .. start .. "-L" .. finish)
  else
    git_remote_url(path, "#L" .. vim.fn.line("."))
  end
end, { silent = true })

-- git hunk navigation (gitsigns)
vim.keymap.set("n", "<leader>gj", function() require("gitsigns").nav_hunk("next") end, { silent = true, desc = "Next git change" })
vim.keymap.set("n", "<leader>gk", function() require("gitsigns").nav_hunk("prev") end, { silent = true, desc = "Previous git change" })

-- git workflow
vim.keymap.set("n", "<leader>gs", "<cmd>Gdiffsplit<CR>", { silent = true })
vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<CR>", { silent = true })
vim.keymap.set("n", "<leader>gb", function()
  require("fzf-lua").git_branches()
end, { silent = true, desc = "Git branches" })
-- octo (GitHub PR review)
vim.keymap.set("n", "<leader>ol", "<cmd>Octo pr search review-requested:@me is:open<CR>", { silent = true })
vim.keymap.set("n", "<leader>om", "<cmd>Octo pr search author:@me is:open<CR>", { silent = true })
vim.keymap.set("n", "<leader>oa", "<cmd>Octo pr search assignee:@me is:open<CR>", { silent = true })
vim.keymap.set("n", "<leader>os", "<cmd>Octo pr search<CR>", { silent = true })
vim.keymap.set("n", "<leader>oc", "<cmd>Octo pr checkout<CR>", { silent = true })
vim.keymap.set("n", "<leader>or", "<cmd>Octo review start<CR>", { silent = true })
vim.keymap.set("n", "<leader>od", "<cmd>Octo pr diff<CR>", { silent = true })
