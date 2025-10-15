local config = require("arrow.config")
local Namespaces = require("arrow.bookmarks.namespaces_enum")
local HighlightGroups = require("arrow.highlight_groups_enum")

local M = {}

---Open horizontal highlight render strategy
---@param opts HighlightStrategyOptions
function M.apply_highlights(opts)
	local menuBuf = opts.buffer or vim.api.nvim_get_current_buf()
	local mappings = config.getState("mappings")

	for i, _ in ipairs(opts.arrows) do
		vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.FILE_INDEX, i, 3, {
			end_col = 4,
			hl_group = HighlightGroups.FILE_INDEX,
		})
	end

	-- highlight vertical mode line in actions menu
	for i, action in ipairs(opts.actionsMenu) do
		if action:find(mappings.open_horizontal .. " Horizontal Mode") then
			vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.ACTION, #opts.arrows + i + 1, 0, {
				end_col = -1,
				hl_group = HighlightGroups.ACTION,
			})
		end
	end
end

return M
