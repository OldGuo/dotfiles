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

-- Initialize vim.lsp.config['*'] before plugins load (blink.cmp v1.x reads it)
if vim.lsp.config then
  vim.lsp.config('*', {})
end

require("lazy").setup({
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-frecency.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
          },
          file_ignore_patterns = {
            "node_modules/",
            "bazel%-out/",
            "bazel%-bin/",
            "bazel%-testlogs/",
            "bazel%-applied%w+/",
            "%.git/",
            "lcov%-report/",
            "map_tiles/",
            "%.generated",
            "data/py/",
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          frecency = {
            matcher = "fuzzy",
            workspace_scan_cmd = { "rg", "--files" },
            default_workspace = "CWD",
            db_safe_mode = false,
          },
        },
      })
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("frecency")
    end,
  },
  {
    "maxmx03/solarized.nvim",
    config = function()
      local solarized = require("solarized")
      vim.o.termguicolors = true
      vim.o.background = "dark"
      solarized.setup({})
      vim.cmd.colorscheme("solarized")
      -- Diff highlights: background-only so syntax highlighting is preserved
      vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#003a20" })
      vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3a0a10" })
      vim.api.nvim_set_hl(0, "DiffChange", { bg = "#002a40" })
      vim.api.nvim_set_hl(0, "DiffText", { bg = "#004a55" })
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
  { "stevearc/conform.nvim", lazy = false },
  { "mfussenegger/nvim-lint", lazy = false },
  { "j-hui/fidget.nvim", opts = {} },
  {
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
      keymap = {
        preset = "default",
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<Tab>"] = { "show", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
      },
      completion = {
        documentation = { auto_show = true },
      },
      cmdline = {
        enabled = true,
        keymap = {
          ["<Up>"] = { "select_prev", "fallback" },
          ["<Down>"] = { "select_next", "fallback" },
          ["<Tab>"] = { "show", "select_next", "fallback" },
          ["<S-Tab>"] = { "select_prev", "fallback" },
        },
      },
      sources = {
        default = { "lsp", "path", "buffer" },
      },
    },
  },
  { "lukas-reineke/indent-blankline.nvim" },
  {
    "karb94/neoscroll.nvim",
    opts = {
      duration_multiplier = 0.5,
    },
  },

  { "lewis6991/gitsigns.nvim" },
  { "nvim-tree/nvim-web-devicons" },
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        show_close_icon = false,
        show_buffer_close_icons = false,
        separator_style = "thin",
      },
    },
  },
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
      hooks = {
        diff_buf_read = function(bufnr)
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then return end
            local ft = vim.bo[bufnr].filetype
            if not ft or ft == "" then
              local name = vim.api.nvim_buf_get_name(bufnr)
              local clean = name:gsub("^diffview://.-/%.git/.-/", "")
              ft = vim.filetype.match({ buf = bufnr, filename = clean })
              if ft then
                vim.bo[bufnr].filetype = ft
              end
            end
            if ft and ft ~= "" then
              pcall(vim.treesitter.start, bufnr, ft)
            end
          end)
        end,
      },
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    opts = {
      cmdline = {
        view = "cmdline_popup",
      },
      messages = { enabled = false },
      popupmenu = { enabled = false },
      notify = { enabled = false },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
        progress = { enabled = false },
      },
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
