---@class Arrow
---@field key string
---@field filename string

local utils = require("arrow.utils")
local config = require("arrow.config")

local M = {}

---@type Arrow[]
local in_memory_arrows = {}

---@param arrows Arrow[]
function M.set_arrows(arrows)
	in_memory_arrows = arrows
end

---@param arrow Arrow
function M.save(arrow)
	print("in_memory_arrows arrow.key: " .. vim.inspect(arrow))
	if not M.get_index(arrow.filename) then
		-- local key = tostring(#in_memory_arrows + 1)
		print("in_memory_arrows arrow.key: " .. arrow.key)
		print("in_memory_arrows arrow.filename: " .. arrow.filename)
		table.insert(in_memory_arrows, { key = arrow.key, filename = arrow.filename })
	end
end

---@param arrow Arrow
function M.remove(arrow)
	local index = M.get_index(arrow.filename)
	if index then
		M.remove_at(index)
	end
end

function M.remove_at(index)
	table.remove(in_memory_arrows, index)
end

function M.get_index(filename)
	for i, arrow in ipairs(in_memory_arrows) do
		local name = arrow.filename

		if config.getState("relative_path") == true and config.getState("global_bookmarks") == false then
			if not name:match("^%./") and not utils.string_contains_whitespace(name) then
				name = "./" .. name
			end

			if not filename:match("^%./") and not utils.string_contains_whitespace(filename) then
				filename = "./" .. filename
			end
		end

		if name == filename then
			return i
		end
	end
	return nil
end

function M.clear()
	in_memory_arrows = {}
end

-- Expose a read-only copy
function M.fetch_arrows()
	local copy = {}
	for i, entry in ipairs(in_memory_arrows) do
		copy[i] = entry
	end
	return copy
end

function M.fetch_by_index(index)
	return in_memory_arrows[index]
end

return M
