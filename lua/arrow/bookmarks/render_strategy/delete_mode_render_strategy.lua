local config = require("arrow.config")
local Namespaces = require("arrow.bookmarks.namespaces_enum")
local HighlightGroups = require("arrow.highlight_groups_enum")
local Style = require("arrow.bookmarks.style")
local MenuItems = require("arrow.menu_items")

local M = {}

---Delete mode highlight render strategy
---@param opts HighlightStrategyOptions
function M.apply_highlights(opts)
	local menuBuf = opts.buffer or vim.api.nvim_get_current_buf()

	local col = #Style.Padding.m

	for _, arrow in ipairs(opts.arrows) do
		vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.DELETE_MODE, arrow.line, col, {
			end_col = col + 1,
			hl_group = HighlightGroups.DELETE_MODE,
		})
	end

	-- highlight delete mode line in actions menu
	for _, action in ipairs(opts.actionsMenu) do
		if action.key == MenuItems.DELETE.id then
			local line = vim.api.nvim_buf_get_lines(menuBuf, action.line, action.line + 1, false)[1]
			vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.ACTION, action.line, 0, {
				end_col = #line,
				hl_group = HighlightGroups.DELETE_MODE,
			})
		end
	end
end

return M
