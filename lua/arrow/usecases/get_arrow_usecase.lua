local cache_quiver = require("arrow.persistence.cache_quiver")

local M = {}

---Return only filenames
---@return string[]
function M.get_arrows()
	local arrows = cache_quiver.fetch_arrows()
	local filenames = {}
	for i, arrow in ipairs(arrows) do
		filenames[i] = arrow.filename
	end
	return filenames
end

---Return filename by index
---@param index integer
---@return string|nil
function M.get_arrow_by_index(index)
	local arrow = cache_quiver.fetch_by_index(index)
	if arrow then
		return arrow.filename
	end
	return nil
end

return M
