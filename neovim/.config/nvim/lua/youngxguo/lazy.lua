local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "nvim-telescope/telescope.nvim",
    version = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "maxmx03/solarized.nvim",
    config = function()
      local solarized = require("solarized")
      vim.o.termguicolors = true
      vim.o.background = "dark"
      solarized.setup({})
      vim.cmd.colorscheme("solarized")
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/nvim-cmp" },
  { "lukas-reineke/indent-blankline.nvim" },
  { "akinsho/bufferline.nvim" },
  { "lewis6991/gitsigns.nvim" },
})
