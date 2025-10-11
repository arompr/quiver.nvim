local default_mode = require("arrow.strategy.default_mode_strategy")

local M = {}

local current_strategy = default_mode

function M.set_strategy(strategy)
	current_strategy = strategy
end

--- Applies the correct mode strategy based on current mode
--- @param opts table
function M.setup_keymaps(opts)
	current_strategy.setup_keymaps(opts)
end

return M
