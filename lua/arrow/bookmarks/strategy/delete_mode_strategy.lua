local store = require("arrow.bookmarks.store.state_store")
local get_arrow_usecase = require("arrow.bookmarks.usecase.get_arrow_usecase")
local remove_arrow_usecase = require("arrow.bookmarks.usecase.remove_arrow_usecase")

local M = {}

---@class UIHooksDeleteModeStrategy
---@field render_buffer fun(buf: integer)  	# Renders buffer contents
---@field render_highlights fun(buf: integer) 	# Renders highlights in buffer

---@type UIHooksDeleteModeStrategy | nil
local ui = nil

---@param opts UIHooksDeleteModeStrategy
function M.setup(opts)
	ui = opts
end

---@param key string
local function delete_file(key)
	if not ui then
		vim.notify("UI hooks not initialized", vim.log.levels.ERROR)
		return
	end

	local arrow = get_arrow_usecase.get_arrow_by_key(key)
	if arrow == nil then
		return
	end
	local filename = arrow.filename

	remove_arrow_usecase.remove_arrow(filename)

	ui.render_buffer(vim.api.nvim_get_current_buf())
	ui.render_highlights(vim.api.nvim_get_current_buf())
end

--- Setup keymaps for delete mode
--- @param opts table
function M.setup_keymaps(opts)
	local buf = opts.buf

	for _, arrow in ipairs(store.arrows()) do
		vim.keymap.set("n", arrow.key, function()
			delete_file(arrow.key)
		end, { noremap = true, silent = true, buffer = buf, nowait = true })
	end
end

return M
