local cache_quiver = require("arrow.persistence.cache_quiver")

local M = {}

---@return Arrow[]
function M.get_arrows()
	local arrows = cache_quiver.fetch_arrows()
	local copy = {}
	for i, arrow in ipairs(arrows) do
		copy[i] = arrow
	end
	return copy
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

---Return arrow by key
---@param key string
---@return Arrow|nil
function M.get_arrow_by_key(key)
	local arrow = cache_quiver.fetch_by_key(key)
	if arrow then
		return arrow
	end
	return nil
end

return M
