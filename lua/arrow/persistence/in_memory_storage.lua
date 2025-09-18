---@class Bookmark
---@field filename string

local utils = require("arrow.utils")
local config = require("arrow.config")

local M = {}

---@type Bookmark[]
local in_memory_arrows = {}

function M.set_arrows(arrows)
	arrows = arrows
end

---@param arrow Bookmark
function M.save(arrow)
	if not M.is_saved(arrow) then
		table.insert(in_memory_arrows, arrow)
	end
end

function M.remove(arrow)
	local index = M.is_saved(arrow)
	if index then
		M.remove_at(index)
	end
end

function M.remove_at(index)
	table.remove(in_memory_arrows, index)
end

-- Check if a filename is saved, return its index or nil
function M.is_saved(filename)
	for i, name in ipairs(in_memory_arrows) do
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
