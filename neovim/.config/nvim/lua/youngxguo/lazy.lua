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
    opts = {
      ensure_installed = { "javascript", "typescript", "lua", "c" },
      sync_install = false,
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
    },
  },
  { "neovim/nvim-lspconfig" },
  { "j-hui/fidget.nvim", opts = {} },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/nvim-cmp" },
  { "lukas-reineke/indent-blankline.nvim" },
  { "akinsho/bufferline.nvim" },
  { "lewis6991/gitsigns.nvim" },
  { "nvim-tree/nvim-web-devicons" },
  { "christoomey/vim-tmux-navigator" },
  { "tpope/vim-fugitive" },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = true,
  },
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      use_icons = true,
    },
  },
  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Octo",
    opts = {
      default_merge_method = "squash",
      picker = "telescope",
    },
  },
})
