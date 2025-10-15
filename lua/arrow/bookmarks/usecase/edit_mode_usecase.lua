local cache_quiver = require("arrow.persistence.cache_quiver")
local config = require("arrow.config")
local utils = require("arrow.utils")
local git = require("arrow.git")

local M = {}

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

function M.open_edit_mode()
	git.refresh_git_branch()

	local cache_path = cache_file_path()
	local cache_content

	if vim.fn.filereadable(cache_path) == 0 then
		cache_content = {}
	else
		cache_content = vim.fn.readfile(cache_path)
	end

	if config.getState("relative_path") == true and config.getState("global_bookmarks") == false then
		for i, line in ipairs(cache_content) do
			if not line:match("^%./") and not utils.string_contains_whitespace(line) and #cache_content[i] > 1 then
				cache_content[i] = "./" .. line
			end
		end
	end

	local bufnr = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, cache_content)

	local width = math.min(80, vim.fn.winwidth(0) - 4)
	local height = math.min(20, #cache_content + 2)

	local row = math.ceil((vim.o.lines - height) / 2)
	local col = math.ceil((vim.o.columns - width) / 2)

	local border = config.getState("window").border

	local opts = {
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		focusable = true,
		border = border,
	}

	local winid = vim.api.nvim_open_win(bufnr, true, opts)

	local close_buffer = ":lua vim.api.nvim_win_close(" .. winid .. ", {force = true})<CR>"
	vim.api.nvim_buf_set_keymap(bufnr, "n", "q", close_buffer, { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", close_buffer, { noremap = true, silent = true })
	vim.keymap.set("n", config.getState("leader_key"), close_buffer, { noremap = true, silent = true, buffer = bufnr })

	vim.keymap.set("n", "<CR>", function()
		local line = vim.api.nvim_get_current_line()

		vim.api.nvim_win_close(winid, true)
		vim.cmd(":edit " .. vim.fn.fnameescape(line))
	end, { noremap = true, silent = true, buffer = bufnr })

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = bufnr,
		desc = "save cache buffer on leave",
		callback = function()
			local updated_content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

			-- TODO: Rework this after persistence improved to key/value pairs
			-- TODO reorder cache_quiver arrows with updated_content
			cache_quiver.set(updated_content)
			-- cache_quiver.persist_arrows()
		end,
	})

	vim.cmd("setlocal nu")

	return bufnr, winid
end

return M
