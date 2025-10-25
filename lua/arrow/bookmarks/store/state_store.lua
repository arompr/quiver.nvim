local cache_quiver = require("arrow.persistence.cache_quiver")

local M = {}

---@class WindowConfig
---@field col integer
---@field height integer
---@field row integer
---@field width integer

---@return WindowConfig
local function new_window_config()
	return { col = 0, height = 0, row = 0, width = 0 }
end

---@class State
---@field arrows Arrow[]		# List of arrows in memory
---@field arrow_filenames string[]	# Corresponding filenames
---@field highlights string[]		# Highlight info
---@field current_index integer		# Currently selected index
---@field current_window_config WindowConfig	# Current quiver window config
---@field line_keys string[]
---@type State
local state = {
	arrows = {},
	arrow_filenames = {},
	highlights = {},
	current_index = 0,
	current_window_config = new_window_config(),
	line_keys = {},
}

local function to_filenames(arrows)
	local arrow_filenames = {}
	for _, value in pairs(arrows) do
		table.insert(arrow_filenames, value.filename)
	end

	return arrow_filenames
end

function M.load_arrows()
	if #state.arrows == 0 then
		M.refresh_arrows()
	end
end

function M.refresh_arrows()
	state.arrows = cache_quiver.fetch_arrows()
	state.arrow_filenames = to_filenames(state.arrows)
end

---@param arrows Arrow[]
function M.set_arrows(arrows)
	state.arrows = arrows
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

---@param window_config WindowConfig
function M.set_window_config(window_config)
	state.current_window_config = window_config
end

---@param new_line_keys string[]
function M.set_line_keys(new_line_keys)
	state.line_keys = new_line_keys
end

M.arrows = function()
	return state.arrows
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

M.window_config = function()
	return state.current_window_config
end

M.line_keys = function()
	return state.line_keys
end

return M
