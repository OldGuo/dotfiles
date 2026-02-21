vim.g.mapleader = " "
-- file tree sidebar (vscode-like Ctrl+B)
vim.keymap.set("n", "<leader>b", "<cmd>NvimTreeToggle<CR>", { silent = true })

-- file picker: open buffers first, then recent files (from shada), then all files
vim.keymap.set("n", "<C-p>", function()
  -- 1. collect open buffers
  local bufs, seen = {}, {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
      local name = vim.api.nvim_buf_get_name(b)
      if name ~= "" then
        local rel = vim.fn.fnamemodify(name, ":.")
        if rel ~= "" then
          table.insert(bufs, rel)
          seen[rel] = true
        end
      end
    end
  end

  -- 2. recent files from previous sessions (oldfiles persisted via shada)
  local cwd = vim.fn.getcwd() .. "/"
  local recent = {}
  for _, f in ipairs(vim.v.oldfiles) do
    if f:sub(1, #cwd) == cwd then
      local rel = f:sub(#cwd + 1)
      if not seen[rel] and vim.fn.filereadable(f) == 1 then
        table.insert(recent, rel)
        seen[rel] = true
      end
    end
  end

  -- 3. remaining workspace files via rg
  local rest = {}
  for _, f in ipairs(vim.fn.systemlist({ "rg", "--files" })) do
    if not seen[f] then
      table.insert(rest, f)
    end
  end

  local results = vim.list_extend(vim.list_extend(bufs, recent), rest)

  require("telescope.pickers").new({}, {
    prompt_title = "Files",
    finder = require("telescope.finders").new_table({
      results = results,
      entry_maker = require("telescope.make_entry").gen_from_file({ path_display = { "truncate" } }),
    }),
    sorter = require("telescope.config").values.file_sorter({}),
    previewer = require("telescope.config").values.file_previewer({}),
  }):find()
end, { silent = true })
-- splits
vim.api.nvim_set_keymap("n", "<leader>%", ":vsplit<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", '<leader>"', ":split<CR>", { noremap = true, silent = true })

-- search: center + open folds after jumping (neoscroll animates the zz)
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- tabs
vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<CR>", { silent = true })

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

-- git hunk navigation (gitsigns)
vim.keymap.set("n", "<leader>gj", function() require("gitsigns").nav_hunk("next") end, { silent = true, desc = "Next git change" })
vim.keymap.set("n", "<leader>gk", function() require("gitsigns").nav_hunk("prev") end, { silent = true, desc = "Previous git change" })

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
          pcall(require("diffview.actions").refresh_files)
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
vim.keymap.set("n", "<leader>gb", function()
  require("telescope.builtin").git_branches()
end, { silent = true, desc = "Git branches" })
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

vim.keymap.set("n", "<leader>gL", function()
  local file = vim.fn.expand("%:.")
  if file == "" then
    return
  end

  local p = require("neogit.popups.log").create()
  p.state.env.files = { file }
end, { silent = true })
