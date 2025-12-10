local cache_quiver = require("arrow.persistence.cache_quiver")
local go_to_subcase = require("arrow.bookmarks.usecase.navigation.go_to_subcase")
local git = require("arrow.git")
local utils = require("arrow.utils")

local M = {}

function M.next()
	git.refresh_git_branch()

	local current_index = cache_quiver.get_file_index(utils.get_current_buffer_path())
	local next_index

	if current_index and current_index < #cache_quiver.fetch_arrows() then
		next_index = current_index + 1
	else
		next_index = 1
	end

	go_to_subcase.go_to(next_index)
end

return M
