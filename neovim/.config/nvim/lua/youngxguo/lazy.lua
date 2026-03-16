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
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      "telescope",
      formatter = "path.filename_first",
      winopts = {
        preview = {
          layout = "vertical",
          vertical = "down:50%",
        },
      },
      fzf_opts = {
        ["--layout"] = "reverse",
      },
      files = {
        hidden = true,
        rg_opts = [[--color=never --hidden --files -g "!.git" -g "!node_modules/**" -g "!bazel-out/**" -g "!bazel-bin/**" -g "!bazel-testlogs/**" -g "!bazel-applied*/**" -g "!lcov-report/**" -g "!map_tiles/**" -g "!*.generated" -g "!data/py/**"]],
        fd_opts = [[--color=never --hidden --type f --type l --exclude .git --exclude node_modules --exclude bazel-out --exclude bazel-bin --exclude bazel-testlogs --exclude bazel-applied* --exclude lcov-report --exclude map_tiles --exclude data/py --exclude *.generated]],
      },
      grep = {
        rg_opts = [[--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --glob "!.git" --glob "!node_modules/**" --glob "!bazel-out/**" --glob "!bazel-bin/**" --glob "!bazel-testlogs/**" --glob "!bazel-applied*/**" --glob "!lcov-report/**" --glob "!map_tiles/**" --glob "!*.generated" --glob "!data/py/**" -e]],
      },
    },
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
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = { "javascript", "typescript", "lua", "c", "cpp" },
        auto_install = true,
      })
    end,
  },
  { "neovim/nvim-lspconfig" },
  { "stevearc/conform.nvim", lazy = false },
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
          ["<Tab>"] = { "show", "accept", "fallback" },
          ["<S-Tab>"] = { "select_prev", "fallback" },
        },
        completion = {
          list = {
            selection = {
              preselect = true,
              auto_insert = false,
            },
          },
          menu = {
            auto_show = function()
              return vim.fn.getcmdtype() == ":"
            end,
          },
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

  { "nvim-treesitter/nvim-treesitter-context", main = "treesitter-context", opts = { max_lines = 3 } },
  {
    "Bekaboo/dropbar.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
    keys = {
      {
        "<leader>;",
        function()
          require("dropbar.api").pick()
        end,
        desc = "Pick breadcrumb",
      },
      {
        "[;",
        function()
          require("dropbar.api").goto_context_start()
        end,
        desc = "Context start",
      },
      {
        "];",
        function()
          require("dropbar.api").select_next_context()
        end,
        desc = "Next context",
      },
    },
  },
  { "lewis6991/gitsigns.nvim" },
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    opts = {
      highlights = {
        incoming = "DiffAdd",
        current = "DiffChange",
        ancestor = "DiffText",
      },
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      disable_netrw = true,
      filters = { dotfiles = false },
      update_focused_file = { enable = true },
    },
  },
  { "nvim-tree/nvim-web-devicons" },
  { "rebelot/heirline.nvim" },
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
  { "numToStr/Comment.nvim", opts = {} },
  { "tpope/vim-fugitive" },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "ibhagwan/fzf-lua",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      integrations = {
        telescope = false,
        diffview = true,
        fzf_lua = true,
      },
    },
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
      "ibhagwan/fzf-lua",
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Octo",
    opts = {
      default_merge_method = "squash",
      picker = "fzf-lua",
    },
  },
})
