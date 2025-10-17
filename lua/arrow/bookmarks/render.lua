local config = require("arrow.config")
local store = require("arrow.bookmarks.store.state_store")
local icons = require("arrow.integration.icons")
local utils = require("arrow.utils")

local default_mode_render_strategy = require("arrow.bookmarks.render_strategy.default_mode_render_strategy")

local Namespaces = require("arrow.bookmarks.namespaces_enum")
local HighlightGroups = require("arrow.highlight_groups_enum")

local M = {}

local ns_id = vim.api.nvim_create_namespace("arrow")

---@class HighlightStrategyOptions
---@field buffer integer
---@field arrows Arrow[]
---@field actionsMenu string[]

---@class HighlightStrategy
---@field apply_highlights fun(opts: HighlightStrategyOptions)

---@type HighlightStrategy
local render_strategy = default_mode_render_strategy

function M.set_strategy(strategy)
	render_strategy = strategy
end

local function get_actions_menu()
	local mappings = config.getState("mappings")

	if #store.arrows() == 0 then
		return {
			string.format("%s Save File", mappings.toggle),
		}
	end

	local already_saved = store.current_index() > 0

	local separate_save_and_remove = config.getState("separate_save_and_remove")

	local return_mappings = {
		string.format("%s Edit Arrow File", mappings.edit),
		string.format("%s Clear All Items", mappings.clear_all_items),
		string.format("%s Delete Mode", mappings.delete_mode),
		string.format("%s Open Vertical", mappings.open_vertical),
		string.format("%s Open Horizontal", mappings.open_horizontal),
		string.format("%s Next Item", mappings.next_item),
		string.format("%s Prev Item", mappings.prev_item),
		string.format("%s Quit", mappings.quit),
	}

	if separate_save_and_remove then
		table.insert(return_mappings, 1, string.format("%s Remove Current File", mappings.remove))
		table.insert(return_mappings, 1, string.format("%s Save Current File", mappings.toggle))
	else
		if already_saved == true then
			table.insert(return_mappings, 1, string.format("%s Remove Current File", mappings.toggle))
		else
			table.insert(return_mappings, 1, string.format("%s Save Current File", mappings.toggle))
		end
	end

	return return_mappings
end

---comment
---@param buffer any
---@param setup_keymaps function
function M.render_buffer(buffer, setup_keymaps)
	vim.bo[buffer].modifiable = true

	local show_icons = config.getState("show_icons")
	local buf = buffer or vim.api.nvim_get_current_buf()
	local lines = { "" }

	local arrows = store.arrows()
	local filenames = store.filenames()
	local formattedFilenames = utils.format_file_names(filenames)

	store.clear_highlights()
	store.set_current_index(0)

	setup_keymaps({ buf = buf })
	-- mode_context.setup_keymaps({
	-- 	buf = buf,
	-- })

	-- Render arrows
	for i, arrow in ipairs(arrows) do
		vim.highlight.range(buf, ns_id, "ArrowDeleteMode", { i + 3, 0 }, { i + 3, -1 })

		local parsed_filename = filenames[i]
		if parsed_filename:sub(1, 2) == "./" then
			parsed_filename = parsed_filename:sub(3)
		end

		if parsed_filename == vim.b[buf].filename then
			store.set_current_index(i)
		end

		local fileName = formattedFilenames[i]
		if show_icons then
			local icon, hl_group = icons.get_file_icon(filenames[i])
			store.add_highlight(hl_group)
			fileName = icon .. " " .. fileName
		end

		table.insert(lines, string.format("   %s %s", arrow.key, fileName))
	end

	-- Handle empty list
	if #store.arrows() == 0 then
		table.insert(lines, "   No files yet.")
	end

	table.insert(lines, "")

	local actionsMenu = get_actions_menu()
	if not config.getState("hide_handbook") then
		for _, action in ipairs(actionsMenu) do
			table.insert(lines, "   " .. action)
		end
	end

	table.insert(lines, "")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buffer].modifiable = false
	vim.bo[buf].buftype = "nofile"
end

function M.render_highlights(buffer)
	local actionsMenu = get_actions_menu()
	local arrows = store.arrows()
	local current_index = store.current_index()

	vim.api.nvim_buf_clear_namespace(buffer, -1, 0, -1)
	local menuBuf = buffer or vim.api.nvim_get_current_buf()

	local line = vim.api.nvim_buf_get_lines(menuBuf, current_index, current_index + 1, false)[1]
	vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.CURRENT_FILE, current_index, 0, {
		end_col = #line,
		hl_group = HighlightGroups.CURRENT_FILE,
	})

	if config.getState("show_icons") then
		for k, v in pairs(store.highlights()) do
			vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.FILE_INDEX, k, 5, {
				end_col = 8,
				hl_group = v,
			})
		end
	end

	for i = #arrows + 3, #arrows + #actionsMenu + 3 do
		vim.api.nvim_buf_add_highlight(menuBuf, -1, HighlightGroups.ACTION, i - 1, 3, 4)
	end

	local highlight_options = {
		buffer = buffer,
		arrows = arrows,
		actionsMenu = actionsMenu,
	}
	render_strategy.apply_highlights(highlight_options)

	local pattern = " %. .-$"
	local line_number = 1

	while line_number <= #arrows + 1 do
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
