local M = {}

local config = require("arrow.config")

function M.get_git_branch()
	local git_files = vim.fs.find(".git", { upward = true, stop = vim.loop.os_homedir() })

	if git_files then
		local result = vim.fn.system({ "git", "symbolic-ref", "--short", "HEAD" })

		return vim.trim(string.gsub(result, "\n", ""))
	else
		return nil
	end
end

function M.refresh_git_branch()
	if config.getState("separate_by_branch") then
		local current_branch = config.getState("current_branch")

		if current_branch ~= M.get_git_branch() then
			config.setState("current_branch", M.get_git_branch())
			require("arrow.persistence.cache_quiver").clear_arrows()
		end
	end

	return config.getState("current_branch")
end

return M
