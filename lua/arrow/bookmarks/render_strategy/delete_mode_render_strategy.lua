local config = require("arrow.config")
local Namespaces = require("arrow.bookmarks.namespaces_enum")
local HighlightGroups = require("arrow.highlight_groups_enum")

local M = {}

---Delete mode highlight render strategy
---@param opts HighlightStrategyOptions
function M.apply_highlights(opts)
	local menuBuf = opts.buffer or vim.api.nvim_get_current_buf()
	local mappings = config.getState("mappings")

	for i, _ in ipairs(opts.arrows) do
		vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.DELETE_MODE, i, 3, {
			end_col = 4,
			hl_group = HighlightGroups.DELETE_MODE,
		})
	end

	-- highlight delete mode line in actions menu
	for i, action in ipairs(opts.actionsMenu) do
		if action:find(mappings.delete_mode .. " Delete Mode") then
			local line = vim.api.nvim_buf_get_lines(menuBuf, #opts.arrows + i + 1, #opts.arrows + i + 2, false)[1]
			vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.ACTION, #opts.arrows + i + 1, 0, {
				end_col = #line,
				hl_group = HighlightGroups.DELETE_MODE,
			})
		end
	end
end

return M
