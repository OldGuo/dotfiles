local builtin = require('telescope.builtin')

local function live_grep_project()
	builtin.live_grep({
		additional_args = function()
			return { '--hidden', '--glob', '!.git' }
		end,
	})
end

vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>/', live_grep_project, { desc = 'Telescope live grep (project)' })
vim.keymap.set('n', '<leader>ps', function()
	builtin.grep_string({ search = vim.fn.input('Grep > ') })
end, { desc = 'Telescope grep prompt' })
