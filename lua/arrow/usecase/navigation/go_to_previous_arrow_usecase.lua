local cache_quiver = require("arrow.persistence.cache_quiver")
local go_to_subcase = require("arrow.usecase.navigation.go_to_subcase")
local git = require("arrow.git")
local utils = require("arrow.utils")

local M = {}

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

	go_to_subcase.go_to(previous_index)
end

return M
