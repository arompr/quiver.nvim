local default_render_strategy = require("arrow.bookmarks.render_strategy.default_mode_render_strategy")

local Namespaces = require("arrow.bookmarks.namespaces_enum")
local HighlightGroups = require("arrow.highlight_groups_enum")
local MenuItems = require("arrow.menu_items")

local M = {}

---Open vertical highlight render strategy
---@param opts HighlightStrategyOptions
function M.apply_highlights(opts)
	local menuBuf = opts.buffer or vim.api.nvim_get_current_buf()

	default_render_strategy.apply_highlights(opts)

	-- highlight vertical mode line in actions menu
	for _, action in ipairs(opts.actionsMenu) do
		if action.key == MenuItems.OPEN_VERTICAL.id then
			local line = vim.api.nvim_buf_get_lines(menuBuf, action.line, action.line + 1, false)[1]
			vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.ACTION, action.line, 0, {
				end_col = #line,
				hl_group = HighlightGroups.ACTION,
			})
		end
	end
end

return M
