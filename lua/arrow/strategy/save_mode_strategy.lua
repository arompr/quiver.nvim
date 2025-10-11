local save_arrow_usecase = require("arrow.usecase.save_arrow_usecase")
local config = require("arrow.config")

local M = {}

---@class UIHooksSaveModeStrategy
---@field closeMenu fun()			# Closes the Arrow menu window
---@field renderBuffer fun(buf: integer)  	# Renders buffer contents
---@field renderHighlights fun(buf: integer) 	# Renders highlights in buffer

---@type UIHooksSaveModeStrategy | nil
local ui = nil

function M.setup(opts)
	ui = opts
end

--- Setup keymaps for save mode
--- @param opts table
function M.setup_keymaps(opts)
	if not ui then
		vim.notify("UI hooks not initialized", vim.log.levels.ERROR)
		return
	end

	local buf = opts.buf
	local assignable_keys = config.getState("index_keys")
	for key in assignable_keys:gmatch(".") do
		vim.keymap.set("n", key, function()
			local file = vim.b[buf].filename
			save_arrow_usecase.save_arrow(key, file)

			ui.close_menu()
		end, { noremap = true, silent = true, buffer = buf, nowait = true })
	end
end

return M
