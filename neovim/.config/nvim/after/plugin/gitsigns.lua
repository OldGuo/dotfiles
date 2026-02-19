local ok, gitsigns = pcall(require, "gitsigns")
if not ok then
  return
end

gitsigns.setup({
  update_debounce = 100,
  watch_gitdir = {
    follow_files = true,
  },
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "^" },
    changedelete = { text = "~" },
  },
})
