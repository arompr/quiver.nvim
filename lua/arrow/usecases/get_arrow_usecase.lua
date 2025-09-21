local M = {}

local cache_quiver = require("arrow.persistence.cache_quiver")

function M.get_arrows()
	return cache_quiver.fetch_arrows()
end

function M.get_arrow_by_index(index)
	return cache_quiver.fetch_by_index(index)
end

return M
