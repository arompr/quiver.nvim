local config = require("arrow.config")
local store = require("arrow.bookmarks.store.state_store")
local icons = require("arrow.integration.icons")
local ui_utils = require("arrow.bookmarks.ui_utils")
local default_mode_render_strategy = require("arrow.bookmarks.render_strategy.default_mode_render_strategy")
local get_arrow_usecase = require("arrow.bookmarks.usecase.get_arrow_usecase")
local LayoutBuilder = require("arrow.bookmarks.layout.layout_builder")

local Style = require("arrow.bookmarks.style")
local MenuItems = require("arrow.menu_items")

local M = {}

---@class HighlightStrategyOptions
---@field buffer integer
---@field arrows LayoutItem[]
---@field actionsMenu LayoutItem[]

---@class HighlightStrategy
---@field apply_highlights fun(opts: HighlightStrategyOptions)

---@type HighlightStrategy
local render_strategy = default_mode_render_strategy

function M.set_strategy(strategy)
	render_strategy = strategy
end

local function add_keys_section(layout)
	layout.add_title("Keys")
	local available_width = config.getState("window").width - (2 * #Style.Padding.m)
	local wrapped_line_keys = ui_utils.wrap_str_to_length(config.getState("index_keys"), available_width)
	store.set_line_keys(wrapped_line_keys)
	for index, value in ipairs(wrapped_line_keys) do
		local key = "line_key_" .. index
		layout.add_line_key(value, key)
	end
	layout.add_breakline()
	return layout
end

local function add_handbook_menu(layout)
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
	return layout
end

local function new_empty_layout()
	local layout = LayoutBuilder.new()
	layout.add_breakline().add_title("No files yet.").add_breakline()

	if not config.getState("hide_handbook") then
		layout.add_menu(MenuItems.SAVE.label, MenuItems.SAVE.id).add_menu(MenuItems.QUIT.label, MenuItems.QUIT.id)
	end

	layout.add_breakline()

	return add_keys_section(layout)
end

function M.create_layout()
	local arrows = get_arrow_usecase.get_arrows()

	if #arrows == 0 then
		return new_empty_layout()
	end

	local layout = LayoutBuilder.new()
	layout.add_breakline()
	for _, arrow in ipairs(arrows) do
		local parsed_filename = arrow.filename
		layout.add_arrow(parsed_filename, arrow.key)
	end

	layout.add_breakline()

	if not config.getState("hide_handbook") then
		add_handbook_menu(layout)
	end

	if config.getState("show_keys") then
		add_keys_section(layout)
	end

	return layout
end

---@param buffer integer
---@param setup_keymaps function
function M.render_from_layout(buffer, setup_keymaps)
	local mappings = config.getState("mappings")
	vim.bo[buffer].modifiable = true
	local buf = buffer or vim.api.nvim_get_current_buf()
	local width = config.getState("window").width

	local show_icons = config.getState("show_icons")

	local layout = M.create_layout()
	store.set_layout(layout)
	local items = layout.get_all_items()

	local lines = {}

	store.clear_highlights()
	store.set_current_index(0)
	store.clear_path_highlights()

	for _, item in ipairs(items) do
		local line = ""

		if item.type == LayoutBuilder.TYPE.ARROW then
			-- Detect current file
			local current_filename = vim.b[buf].filename
			local arrow = get_arrow_usecase.get_arrow_by_key(item.key)
			if arrow ~= nil and current_filename == arrow.filename then
				store.set_current_index(item.line)
			end

			local filename, path = ui_utils.split_filepath(item.label)

			local prefix = Style.Padding.m .. item.key .. " "
			local prefix_len = #prefix

			local icon_len = 0
			if show_icons then
				local icon = icons.get_file_icon(item.label)
				icon_len = vim.fn.strdisplaywidth(icon) + 1
			end

			local display, path_start, path_end =
				ui_utils.truncate_left(filename, path, width - (prefix_len + icon_len + #Style.Padding.m))
			path_start = path_start + prefix_len
			path_end = path_end + prefix_len

			if show_icons then
				local icon, hl = icons.get_file_icon(item.label)
				store.add_highlight(hl)
				display = icon .. " " .. display
				icon_len = #icon + 1

				path_start = path_start + icon_len
				path_end = path_end + icon_len
			end

			line = prefix .. display
			store.add_path_highlight(item.line, path_start, path_end)
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

	vim.api.nvim_buf_clear_namespace(buffer, -1, 0, -1)

	default_mode_render_strategy.apply_highlights({
		buffer = buffer,
		arrows = layout_arrows,
		actionsMenu = menuItems,
	})
	render_strategy.apply_highlights({
		buffer = buffer,
		arrows = layout_arrows,
		actionsMenu = menuItems,
	})
end

return M
