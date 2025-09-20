local M = {}

local cache_quiver = require("arrow.persistence.cache_quiver")

local config = require("arrow.config")
local utils = require("arrow.utils")
local git = require("arrow.git")

local function notify()
	vim.api.nvim_exec_autocmds("User", {
		pattern = "ArrowUpdate",
	})
end

function M.save(filename)
	cache_quiver.save(filename)
	cache_quiver.persist_arrows()
	notify()
end

function M.remove(filename)
	local arrow = cache_quiver.fetch_by_filename(filename)
	if arrow then
		cache_quiver.remove(arrow)
		cache_quiver.persist_arrows()
	end
	notify()
end

function M.toggle(filename)
	git.refresh_git_branch()

	filename = filename or utils.get_current_buffer_path()

	local arrow = cache_quiver.fetch_by_filename(filename)
	if arrow then
		cache_quiver.remove(arrow)
		cache_quiver.persist_arrows()
	else
		cache_quiver.save(filename)
		cache_quiver.persist_arrows()
	end
	notify()
end

function M.clear()
	cache_quiver.clear_arrows()
	cache_quiver.persist_arrows()
	notify()
end

function M.go_to(index)
	local filename = cache_quiver.fetch_by_index(index)

	if not filename then
		return
	end

	if
		config.getState("global_bookmarks") == true
		or config.getState("save_key_name") == "cwd"
		or config.getState("save_key_name") == "git_root_bare"
	then
		vim.cmd(":edit " .. filename)
	else
		vim.cmd(":edit " .. config.getState("save_key_cached") .. "/" .. filename)
	end
end

function M.next()
	git.refresh_git_branch()

	local current_index = cache_quiver.get_file_index(utils.get_current_buffer_path())
	local next_index

	if current_index and current_index < #cache_quiver.fetch_arrows() then
		next_index = current_index + 1
	else
		next_index = 1
	end

	M.go_to(next_index)
end

function M.previous()
	git.refresh_git_branch()

	local current_index = cache_quiver.get_file_index(utils.get_current_buffer_path())
	local previous_index

	if current_index and current_index == 1 then
		previous_index = #cache_quiver.fetch_arrows()
	elseif current_index then
		previous_index = current_index - 1
	else
		previous_index = #cache_quiver.fetch_arrows()
	end

	M.go_to(previous_index)
end

function M.get_arrows()
	return cache_quiver.fetch_arrows()
end

function M.fetch_by_index(index)
	return cache_quiver.fetch_by_index(index)
end

return M
