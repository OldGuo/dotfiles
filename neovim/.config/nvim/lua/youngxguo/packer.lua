-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup({
  function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    use {
      'nvim-telescope/telescope.nvim', tag = '0.1.8',
      -- or                            , branch = '0.1.x',
      requires = { {'nvim-lua/plenary.nvim'} }
    }

    use {
      'maxmx03/solarized.nvim',
      config = function()
        vim.o.background = 'dark'
        ---@type solarized
        local solarized = require('solarized')
        vim.o.termguicolors = true
        vim.o.background = 'dark'
        solarized.setup({})
        vim.cmd.colorscheme 'solarized'
      end
    }

    use {
      'nvim-treesitter/nvim-treesitter',
      run = ':TSUpdate'
    }

    use({'neovim/nvim-lspconfig'})
    use({'hrsh7th/cmp-nvim-lsp'})
    use({'hrsh7th/nvim-cmp'})

    use({'lukas-reineke/indent-blankline.nvim'})
    use({'akinsho/bufferline.nvim'})
  end,
  config = {
    compile_path = vim.fn.stdpath('data') .. '/site/plugin/packer_compiled.lua',
  },
})
