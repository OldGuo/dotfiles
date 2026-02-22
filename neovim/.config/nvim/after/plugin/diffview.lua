local function diffview_ctx()
  local ok_lib, lib = pcall(require, "diffview.lib")
  if not ok_lib or not lib then
    return nil
  end

  local ok_diff, DiffView = pcall(function()
    return require("diffview.scene.views.diff.diff_view").DiffView
  end)
  local ok_history, FileHistoryView = pcall(function()
    return require("diffview.scene.views.file_history.file_history_view").FileHistoryView
  end)

  return {
    lib = lib,
    DiffView = ok_diff and DiffView or nil,
    FileHistoryView = ok_history and FileHistoryView or nil,
  }
end

local function is_view(view, klass)
  return view and klass and view.instanceof and view:instanceof(klass)
end

local function find_view(predicate)
  local ctx = diffview_ctx()
  if not ctx then
    return nil
  end

  local current = ctx.lib.get_current_view and ctx.lib.get_current_view() or nil
  if predicate(current, ctx) then
    return current, ctx
  end

  for _, view in ipairs(ctx.lib.views or {}) do
    if predicate(view, ctx) and view.tabpage and vim.api.nvim_tabpage_is_valid(view.tabpage) then
      return view, ctx
    end
  end
end

local function focus_view(predicate, on_focus)
  local view = find_view(predicate)
  if not view then
    return false
  end

  if view.tabpage and vim.api.nvim_tabpage_is_valid(view.tabpage) then
    vim.api.nvim_set_current_tabpage(view.tabpage)
  end

  if on_focus then
    pcall(on_focus, view)
  end

  return true
end

local function file_history_matches(view, file)
  local ctx = diffview_ctx()
  if not ctx or not is_view(view, ctx.FileHistoryView) then
    return false
  end

  if not (view.panel and view.panel.single_file) then
    return false
  end

  local path_args = view.adapter and view.adapter.ctx and view.adapter.ctx.path_args or nil
  if type(path_args) ~= "table" or #path_args == 0 then
    return false
  end

  local target = vim.fs.normalize(vim.fn.fnamemodify(file, ":p"))
  local repo_root = view.adapter.ctx.toplevel and vim.fs.normalize(view.adapter.ctx.toplevel) or nil

  for _, arg in ipairs(path_args) do
    if type(arg) == "string" then
      local normalized = vim.fs.normalize(arg)
      if normalized == target then
        return true
      end

      if repo_root and arg:sub(1, 1) ~= "/" then
        if vim.fs.normalize(repo_root .. "/" .. arg) == target then
          return true
        end
      end
    end
  end

  return false
end

vim.keymap.set("n", "<leader>gd", function()
  if focus_view(function(view, ctx)
    return is_view(view, ctx.DiffView)
  end, function()
    pcall(require("diffview.actions").refresh_files)
  end) then
    return
  end

  vim.cmd("DiffviewOpen")
end, { silent = true, desc = "Git diff (Diffview)" })

vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewClose<CR>", { silent = true, desc = "Close Diffview" })

vim.keymap.set("n", "<leader>gl", function()
  if focus_view(function(view, ctx)
    return is_view(view, ctx.FileHistoryView) and view.panel and not view.panel.single_file
  end) then
    return
  end

  vim.cmd("DiffviewFileHistory")
end, { silent = true, desc = "Git history (Diffview)" })

vim.keymap.set("n", "<leader>gL", function()
  local file = vim.fn.expand("%")
  if file == "" or vim.bo.buftype ~= "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return
  end

  if focus_view(function(view)
    return file_history_matches(view, file)
  end) then
    return
  end

  vim.cmd("DiffviewFileHistory --follow -- " .. vim.fn.fnameescape(file))
end, { silent = true, desc = "Git file history (Diffview)" })
