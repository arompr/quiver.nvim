local store = require("arrow.bookmarks.store.state_store")
local get_arrow_usecase = require("arrow.bookmarks.usecase.get_arrow_usecase")
local config = require("arrow.config")

local M = {}

---@class UIHooksDefaultModeStrategy
---@field close_menu fun()			# Closes the Arrow menu window
---@field render_buffer fun(buf: integer)  	# Renders buffer contents
---@field render_highlights fun(buf: integer) 	# Renders highlights in buffer

---@type UIHooksDefaultModeStrategy | nil
local ui = nil
local action = config.getState("open_action")

---@param opts UIHooksDefaultModeStrategy
function M.setup(opts)
	ui = opts
	action = config.getState("open_action")
end

function M.set_action(new_action)
	action = new_action
end

---@param key string
local function open_file(key)
	if not ui then
		vim.notify("UI hooks not initialized", vim.log.levels.ERROR)
		return
	end

	local arrow = get_arrow_usecase.get_arrow_by_key(key)
	if arrow == nil then
		return
	end
	local filename = arrow.filename

	if not filename then
		print("Invalid file number")

		return
	end

	filename = vim.fn.fnameescape(filename)

	ui.close_menu()
	vim.api.nvim_exec_autocmds("User", { pattern = "ArrowOpenFile" })

	if
		config.getState("global_bookmarks") == true
		or config.getState("save_key_name") == "cwd"
		or config.getState("save_key_name") == "git_root_bare"
	then
		action(filename, vim.b.filename)
	else
		action(config.getState("save_key_cached") .. "/" .. filename, vim.b.filename)
	end
end

--- Setup keymaps for default mode
--- @param opts table
function M.setup_keymaps(opts)
	local buf = opts.buf

	for _, arrow in ipairs(store.arrows()) do
		vim.keymap.set("n", arrow.key, function()
			open_file(arrow.key)
		end, { noremap = true, silent = true, buffer = buf, nowait = true })
	end
end

return M
