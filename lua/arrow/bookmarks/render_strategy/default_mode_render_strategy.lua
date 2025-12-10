local config = require("arrow.config")
local store = require("arrow.bookmarks.store.state_store")

local Namespaces = require("arrow.bookmarks.namespaces_enum")
local HighlightGroups = require("arrow.highlight_groups_enum")
local Style = require("arrow.bookmarks.style")

local M = {}

---Default mode highlight render strategy
---@param opts HighlightStrategyOptions
function M.apply_highlights(opts)
	local menuBuf = opts.buffer or vim.api.nvim_get_current_buf()

	local current_index = store.current_index()
	local line = vim.api.nvim_buf_get_lines(menuBuf, current_index, current_index + 1, false)[1]
	vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.CURRENT_FILE, current_index, 0, {
		end_col = #line,
		hl_group = HighlightGroups.CURRENT_FILE,
	})

	if config.getState("show_icons") then
		for k, v in pairs(store.highlights()) do
			vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.FILE_INDEX, k, #Style.Padding.m + 2, {
				end_col = #Style.Padding.m + 5,
				hl_group = v,
			})
		end
	end

	for _, menuItem in ipairs(store.layout_menu_items()) do
		vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.ACTION, menuItem.line, #Style.Padding.m, {
			end_row = menuItem.line,
			end_col = #Style.Padding.m + 1,
			hl_group = HighlightGroups.ACTION,
			hl_mode = "combine",
		})
	end

	for _, hl in ipairs(store.path_highlights()) do
		vim.api.nvim_buf_set_extmark(opts.buffer, Namespaces.ACTION, hl.line, hl.start_col, {
			end_col = hl.end_col,
			hl_group = HighlightGroups.PATH,
			hl_mode = "combine",
		})
	end

	local pattern = " %. .-$"
	local line_number = 1
	while line_number <= #store.layout_arrows() + 1 do
		local line_content = vim.api.nvim_buf_get_lines(menuBuf, line_number - 1, line_number, false)[1]

		local match_start, match_end = string.find(line_content, pattern)
		if match_start and match_end then
			vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.ACTION, line_number - 1, match_start - 1, {
				end_col = match_end,
				hl_group = HighlightGroups.ACTION,
			})
		end
		line_number = line_number + 1
	end
end

return M
