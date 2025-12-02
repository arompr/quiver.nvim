local LayoutBuilder = require("arrow.bookmarks.layout.layout_builder")

local M = {}

---@type State
local state = {
	arrows = {},
	arrow_filenames = {},
	highlights = {},
	current_index = 0,
	line_keys = {},
	layout = LayoutBuilder.new(),
	window_config = {},
}

---@param arrows Arrow[]
---@return string[]
local function to_filenames(arrows)
	local arrow_filenames = {}
	for _, arrow in pairs(arrows) do
		table.insert(arrow_filenames, arrow.filename)
	end

	return arrow_filenames
end

function M.set_arrows(new_arrows)
	state.arrows = new_arrows
	state.arrow_filenames = to_filenames(state.arrows)
end

function M.clear_arrows()
	state.arrows = {}
	state.arrow_filenames = {}
end

---@param highlight string
function M.add_highlight(highlight)
	table.insert(state.highlights, highlight)
end

function M.clear_highlights()
	state.highlights = {}
end

---@param index integer
function M.set_current_index(index)
	state.current_index = index
end

---@param new_line_keys string[]
function M.set_line_keys(new_line_keys)
	state.line_keys = new_line_keys
end

function M.set_layout(new_layout)
	state.layout = new_layout
end

function M.set_window_config(new_window_config)
	state.window_config = new_window_config
end

---@return Arrow[]
M.arrows = function()
	return state.arrows
end

---@return LayoutItem[]
M.layout_arrows = function()
	return state.layout.get_items_by_type(LayoutBuilder.TYPE.ARROW)
end

M.filenames = function()
	return state.arrow_filenames
end

M.highlights = function()
	return state.highlights
end

M.current_index = function()
	return state.current_index
end

M.line_keys = function()
	return state.line_keys
end

M.layout = function()
	return state.layout
end

M.window_config = function()
	return state.window_config
end

return M
