local cache_quiver = require("arrow.persistence.cache_quiver")
local events = require("arrow.events")

local M = {}

function M.clear()
	cache_quiver.clear_arrows()
	cache_quiver.persist_arrows()
	events.notify()
end

return M
