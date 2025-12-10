local default_render_strategy = require("arrow.bookmarks.render_strategy.default_mode_render_strategy")
local store = require("arrow.bookmarks.store.state_store")

local get_available_keys_usecase = require("arrow.bookmarks.usecase.get_available_keys_usecase")

local Namespaces = require("arrow.bookmarks.namespaces_enum")
local HighlightGroups = require("arrow.highlight_groups_enum")
local Style = require("arrow.bookmarks.style")
local Padding = Style.Padding
local MenuItems = require("arrow.menu_items")
local LayoutBuilder = require("arrow.bookmarks.layout.layout_builder")

local M = {}

---Save mode highlight render strategy
---@param opts HighlightStrategyOptions
function M.apply_highlights(opts)
	local menuBuf = opts.buffer or vim.api.nvim_get_current_buf()

	default_render_strategy.apply_highlights(opts)

	-- highlight save mode line in actions menu
	for _, action in ipairs(opts.actionsMenu) do
		if action.key == MenuItems.SAVE.id then
			local line = vim.api.nvim_buf_get_lines(menuBuf, action.line, action.line + 1, false)[1]
			vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.ACTION, action.line, 0, {
				end_col = #line,
				hl_group = HighlightGroups.SAVE_MODE,
			})
		end
	end

	-- highlight available keys
	-- local keys_lookup = get_available_keys_usecase.get_available_keys()
	-- local line_keys = store.layout().get_items_by_type(LayoutBuilder.TYPE.LINE_KEY)
	-- for _, line_key in ipairs(line_keys) do
	-- 	local buf_line = vim.api.nvim_buf_get_lines(menuBuf, line_key.line, line_key.line + 1, false)[1]
	--
	-- 	if buf_line then
	-- 		for col = 1, #line_key.label do
	-- 			local key = line_key.label:sub(col, col)
	-- 			if keys_lookup[key] then
	-- 				local start_col = #Padding.m + (col - 1)
	-- 				local end_col = start_col + 1
	--
	-- 				-- clamp end_col to line length
	-- 				if start_col < #buf_line then
	-- 					if end_col > #buf_line then
	-- 						end_col = #buf_line
	-- 					end
	--
	-- 					vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.ACTION, line_key.line, start_col, {
	-- 						end_col = end_col,
	-- 						hl_group = HighlightGroups.SAVE_MODE,
	-- 					})
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end

	local keys_lookup = get_available_keys_usecase.get_available_keys()
	local line_keys = store.layout().get_items_by_type(LayoutBuilder.TYPE.LINE_KEY)

	for _, line_key in ipairs(line_keys) do
		local buf_line = vim.api.nvim_buf_get_lines(menuBuf, line_key.line, line_key.line + 1, false)[1]

		if buf_line then
			for col = 1, #line_key.label do
				local key = line_key.label:sub(col, col)
				local start_col = #Padding.m + (col - 1)
				local end_col = start_col + 1

				-- clamp end_col to line length
				if start_col < #buf_line then
					if end_col > #buf_line then
						end_col = #buf_line
					end

					if keys_lookup[key] then
						vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.ACTION, line_key.line, start_col, {
							end_col = end_col,
							hl_group = HighlightGroups.SAVE_MODE,
						})
					else
						vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.DELETE_MODE, line_key.line, start_col, {
							end_col = end_col,
							hl_group = HighlightGroups.DELETE_MODE,
						})
					end
				end
			end
		end
	end
end

return M
