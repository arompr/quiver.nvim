local default_mode = require("arrow.bookmarks.strategy.default_mode_strategy")

local M = {}

local keymap_strategy = default_mode

function M.set_strategy(strategy)
	keymap_strategy = strategy
end

--- Applies the correct mode strategy based on current mode
--- @param opts table
function M.setup_keymaps(opts)
	keymap_strategy.setup_keymaps(opts)
end

return M
