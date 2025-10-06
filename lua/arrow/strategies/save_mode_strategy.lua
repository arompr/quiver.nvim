local save_arrow_usecase = require("arrow.usecases.save_arrow_usecase")
local config = require("arrow.config")

local M = {}

--- Setup keymaps for save mode
--- @param opts table
function M.setup_keymaps(opts)
	local buf = opts.buf
	local assignable_keys = config.getState("index_keys")

	for key in assignable_keys:gmatch(".") do
		vim.keymap.set("n", key, function()
			local file = vim.b[buf].filename
			save_arrow_usecase.save_arrow(key, file)
			vim.g.global = ""
			local win = vim.fn.win_getid()
			vim.api.nvim_win_close(win, true)
		end, { noremap = true, silent = true, buffer = buf, nowait = true })
	end
end

return M
