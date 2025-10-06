local cache_quiver = require("arrow.persistence.cache_quiver")

local M = {}

--- Setup keymaps for default mode
--- @param opts table
function M.setup_keymaps(opts)
	local buf = opts.buf
	local stored_arrows = cache_quiver.fetch_arrows()
	local openFile = opts.openFile

	for _, arrow in ipairs(stored_arrows) do
		vim.keymap.set("n", arrow.key, function()
			openFile(arrow.key, buf)
		end, { noremap = true, silent = true, buffer = buf, nowait = true })
	end
end

return M
