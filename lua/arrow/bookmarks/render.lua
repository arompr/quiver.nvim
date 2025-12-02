local config = require("arrow.config")
local store = require("arrow.bookmarks.store.state_store")
local icons = require("arrow.integration.icons")
local ui_utils = require("arrow.bookmarks.ui_utils")
local default_mode_render_strategy = require("arrow.bookmarks.render_strategy.default_mode_render_strategy")
local get_arrow_usecase = require("arrow.bookmarks.usecase.get_arrow_usecase")
local LayoutBuilder = require("arrow.bookmarks.layout.layout_builder")

local Namespaces = require("arrow.bookmarks.namespaces_enum")
local HighlightGroups = require("arrow.highlight_groups_enum")
local Style = require("arrow.bookmarks.style")
local MenuItems = require("arrow.menu_items")

local M = {}

---@class HighlightStrategyOptions
---@field buffer integer
---@field arrows LayoutArrow[]
---@field actionsMenu LayoutItem[]

---@class HighlightStrategy
---@field apply_highlights fun(opts: HighlightStrategyOptions)

---@type HighlightStrategy
local render_strategy = default_mode_render_strategy

function M.set_strategy(strategy)
	render_strategy = strategy
end

function M.create_layout()
	local arrows = get_arrow_usecase.get_arrows()

	local layout = LayoutBuilder.new()
	layout.add_breakline()
	for _, arrow in ipairs(arrows) do
		local parsed_filename = arrow.filename
		if parsed_filename:sub(1, 2) == "./" then
			parsed_filename = parsed_filename:sub(3)
		end

		local fileName = ui_utils.format_filename(arrow.filename)

		layout.add_arrow(fileName, arrow.key)
	end

	layout.add_breakline()

	if not config.getState("hide_handbook") then
		layout
			.add_menu(MenuItems.SAVE.label, MenuItems.SAVE.id)
			.add_menu(MenuItems.REMOVE.label, MenuItems.REMOVE.id)
			.add_menu(MenuItems.EDIT.label, MenuItems.EDIT.id)
			.add_menu(MenuItems.CLEAR_ALL.label, MenuItems.CLEAR_ALL.id)
			.add_menu(MenuItems.DELETE.label, MenuItems.DELETE.id)
			.add_menu(MenuItems.OPEN_VERTICAL.label, MenuItems.OPEN_VERTICAL.id)
			.add_menu(MenuItems.OPEN_HORIZONTAL.label, MenuItems.OPEN_HORIZONTAL.id)
			.add_menu(MenuItems.NEXT_ITEM.label, MenuItems.NEXT_ITEM.id)
			.add_menu(MenuItems.PREV_ITEM.label, MenuItems.PREV_ITEM.id)
			.add_menu(MenuItems.QUIT.label, MenuItems.QUIT.id)

		layout.add_breakline()

		layout.add_title("Keys")
		local line_keys = store.line_keys()
		for index, value in ipairs(line_keys) do
			local key = "line_key_" .. index
			layout.add_line_key(value, key)
		end
	end

	return layout
end

---@param buffer integer
---@param setup_keymaps function
function M.render_from_layout(buffer, setup_keymaps)
	local mappings = config.getState("mappings")
	vim.bo[buffer].modifiable = true
	local buf = buffer or vim.api.nvim_get_current_buf()

	local show_icons = config.getState("show_icons")

	local layout = M.create_layout()
	store.set_layout(layout)
	local items = layout.get_all_items()

	local lines = {}

	store.clear_highlights()
	store.set_current_index(0)

	for _, item in ipairs(items) do
		local line = ""

		if item.type == LayoutBuilder.TYPE.ARROW then
			-- Detect current file
			local current_filename = vim.b[buf].filename
			local arrow = get_arrow_usecase.get_arrow_by_key(item.key)
			if arrow ~= nil and current_filename == arrow.filename then
				store.set_current_index(item.line)
			end

			local display = ui_utils.truncate_keep_ext_progressive(item.label, 32 - (2 * #Style.Padding.m))

			if show_icons then
				local icon, hl = icons.get_file_icon(item.label)
				store.add_highlight(hl)
				display = icon .. " " .. display
			end

			line = string.format("%s%s %s", Style.Padding.m, item.key, display)
		elseif item.type == LayoutBuilder.TYPE.MENU then
			line = string.format("%s%s %s", Style.Padding.m, mappings[item.key], item.label)
		elseif item.type == LayoutBuilder.TYPE.LINE_KEY then
			line = Style.Padding.m .. item.label
		elseif item.type == LayoutBuilder.TYPE.TITLE then
			line = Style.Padding.m .. item.label
		elseif item.type == LayoutBuilder.TYPE.EMPTY then
			line = ""
		end

		table.insert(lines, line)
	end

	-- Write lines to buffer
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buffer].modifiable = false
	vim.bo[buf].buftype = "nofile"

	-- Now highlights can be applied based on the layout
	render_strategy.apply_highlights({
		buffer = buf,
		arrows = layout.get_items_by_type(LayoutBuilder.TYPE.ARROW),
		actionsMenu = layout.get_items_by_type(LayoutBuilder.TYPE.MENU),
	})

	setup_keymaps({ buf = buf })
end

---@param buffer any
---@param setup_keymaps function
function M.render_buffer(buffer, setup_keymaps)
	M.render_from_layout(buffer, setup_keymaps)
end

function M.render_highlights(buffer)
	local menuItems = store.layout().get_items_by_type(LayoutBuilder.TYPE.MENU)
	local layout_arrows = store.layout_arrows()
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
			vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.FILE_INDEX, k, #Style.Padding.m + 2, {
				end_col = #Style.Padding.m + 5,
				hl_group = v,
			})
		end
	end

	for _, menuItem in ipairs(menuItems) do
		vim.api.nvim_buf_set_extmark(menuBuf, Namespaces.ACTION, menuItem.line, #Style.Padding.m, {
			end_row = menuItem.line,
			end_col = #Style.Padding.m + 1,
			hl_group = HighlightGroups.ACTION,
			hl_mode = "combine",
		})
	end

	render_strategy.apply_highlights({
		buffer = buffer,
		arrows = layout_arrows,
		actionsMenu = menuItems,
	})

	local pattern = " %. .-$"
	local line_number = 1

	while line_number <= #layout_arrows + 1 do
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
