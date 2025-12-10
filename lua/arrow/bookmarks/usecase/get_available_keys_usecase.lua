local cache_quiver = require("arrow.persistence.cache_quiver")
local config = require("arrow.config")

local M = {}

function M.get_available_keys()
	local arrows = cache_quiver.fetch_arrows()
	local keys = config.getState("index_keys")

	local taken_lookup = {}
	for _, arrow in ipairs(arrows) do
		taken_lookup[arrow.key] = true
	end

	-- collect free keys
	local keys_lookup = {}
	for key in keys:gmatch(".") do
		if not taken_lookup[key] then
			keys_lookup[key] = true
			-- table.insert(available_keys, key)
		else
			keys_lookup[key] = false
		end
	end

	return keys_lookup
end

return M
