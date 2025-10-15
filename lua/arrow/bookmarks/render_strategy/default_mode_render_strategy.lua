local Namespaces = require("arrow.bookmarks.namespaces_enum")
local HighlightGroups = require("arrow.highlight_groups_enum")

local M = {}

function M.apply_highlights(opts)
	local menuBuf = opts.buffer or vim.api.nvim_get_current_buf()

	for i, _ in ipairs(opts.arrows) do
		vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.FILE_INDEX, i, 3, {
			end_col = 4,
			hl_group = HighlightGroups.FILE_INDEX,
		})
	end
end

return M
