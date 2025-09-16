---@class Bookmark
---@field filename string

local utils = require("arrow.utils")
local config = require("arrow.config")

local M = {}

---@type Bookmark[]
local arrow_filenames = {}

function M.build(filenames)
	arrow_filenames = filenames
end

function M.save(filename)
	if not M.is_saved(filename) then
		table.insert(arrow_filenames, filename)
	end
end

function M.remove(index)
	table.remove(arrow_filenames, index)
end

-- Normalize filenames according to config
local function normalize_filename(filename)
	if config.getState("relative_path") and not config.getState("global_bookmarks") then
		if not filename:match("^%./") and not utils.string_contains_whitespace(filename) then
			return "./" .. filename
		end
	end
	return filename
end

-- Check if a filename is saved, return its index or nil
function M.is_saved(filename)
	for i, name in ipairs(arrow_filenames) do
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
	arrow_filenames = {}
end

-- Expose a read-only copy
function M.get_all()
	local copy = {}
	for i, entry in ipairs(arrow_filenames) do
		copy[i] = entry
	end
	return copy
end

function M.fetch_by_index(index)
	return arrow_filenames[index]
end

return M
