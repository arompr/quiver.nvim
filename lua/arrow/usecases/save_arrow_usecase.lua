local cache_quiver = require("arrow.persistence.cache_quiver")
local events = require("arrow.events")

local M = {}

function M.save_arrow(key, filename)
	print("save_arrow_usecase key: " .. key)
	print("save_arrow_usecase filename: " .. filename)
	cache_quiver.save({ key = key, filename = filename })
	cache_quiver.persist_arrows()
	events.notify()
end

return M
