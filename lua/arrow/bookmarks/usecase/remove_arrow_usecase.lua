local cache_quiver = require("arrow.persistence.cache_quiver")
local store = require("arrow.bookmarks.store.state_store")
local events = require("arrow.events")

local M = {}

function M.remove_arrow(filename)
	local arrow = cache_quiver.fetch_by_filename(filename)
	if arrow then
		cache_quiver.remove(arrow)
		cache_quiver.persist_arrows()
		events.notify()
	end
end

return M
