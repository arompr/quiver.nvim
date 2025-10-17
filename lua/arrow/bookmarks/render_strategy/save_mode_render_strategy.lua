local config = require("arrow.config")
local default_render_strategy = require("arrow.bookmarks.render_strategy.default_mode_render_strategy")

local Namespaces = require("arrow.bookmarks.namespaces_enum")
local HighlightGroups = require("arrow.highlight_groups_enum")

local M = {}

---Save mode highlight render strategy
---@param opts HighlightStrategyOptions
function M.apply_highlights(opts)
	local menuBuf = opts.buffer or vim.api.nvim_get_current_buf()
	local mappings = config.getState("mappings")

	default_render_strategy.apply_highlights(opts)

	-- highlight save mode line in actions menu
	for i, action in ipairs(opts.actionsMenu) do
		if action:find(mappings.toggle .. " Save Current File") then
			local line = vim.api.nvim_buf_get_lines(menuBuf, #opts.arrows + i + 1, #opts.arrows + i + 2, false)[1]
			vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.ACTION, #opts.arrows + i + 1, 0, {
				end_col = #line,
				hl_group = HighlightGroups.SAVE_MODE,
			})
		end
	end
end

return M
