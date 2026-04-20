local ok, heirline = pcall(require, "heirline")
if not ok then
  return
end

local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local colors = {
  base03 = "#002b36",
  base02 = "#073642",
  base01 = "#586e75",
  base00 = "#657b83",
  base0 = "#839496",
  base1 = "#93a1a1",
  base2 = "#eee8d5",
  blue = "#268bd2",
  cyan = "#2aa198",
  green = "#859900",
  orange = "#cb4b16",
  red = "#dc322f",
  magenta = "#d33682",
  violet = "#6c71c4",
  yellow = "#b58900",
}

local mode_names = {
  n = "NORMAL",
  no = "O-PEND",
  nov = "O-PEND",
  noV = "O-PEND",
  ["no\22"] = "O-PEND",
  niI = "NORMAL",
  niR = "NORMAL",
  niV = "NORMAL",
  nt = "NORMAL",
  v = "VISUAL",
  vs = "VISUAL",
  V = "V-LINE",
  Vs = "V-LINE",
  ["\22"] = "V-BLOCK",
  ["\22s"] = "V-BLOCK",
  s = "SELECT",
  S = "S-LINE",
  ["\19"] = "S-BLOCK",
  i = "INSERT",
  ic = "INSERT",
  ix = "INSERT",
  R = "REPLACE",
  Rc = "REPLACE",
  Rx = "REPLACE",
  Rv = "V-REPL",
  c = "COMMAND",
  cv = "EX",
  ce = "EX",
  r = "PROMPT",
  rm = "MORE",
  ["r?"] = "CONFIRM",
  ["!"] = "SHELL",
  t = "TERMINAL",
}

local mode_colors = {
  n = colors.blue,
  no = colors.blue,
  niI = colors.blue,
  niR = colors.blue,
  niV = colors.blue,
  nt = colors.blue,
  v = colors.magenta,
  vs = colors.magenta,
  V = colors.magenta,
  Vs = colors.magenta,
  ["\22"] = colors.magenta,
  ["\22s"] = colors.magenta,
  s = colors.violet,
  S = colors.violet,
  ["\19"] = colors.violet,
  i = colors.green,
  ic = colors.green,
  ix = colors.green,
  R = colors.orange,
  Rc = colors.orange,
  Rx = colors.orange,
  Rv = colors.orange,
  c = colors.yellow,
  cv = colors.yellow,
  ce = colors.yellow,
  r = colors.cyan,
  rm = colors.cyan,
  ["r?"] = colors.cyan,
  ["!"] = colors.red,
  t = colors.red,
}

local function statusline_win()
  local winid = tonumber(vim.g.statusline_winid)
  if winid and vim.api.nvim_win_is_valid(winid) then
    return winid
  end
  return vim.api.nvim_get_current_win()
end

local function statusline_buf(winid)
  winid = winid or statusline_win()
  if vim.api.nvim_win_is_valid(winid) then
    return vim.api.nvim_win_get_buf(winid)
  end
  return vim.api.nvim_get_current_buf()
end

local function is_active()
  local winid = tonumber(vim.g.statusline_winid)
  if winid == nil then
    -- With a global statusline (laststatus=3), Neovim may not expose statusline_winid
    -- the same way. Treat it as active so the mode block still renders.
    return vim.o.laststatus == 3
  end
  return vim.api.nvim_get_current_win() == winid
end

local function win_width(winid)
  winid = winid or statusline_win()
  if vim.api.nvim_win_is_valid(winid) then
    return vim.api.nvim_win_get_width(winid)
  end
  return vim.o.columns
end

local function get_file_label(bufnr, winid)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local bt = vim.bo[bufnr].buftype
  local ft = vim.bo[bufnr].filetype
  if name == "" then
    if ft == "NvimTree" then
      return "Files"
    end
    if ft == "TelescopePrompt" then
      return "Telescope"
    end
    if bt == "terminal" then
      return "Terminal"
    end
    if bt == "quickfix" then
      return "Quickfix"
    end
    if bt == "help" then
      return "Help"
    end
    if ft ~= "" then
      return ft
    end
    return "[No Name]"
  end
  return vim.fn.fnamemodify(name, ":~:.")
end

local Align = { provider = "%=" }
local Space = { provider = " " }

