local git = require("arrow.git")
local utils = require("arrow.utils")
local cache_quiver = require("arrow.persistence.cache_quiver")
local events = require("arrow.events")

local M = {}

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
	events.notify()
end

return M
