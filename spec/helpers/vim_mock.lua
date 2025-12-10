-- spec/helpers/vim_mock.lua
---@diagnostic disable: undefined-field

local function setup_vim_mock()
	_G.vim = {
		api = {
			nvim_exec_autocmds = function() end,
			nvim_create_buf = function()
				return 1
			end,
			nvim_buf_set_lines = function() end,
			nvim_open_win = function()
				return 1
			end,
			nvim_buf_set_keymap = function() end,
		},
		fn = {
			isdirectory = function()
				return 1
			end,
			mkdir = function() end,
			filereadable = function()
				return 0
			end,
			readfile = function()
				return {}
			end,
			writefile = function() end,
			join = function(t, sep)
				return table.concat(t, sep)
			end,
			split = function(s, sep)
				-- use Lua's gmatch instead of vim.split to avoid recursion
				local result = {}
				for part in string.gmatch(s, "([^" .. sep .. "]+)") do
					table.insert(result, part)
				end
				return result
			end,
			winwidth = function()
				return 100
			end,
			fnameescape = function(s)
				return s
			end,
		},
		cmd = function(_) end,
		keymap = {
			set = function() end,
		},
		o = {
			lines = 30,
			columns = 100,
		},
	}
end

return setup_vim_mock
