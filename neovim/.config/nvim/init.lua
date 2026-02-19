-- Suppress nvim-lspconfig deprecation warning
local notify = vim.notify
vim.notify = function(msg, ...)
  if msg:match("nvim%-lspconfig.*deprecated") then
    return
  end
  notify(msg, ...)
end

require("youngxguo")
