local cache_quiver = require("arrow.persistence.cache_quiver")

local M = {}

M.openFile = nil

function M.setup(opts) end

--- Setup keymaps for default mode
--- @param opts table
function M.setup_keymaps(opts)
	local buf = opts.buf
	local openFile = opts.openFile
	local stored_arrows = cache_quiver.fetch_arrows()

	for _, arrow in ipairs(stored_arrows) do
		vim.keymap.set("n", arrow.key, function()
			openFile(arrow.key)
		end, { noremap = true, silent = true, buffer = buf, nowait = true })
	end
end

return M
