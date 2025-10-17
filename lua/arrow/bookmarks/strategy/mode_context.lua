local render = require("arrow.bookmarks.render")
local default_mode_keymap_strategy = require("arrow.bookmarks.strategy.default_mode_strategy")
local save_mode_keymap_strategy = require("arrow.bookmarks.strategy.save_mode_strategy")
local delete_mode_keymap_strategy = require("arrow.bookmarks.strategy.delete_mode_strategy")
local default_mode_render_strategy = require("arrow.bookmarks.render_strategy.default_mode_render_strategy")
local save_mode_render_strategy = require("arrow.bookmarks.render_strategy.save_mode_render_strategy")
local delete_mode_render_strategy = require("arrow.bookmarks.render_strategy.delete_mode_render_strategy")
local horizontal_mode_render_strategy = require("arrow.bookmarks.render_strategy.horizontal_mode_render_strategy")
local vertical_mode_render_strategy = require("arrow.bookmarks.render_strategy.vertical_mode_render_strategy")

local M = {}

local keymap_strategy = default_mode_keymap_strategy

function M.setup(opts)
	default_mode_keymap_strategy.setup({
		close_menu = opts.close_menu,
		render_buffer = opts.render_buffer,
		render_highlights = M.render_highlights,
	})
	save_mode_keymap_strategy.setup({
		close_menu = opts.close_menu,
		render_buffer = opts.render_buffer,
		render_highlights = M.render_highlights,
	})
	delete_mode_keymap_strategy.setup({
		close_menu = opts.close_menu,
		render_buffer = opts.render_buffer,
		render_highlights = M.render_highlights,
	})
end

function M.toggle_default_mode()
	keymap_strategy = default_mode_keymap_strategy
	render.set_strategy(default_mode_render_strategy)
end

function M.toggle_save_mode()
	keymap_strategy = save_mode_keymap_strategy
	render.set_strategy(save_mode_render_strategy)
end

function M.toggle_delete_mode()
	keymap_strategy = delete_mode_keymap_strategy
	render.set_strategy(delete_mode_render_strategy)
end

function M.toggle_horizontal_mode()
	keymap_strategy = default_mode_keymap_strategy
	render.set_strategy(horizontal_mode_render_strategy)
end

function M.toggle_vertical_mode()
	keymap_strategy = default_mode_keymap_strategy
	render.set_strategy(vertical_mode_render_strategy)
end

function M.set_strategy(strategy)
	keymap_strategy = strategy
end

---Applies the correct mode strategy based on current mode
--- @param opts table
function M.setup_keymaps(opts)
	keymap_strategy.setup_keymaps(opts)
end

---Renders highlights
---@param buffer integer
function M.render_highlights(buffer)
	render.render_highlights(buffer)
end

function M.render_buffer(buffer)
	render.render_buffer(buffer, M.setup_keymaps)
end

return M
