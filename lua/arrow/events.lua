local M = {}

--- Fire ArrowUpdate event
function M.notify()
	vim.api.nvim_exec_autocmds("User", {
		pattern = "ArrowUpdate",
	})
end

return M
