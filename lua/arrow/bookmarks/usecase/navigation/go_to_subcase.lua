local cache_quiver = require("arrow.persistence.cache_quiver")
local config = require("arrow.config")

local M = {}

function M.go_to(index)
	local arrow = cache_quiver.fetch_by_index(index)
	if not arrow then
		return
	end

	if
		config.getState("global_bookmarks") == true
		or config.getState("save_key_name") == "cwd"
		or config.getState("save_key_name") == "git_root_bare"
	then
		vim.cmd(":edit " .. arrow.filename)
	else
		vim.cmd(":edit " .. config.getState("save_key_cached") .. "/" .. arrow.filename)
	end
end

return M
