local in_memory_quiver = require("arrow.persistence.in_memory_storage")
local file_quiver = require("arrow.persistence.file_storage")

local M = {}

function M.save(arrow)
	in_memory_quiver.save(arrow)
end

function M.fetch_arrows()
	local in_memory_arrows = in_memory_quiver.fetch_arrows()

	if next(in_memory_arrows) ~= nil then
		return in_memory_arrows
	end

	local in_file_arrows = file_quiver.fetch_arrows()
	in_memory_quiver.set_arrows(in_file_arrows)

	return in_file_arrows
end

function M.remove(arrow)
	in_memory_quiver.remove(arrow)
end

function M.clear_arrows()
	in_memory_quiver.clear()
end

function M.persist_arrows()
	file_quiver.save_arrows(in_memory_quiver.fetch_arrows())
end

function M.fetch_by_index(index)
	return M.fetch_arrows()[index]
end

return M
