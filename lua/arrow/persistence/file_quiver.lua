local config = require("arrow.config")
local utils = require("arrow.utils")
local git = require("arrow.git")

local M = {}

local function save_key()
	if config.getState("global_bookmarks") == true then
		return "global.json"
	end

	if config.getState("separate_by_branch") then
		local branch = git.refresh_git_branch()

		if branch then
			return utils.normalize_path_to_filename(config.getState("save_key_cached") .. "-" .. branch) .. ".json"
		end
	end

	return utils.normalize_path_to_filename(config.getState("save_key_cached")) .. ".json"
end

local function cache_file_path()
	local save_path = config.getState("save_path")()

	save_path = save_path:gsub("/$", "")

	if vim.fn.isdirectory(save_path) == 0 then
		vim.fn.mkdir(save_path, "p")
	end

	return save_path .. "/" .. save_key()
end

---@return Arrow[]
function M.fetch_arrows()
	local cache_path = cache_file_path()

	if vim.fn.filereadable(cache_path) == 0 then
		return {}
	end

	local success, data = pcall(vim.fn.readfile, cache_path)
	if not success then
		return {}
	end

	-- `readfile` returns a table of lines, so join them
	local json_str = table.concat(data, "\n")
	local ok, decoded = pcall(vim.fn.json_decode, json_str)

	if ok and type(decoded) == "table" then
		return decoded
	else
		return {}
	end
end

---@param arrows Arrow[]
function M.save_arrows(arrows)
	local json_str = vim.fn.json_encode(arrows)
	local lines = vim.fn.split(json_str, "\n")
	vim.fn.writefile(lines, cache_file_path())
end

return M
