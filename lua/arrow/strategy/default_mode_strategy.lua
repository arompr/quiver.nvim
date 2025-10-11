local store = require("arrow.store.state_store")
local get_arrow_usecase = require("arrow.usecase.get_arrow_usecase")
local remove_arrow_usecase = require("arrow.usecase.remove_arrow_usecase")
local config = require("arrow.config")

local M = {}

---@class UIHooksSaveModeStrategy
---@field close_menu fun()			# Closes the Arrow menu window
---@field render_buffer fun(buf: integer)  	# Renders buffer contents
---@field render_highlights fun(buf: integer) 	# Renders highlights in buffer

---@type UIHooksSaveModeStrategy | nil
local ui = nil

function M.setup(opts)
	ui = opts
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

	if vim.b.arrow_current_mode == "delete_mode" then
		remove_arrow_usecase.remove_arrow(filename)

		ui.render_buffer(vim.api.nvim_get_current_buf())
		ui.render_highlights(vim.api.nvim_get_current_buf())
	else
		if not filename then
			print("Invalid file number")

			return
		end

		local action

		filename = vim.fn.fnameescape(filename)

		if vim.b.arrow_current_mode == "" or not vim.b.arrow_current_mode then
			action = config.getState("open_action")
		elseif vim.b.arrow_current_mode == "vertical_mode" then
			action = config.getState("vertical_action")
		elseif vim.b.arrow_current_mode == "horizontal_mode" then
			action = config.getState("horizontal_action")
		end

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