local ViMode = {
  init = function(self)
    self.mode = vim.fn.mode(1)
  end,
  provider = function(self)
    local name = mode_names[self.mode] or mode_names[self.mode:sub(1, 1)] or self.mode
    return " " .. name .. " "
  end,
  hl = function(self)
    local bg = mode_colors[self.mode] or mode_colors[self.mode:sub(1, 1)] or colors.blue
    return { fg = colors.base03, bg = bg, bold = true }
  end,
  update = { "ModeChanged", "BufEnter", "WinEnter" },
}

local ModeSep = {
  provider = "",
  hl = function()
    local m = vim.fn.mode(1)
    local bg = mode_colors[m] or mode_colors[m:sub(1, 1)] or colors.blue
    return { fg = bg, bg = colors.base03 }
  end,
  update = { "ModeChanged", "BufEnter", "WinEnter" },
}

local FileBlock = {
  init = function(self)
    self.winid = statusline_win()
    self.bufnr = statusline_buf(self.winid)
    self.filename = vim.api.nvim_buf_get_name(self.bufnr)
    self.file_label = get_file_label(self.bufnr, self.winid)
    self.modified = vim.bo[self.bufnr].modified
    self.readonly = vim.bo[self.bufnr].readonly or not vim.bo[self.bufnr].modifiable

    local ext = vim.fn.fnamemodify(self.filename, ":e")
    if has_devicons then
      self.icon, self.icon_color = devicons.get_icon_color(self.filename, ext, { default = true })
    end
  end,
  {
    provider = " ",
  },
  {
    provider = function(self)
      if not self.icon then
        return ""
      end
      return self.icon .. " "
    end,
    hl = function(self)
      return { fg = self.icon_color or colors.blue }
    end,
  },
  {
    provider = function(self)
      return self.file_label
    end,
    hl = function(self)
      if self.modified then
        return { fg = colors.base2, bold = true }
      end
      return { fg = colors.base1 }
    end,
  },
  {
    provider = function(self)
      local parts = {}
      if self.modified then
        table.insert(parts, "[+]")
      end
      if self.readonly then
        table.insert(parts, "")
      end
      if #parts == 0 then
        return ""
      end
      return " " .. table.concat(parts, " ")
    end,
    hl = function(self)
      if self.modified then
        return { fg = colors.yellow, bold = true }
      end
      return { fg = colors.orange }
    end,
  },
}

local Git = {
  condition = function(self)
    self.winid = statusline_win()
    self.bufnr = statusline_buf(self.winid)
    return vim.b[self.bufnr].gitsigns_head ~= nil
  end,
  init = function(self)
    self.winid = statusline_win()
    self.bufnr = statusline_buf(self.winid)
    self.git = vim.b[self.bufnr].gitsigns_status_dict or {}
    self.head = vim.b[self.bufnr].gitsigns_head
  end,
  {
    provider = "  ",
  },
  {
    provider = function(self)
      if not self.head or self.head == "" then
        return ""
      end
      return " " .. self.head
    end,
    hl = { fg = colors.violet, bold = true },
  },
  {
    provider = function(self)
      local parts = {}
      if (self.git.added or 0) > 0 then
        table.insert(parts, "+" .. self.git.added)
      end
      if (self.git.changed or 0) > 0 then
        table.insert(parts, "~" .. self.git.changed)
      end
      if (self.git.removed or 0) > 0 then
        table.insert(parts, "-" .. self.git.removed)
      end
      if #parts == 0 then
        return ""
      end
      return " (" .. table.concat(parts, " ") .. ")"
    end,
    hl = { fg = colors.base0 },
  },
}

local Diagnostics = {
  init = function(self)
    self.winid = statusline_win()
    self.bufnr = statusline_buf(self.winid)
    self.errors = #vim.diagnostic.get(self.bufnr, { severity = vim.diagnostic.severity.ERROR })
    self.warns = #vim.diagnostic.get(self.bufnr, { severity = vim.diagnostic.severity.WARN })
    self.infos = #vim.diagnostic.get(self.bufnr, { severity = vim.diagnostic.severity.INFO })
    self.hints = #vim.diagnostic.get(self.bufnr, { severity = vim.diagnostic.severity.HINT })
  end,
  condition = function(self)
    self.winid = statusline_win()
    self.bufnr = statusline_buf(self.winid)
    return not vim.tbl_isempty(vim.diagnostic.get(self.bufnr))
  end,
  {
    provider = " ",
  },
  {
    provider = function(self)
      if self.errors == 0 then
        return ""
      end
      return " " .. self.errors .. " "
    end,
    hl = { fg = colors.red },
  },
  {
    provider = function(self)
      if self.warns == 0 then
        return ""
      end
      return " " .. self.warns .. " "
    end,
    hl = { fg = colors.yellow },
  },
  {
    provider = function(self)
      if self.infos == 0 then
        return ""
      end
      return " " .. self.infos .. " "
    end,
    hl = { fg = colors.blue },
  },
  {
    provider = function(self)
      if self.hints == 0 then
        return ""
      end
      return "󰌵 " .. self.hints .. " "
    end,
    hl = { fg = colors.cyan },
  },
  hl = { bg = colors.base02 },
}

