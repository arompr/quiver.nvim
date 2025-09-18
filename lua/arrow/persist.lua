local M = {}

local in_memory_storage = require("arrow.persistence.in_memory_storage")
local file_storage = require("arrow.persistence.file_storage")
local cache_quiver = require("arrow.persistence.cache_quiver")

local config = require("arrow.config")
local utils = require("arrow.utils")
local git = require("arrow.git")

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
	local index = in_memory_storage.is_saved(filename)
	if index then
		in_memory_storage.remove_at(index)
		file_storage.persist()
	end
	notify()
end

function M.toggle(filename)
	git.refresh_git_branch()

	filename = filename or utils.get_current_buffer_path()

	local index = in_memory_storage.is_saved(filename)
	if index then
		M.remove(filename)
	else
		M.save(filename)
	end
	notify()
end

function M.clear()
	cache_quiver.clear_arrows()
	cache_quiver.persist_arrows()
	notify()
end

function M.load_cache_file()
	local cache_path = cache_file_path()

	if vim.fn.filereadable(cache_path) == 0 then
		cache_quiver.clear_arrows()

		return
	end

	local success, data = pcall(vim.fn.readfile, cache_path)
	if success then
		-- cache_quiver.remove
		in_memory_storage.set_arrows(data)
	else
		cache_quiver.clear_arrows()
	end
end

function M.go_to(index)
	local filename = in_memory_storage.fetch_by_index(index)

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

	local current_index = in_memory_storage.is_saved(utils.get_current_buffer_path())
	local next_index

	if current_index and current_index < #in_memory_storage.fetch_arrows() then
		next_index = current_index + 1
	else
		next_index = 1
	end

	M.go_to(next_index)
end

function M.previous()
	git.refresh_git_branch()

	local current_index = in_memory_storage.is_saved(utils.get_current_buffer_path())
	local previous_index

	if current_index and current_index == 1 then
		previous_index = #in_memory_storage.fetch_arrows()
	elseif current_index then
		previous_index = current_index - 1
	else
		previous_index = #in_memory_storage.fetch_arrows()
	end

	M.go_to(previous_index)
end

function M.open_cache_file()
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
			vim.fn.writefile(updated_content, cache_path)
			M.load_cache_file()
		end,
	})

	vim.cmd("setlocal nu")

	return bufnr, winid
end

function M.get_arrow_filenames()
	return cache_quiver.fetch_arrows()
end

function M.fetch_by_index(index)
	return cache_quiver.fetch_by_index(index)
end

return M
