local default_mode = require("arrow.strategies.default_mode_strategy")

local M = {}

local current_strategy = default_mode
local menuBuffer = nil

function M.init(strategy, buffer)
	current_strategy = strategy
	menuBuffer = buffer
end

function M.set_strategy(strategy)
	current_strategy = strategy
end

--- Applies the correct mode strategy based on current mode
--- @param opts table
function M.setup_keymaps(opts)
	current_strategy.setup_keymaps(opts, menuBuffer)
end

return M