local Lsp = {
  condition = function(self)
    self.winid = statusline_win()
    if win_width(self.winid) < 100 then
      return false
    end
    self.bufnr = statusline_buf(self.winid)
    return #vim.lsp.get_clients({ bufnr = self.bufnr }) > 0
  end,
  init = function(self)
    self.winid = statusline_win()
    self.bufnr = statusline_buf(self.winid)
    local names = {}
    local seen = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = self.bufnr })) do
      if client.name and client.name ~= "" and not seen[client.name] then
        seen[client.name] = true
        table.insert(names, client.name)
      end
    end
    table.sort(names)
    self.lsp_names = names
  end,
  provider = function(self)
    return "  " .. table.concat(self.lsp_names, ", ") .. " "
  end,
  hl = { fg = colors.cyan, bg = colors.base02 },
}

local FileType = {
  init = function(self)
    self.winid = statusline_win()
    self.bufnr = statusline_buf(self.winid)
    self.ft = vim.bo[self.bufnr].filetype
  end,
  provider = function(self)
    local ft = self.ft ~= "" and self.ft or "text"
    return " " .. ft .. " "
  end,
  hl = { fg = colors.base1, bg = colors.base02 },
}

local Ruler = {
  init = function(self)
    self.winid = statusline_win()
    self.bufnr = statusline_buf(self.winid)
    local cursor = vim.api.nvim_win_get_cursor(self.winid)
    self.line = cursor[1]
    self.col = cursor[2] + 1
    self.total = math.max(vim.api.nvim_buf_line_count(self.bufnr), 1)
    self.percent = math.floor((self.line / self.total) * 100)
  end,
  provider = function(self)
    return string.format(" %d:%d %d%% ", self.line, self.col, self.percent)
  end,
  hl = { fg = colors.base2, bg = colors.base01, bold = true },
}

local ScrollBar = {
  static = {
    bars = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" },
  },
  init = function(self)
    self.winid = statusline_win()
    self.bufnr = statusline_buf(self.winid)
    local line = vim.api.nvim_win_get_cursor(self.winid)[1]
    local total = math.max(vim.api.nvim_buf_line_count(self.bufnr), 1)
    local i = math.floor(((line - 1) / total) * #self.bars) + 1
    self.bar = self.bars[math.min(math.max(i, 1), #self.bars)]
  end,
  provider = function(self)
    return self.bar .. " "
  end,
  hl = { fg = colors.blue, bg = colors.base01, bold = true },
}

local RightSep = {
  provider = "",
  hl = { fg = colors.base02, bg = colors.base03 },
}

local RightSepAlt = {
  provider = "",
  hl = { fg = colors.base01, bg = colors.base02 },
}

local ActiveStatusline = {
  condition = is_active,
  hl = { fg = colors.base1, bg = colors.base03 },
  ViMode,
  ModeSep,
  FileBlock,
  Git,
  Align,
  RightSep,
  Diagnostics,
  Lsp,
  FileType,
  RightSepAlt,
  Ruler,
  ScrollBar,
}

local InactiveStatusline = {
  hl = { fg = colors.base0, bg = colors.base03 },
  Space,
  FileBlock,
  Align,
  FileType,
  {
    provider = function(self)
      self.winid = statusline_win()
      if not vim.api.nvim_win_is_valid(self.winid) then
        return ""
      end
      local cursor = vim.api.nvim_win_get_cursor(self.winid)
      return string.format(" %d:%d ", cursor[1], cursor[2] + 1)
    end,
    hl = { fg = colors.base0, bg = colors.base02 },
  },
}

vim.o.showmode = false
vim.o.laststatus = 3

heirline.setup({
  statusline = {
    fallthrough = false,
    ActiveStatusline,
    InactiveStatusline,
  },
})
