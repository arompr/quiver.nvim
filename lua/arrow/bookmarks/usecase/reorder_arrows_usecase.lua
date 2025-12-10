local cache_quiver = require("arrow.persistence.cache_quiver")

local M = {}

---Reorders arrows based on the order of filenames in the 'filenames' list
---@param filenames string[]
function M.reorder(filenames)
	local arrows = cache_quiver.fetch_arrows()

	local lookup = {}
	for _, arrow in ipairs(arrows) do
		lookup[arrow.filename] = arrow
	end

	-- Build a new table in the desired order
	local reordered = {}
	for _, filename in ipairs(filenames) do
		if lookup[filename] then
			table.insert(reordered, lookup[filename])
		end
	end

	cache_quiver.set(reordered)
	cache_quiver.persist_arrows()
	return reordered
end

return M
