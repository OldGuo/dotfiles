vim.g.mapleader = " "
-- file tree sidebar (vscode-like Ctrl+B)
vim.keymap.set("n", "<leader>b", "<cmd>NvimTreeToggle<CR>", { silent = true })

-- all project files with open buffers + recent files pinned to the top
vim.keymap.set("n", "<C-p>", function()
  local fzf = require("fzf-lua")
  local fzf_config = require("fzf-lua.config")
  local files_mod = require("fzf-lua.providers.files")
  local bufs_mod = require("fzf-lua.providers.buffers")

  -- resolve the fd/rg command fzf-lua would normally use
  local fopts = fzf_config.normalize_opts({}, "files")
  local files_cmd = files_mod.get_files_cmd(fopts)

  local pinned = {}
  local seen = {}

  -- open buffers sorted by last used (most recent first)
  for _, bufnr in ipairs(bufs_mod.list_bufs_sorted()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= "" then
        local rel = vim.fn.fnamemodify(name, ":.")
        if not rel:match("^/") and not seen[rel] then
          seen[rel] = true
          table.insert(pinned, rel)
        end
      end
    end
  end

  -- oldfiles for cross-session persistence (via shada)
  local cwd = vim.fn.getcwd() .. "/"
  for _, f in ipairs(vim.v.oldfiles) do
    if f:sub(1, #cwd) == cwd then
      local rel = f:sub(#cwd + 1)
      if not seen[rel] and vim.uv.fs_stat(f) then
        seen[rel] = true
        table.insert(pinned, rel)
      end
    end
  end

  local raw
  if #pinned > 0 then
    local escaped = {}
    for _, b in ipairs(pinned) do
      table.insert(escaped, vim.fn.shellescape(b))
    end
    -- print pinned paths first, then all files, deduplicate preserving order
    raw = "{ printf '%s\\n' " .. table.concat(escaped, " ") .. " ; " .. files_cmd .. " ; } | awk '!seen[$0]++'"
  else
    raw = files_cmd
  end

  fzf.global({
    raw_cmd = raw,
    fzf_opts = { ["--tiebreak"] = "index" },
  })
end, { silent = true })
-- vim/tmux pane navigation
local tmux_bin = vim.fn.exepath("tmux")
if tmux_bin == "" then
  tmux_bin = "tmux"
end

local tmux_dir_map = { h = "L", j = "D", k = "U", l = "R" }

local function tmux_navigate(direction)
  local nr = vim.fn.winnr()
  vim.cmd("wincmd " .. direction)
  if nr == vim.fn.winnr() and vim.env.TMUX then
    vim.fn.system({ tmux_bin, "select-pane", "-" .. tmux_dir_map[direction] })
  end
end

vim.keymap.set("n", "<C-h>", function() tmux_navigate("h") end, { silent = true })
vim.keymap.set("n", "<C-j>", function() tmux_navigate("j") end, { silent = true })
vim.keymap.set("n", "<C-k>", function() tmux_navigate("k") end, { silent = true })
vim.keymap.set("n", "<C-l>", function() tmux_navigate("l") end, { silent = true })

-- splits
vim.api.nvim_set_keymap("n", "<leader>\\", ":vsplit<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>-", ":split<CR>", { noremap = true, silent = true })

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
  local commit = vim.fn.trim(vim.fn.system("git rev-parse origin/HEAD"))
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

-- git blame: view current line's commit in Diffview
vim.keymap.set("n", "<leader>gc", function()
  local file = vim.fn.expand("%:p")
  local lnum = vim.fn.line(".")
  local out = vim.fn.system({ "git", "blame", "-L", lnum .. "," .. lnum, "--porcelain", "--", file })
  local sha = out:match("^(%x+)")
  if not sha or sha:match("^0+$") then
    vim.notify("No commit for this line (uncommitted change)", vim.log.levels.WARN)
    return
  end
  vim.cmd("DiffviewOpen " .. sha .. "^.." .. sha)
end, { silent = true, desc = "Git blame commit in Diffview" })

-- git blame: open current line's commit on remote
vim.keymap.set("n", "<leader>gC", function()
  local file = vim.fn.expand("%:p")
  local lnum = vim.fn.line(".")
  local out = vim.fn.system({ "git", "blame", "-L", lnum .. "," .. lnum, "--porcelain", "--", file })
  local sha = out:match("^(%x+)")
  if not sha or sha:match("^0+$") then
    vim.notify("No commit for this line (uncommitted change)", vim.log.levels.WARN)
    return
  end
  local remote_url = vim.fn.system("git remote get-url origin"):gsub("%s+$", "")
  -- normalize to https URL
  remote_url = remote_url:gsub("^git@([^:]+):", "https://%1/"):gsub("%.git$", "")
  local url = remote_url .. "/commit/" .. sha
  yank_and_notify(url)
end, { silent = true, desc = "Open line's commit on remote" })

-- git workflow
vim.keymap.set("n", "<leader>gs", "<cmd>Gdiffsplit<CR>", { silent = true })
vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<CR>", { silent = true })
vim.keymap.set("n", "<leader>gb", function()
  require("fzf-lua").git_branches()
end, { silent = true, desc = "Git branches" })
-- octo (GitHub PR review)
vim.keymap.set("n", "<leader>ol", "<cmd>Octo pr search is:pr sort:updated-desc user-review-requested:@me is:open<CR>", { silent = true })
vim.keymap.set("n", "<leader>om", "<cmd>Octo pr search author:@me is:open<CR>", { silent = true })
vim.keymap.set("n", "<leader>oa", "<cmd>Octo pr search assignee:@me is:open<CR>", { silent = true })
vim.keymap.set("n", "<leader>os", "<cmd>Octo pr search<CR>", { silent = true })
vim.keymap.set("n", "<leader>oc", "<cmd>Octo pr checkout<CR>", { silent = true })
vim.keymap.set("n", "<leader>or", "<cmd>Octo review start<CR>", { silent = true })
vim.keymap.set("n", "<leader>oR", "<cmd>Octo review submit<CR>", { silent = true })
vim.keymap.set("n", "<leader>oe", "<cmd>Octo review resume<CR>", { silent = true })
vim.keymap.set("n", "<leader>od", "<cmd>Octo pr diff<CR>", { silent = true })
