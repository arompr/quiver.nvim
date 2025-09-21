local M = {}

local cache_quiver = require("arrow.persistence.cache_quiver")
local events = require("arrow.events")

function M.save_arrow(filename)
	cache_quiver.save(filename)
	cache_quiver.persist_arrows()
	events.notify()
end

return M
