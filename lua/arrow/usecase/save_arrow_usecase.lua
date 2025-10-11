local cache_quiver = require("arrow.persistence.cache_quiver")
local store = require("arrow.store.state_store")
local events = require("arrow.events")

local M = {}

function M.save_arrow(key, filename)
	local existing_arrow = cache_quiver.fetch_by_key(key)

	if existing_arrow ~= nil then
		print(filename .. " already mapped to key " .. key)
	else
		cache_quiver.save({ key = key, filename = filename })
		cache_quiver.persist_arrows()
		store.set_arrows(cache_quiver.fetch_arrows())
		events.notify()
	end
end

return M
