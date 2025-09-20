local M = {}

local in_memory_storage = require("arrow.persistence.in_memory_quiver")
local config = require("arrow.config")
local utils = require("arrow.utils")
local git = require("arrow.git")

local function save_key()
	if config.getState("global_bookmarks") == true then
		return "global"
	end

	if config.getState("separate_by_branch") then
		local branch = git.refresh_git_branch()

		if branch then
			return utils.normalize_path_to_filename(config.getState("save_key_cached") .. "-" .. branch)
		end
	end

	return utils.normalize_path_to_filename(config.getState("save_key_cached"))
end

local function cache_file_path()
	local save_path = config.getState("save_path")()

	save_path = save_path:gsub("/$", "")

	if vim.fn.isdirectory(save_path) == 0 then
		vim.fn.mkdir(save_path, "p")
	end

	return save_path .. "/" .. save_key()
end

function M.fetch_arrows()
	local cache_path = cache_file_path()

	if vim.fn.filereadable(cache_path) == 0 then
		return {}
	end

	local success, data = pcall(vim.fn.readfile, cache_path)

	if success then
		return data
	else
		return {}
	end
end

function M.save_arrows(arrows)
	local content = table.concat(arrows, "\n")
	local lines = vim.fn.split(content, "\n")
	vim.fn.writefile(lines, cache_file_path())
end

return M
