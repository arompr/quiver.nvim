local M = {}

local config = require("arrow.config")
local utils = require("arrow.utils")
local git = require("arrow.git")

local reorder_arrows_usecase = require("arrow.bookmarks.usecase.reorder_arrows_usecase")
local remove_arrow_usecase = require("arrow.bookmarks.usecase.remove_arrow_usecase")

local clear_arrows_usecase = require("arrow.bookmarks.usecase.clear_arrows_usecase")
local go_to_previous_arrow_usecase = require("arrow.bookmarks.usecase.navigation.go_to_previous_arrow_usecase")
local go_to_next_arrow_usecase = require("arrow.bookmarks.usecase.navigation.go_to_next_arrow_usecase")
local get_arrow_usecase = require("arrow.bookmarks.usecase.get_arrow_usecase")

local mode_context = require("arrow.bookmarks.strategy.mode_context")

local store = require("arrow.bookmarks.store.state_store")
local function close_menu()
	local win = vim.fn.win_getid()
	vim.api.nvim_win_close(win, true)
end

-- Function to create the menu buffer with a list format
local function create_menu_buffer(filename)
	local buf = vim.api.nvim_create_buf(false, true)

	vim.b[buf].filename = filename
	vim.b[buf].arrow_current_mode = ""

	mode_context.render_buffer(buf)

	return buf
end

function M.get_window_config()
	local default_window_config = config.getState("window")
	local default_width = default_window_config.width
	local computed_height = #store.layout().get_all_items()
	local new_window_config = {
		width = default_width,
		height = computed_height,
		row = math.ceil((vim.o.lines - computed_height) / 2),
		col = math.ceil((vim.o.columns - default_width) / 2),
	}
	local window_config = vim.tbl_deep_extend("force", config.getState("window"), new_window_config)
	store.set_window_config(window_config)

	return window_config
end

local function open_edit_mode()
	git.refresh_git_branch()

	local arrow_filenames = store.filenames()

	if config.getState("relative_path") == true and config.getState("global_bookmarks") == false then
		for i, line in ipairs(arrow_filenames) do
			if not line:match("^%./") and not utils.string_contains_whitespace(line) and #arrow_filenames[i] > 1 then
				arrow_filenames[i] = "./" .. line
			end
		end
	end

	local bufnr = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, arrow_filenames)

	local width = math.min(80, vim.fn.winwidth(0) - 4)
	local height = math.min(20, #arrow_filenames + 2)

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

	local mappings = config.getState("mappings")
	local close_buffer = ":lua vim.api.nvim_win_close(" .. winid .. ", {force = true})<CR>"
	vim.api.nvim_buf_set_keymap(bufnr, "n", "q", close_buffer, { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(bufnr, "n", mappings.quit, close_buffer, { noremap = true, silent = true })
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
			local filenames = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
			reorder_arrows_usecase.reorder(filenames)
		end,
	})

	vim.cmd("setlocal nu")

	return bufnr, winid
end

function M.open_menu(bufnr)
	git.refresh_git_branch()

	local call_buffer = bufnr or vim.api.nvim_get_current_buf()

	store.clear_highlights()

	local filename
	if config.getState("global_bookmarks") == true then
		filename = vim.fn.expand("%:p")
	else
		filename = utils.get_current_buffer_path()
	end

	store.set_arrows(get_arrow_usecase.get_arrows())
	mode_context.setup({ close_menu = close_menu })
	mode_context.toggle_default_mode()

	local menuBuf = create_menu_buffer(filename)

	local win = vim.api.nvim_open_win(menuBuf, true, M.get_window_config())

	local mappings = config.getState("mappings")

	local menuKeymapOpts = { noremap = true, silent = true, buffer = menuBuf, nowait = true }

	vim.keymap.set("n", config.getState("leader_key"), close_menu, menuKeymapOpts)

	local buffer_leader_key = config.getState("buffer_leader_key")
	if buffer_leader_key then
		vim.keymap.set("n", buffer_leader_key, function()
			close_menu()

			vim.schedule(function()
				require("arrow.buffer_ui").openMenu(call_buffer)
			end)
		end, menuKeymapOpts)
	end

	vim.keymap.set("n", mappings.quit, close_menu, menuKeymapOpts)
	vim.keymap.set("n", mappings.edit, function()
		close_menu()
		open_edit_mode()
	end, menuKeymapOpts)

	vim.keymap.set("n", mappings.save, function()
		filename = filename or utils.get_current_buffer_path()
		if vim.b.arrow_current_mode == "save_mode" then
			vim.b.arrow_current_mode = ""
			mode_context.toggle_default_mode()
		else
			vim.b.arrow_current_mode = "save_mode"
			mode_context.toggle_save_mode()
		end

		mode_context.render_buffer(menuBuf)
		mode_context.render_highlights(menuBuf)
	end, menuKeymapOpts)

	vim.keymap.set("n", mappings.remove, function()
		filename = filename or utils.get_current_buffer_path()
		remove_arrow_usecase.remove_arrow(filename)
		close_menu()
	end, menuKeymapOpts)

	vim.keymap.set("n", mappings.save, function()
		filename = filename or utils.get_current_buffer_path()
		if vim.b.arrow_current_mode == "save_mode" then
			vim.b.arrow_current_mode = ""
			mode_context.toggle_default_mode()
		else
			vim.b.arrow_current_mode = "save_mode"
			mode_context.toggle_save_mode()
		end

		mode_context.render_buffer(menuBuf)
		mode_context.render_highlights(menuBuf)
	end, menuKeymapOpts)

	-- vim.keymap.set("n", mappings.remove, function()
	-- 	filename = filename or utils.get_current_buffer_path()
	-- 	remove_arrow_usecase.remove_arrow(filename)
	-- 	close_menu()
	-- end, menuKeymapOpts)

	vim.keymap.set("n", mappings.clear_all_items, function()
		clear_arrows_usecase.clear()
		close_menu()
	end, menuKeymapOpts)

	vim.keymap.set("n", mappings.next_item, function()
		close_menu()
		go_to_next_arrow_usecase.next()
	end, menuKeymapOpts)

	vim.keymap.set("n", mappings.prev_item, function()
		close_menu()
		go_to_previous_arrow_usecase.previous()
	end, menuKeymapOpts)

	vim.keymap.set("n", "<Esc>", close_menu, menuKeymapOpts)

	vim.keymap.set("n", mappings.delete_mode, function()
		if vim.b.arrow_current_mode == "delete_mode" then
			vim.b[menuBuf].arrow_current_mode = ""
			mode_context.toggle_default_mode()
		else
			vim.b[menuBuf].arrow_current_mode = "delete_mode"
			mode_context.toggle_delete_mode()
		end

		mode_context.render_buffer(menuBuf)
		mode_context.render_highlights(menuBuf)
	end, menuKeymapOpts)

	vim.keymap.set("n", mappings.open_vertical, function()
		if vim.b.arrow_current_mode == "vertical_mode" then
			vim.b.arrow_current_mode = ""
			mode_context.toggle_default_mode()
		else
			vim.b.arrow_current_mode = "vertical_mode"
			mode_context.toggle_vertical_mode()
		end

		mode_context.render_buffer(menuBuf)
		mode_context.render_highlights(menuBuf)
	end, menuKeymapOpts)

	vim.keymap.set("n", mappings.open_horizontal, function()
		if vim.b.arrow_current_mode == "horizontal_mode" then
			vim.b.arrow_current_mode = ""
			mode_context.toggle_default_mode()
		else
			vim.b.arrow_current_mode = "horizontal_mode"
			mode_context.toggle_horizontal_mode()
		end

		mode_context.render_buffer(menuBuf)
		mode_context.render_highlights(menuBuf)
	end, menuKeymapOpts)

	vim.api.nvim_set_hl(0, "ArrowCursor", { nocombine = true, blend = 100 })
	vim.opt.guicursor:append("a:ArrowCursor/ArrowCursor")

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = 0,
		desc = "Disable Cursor",
		once = true,
		callback = function()
			store.set_current_index(0)

			vim.cmd("highlight clear ArrowCursor")
			vim.schedule(function()
				vim.opt.guicursor:remove("a:ArrowCursor/ArrowCursor")
			end)
		end,
	})

	-- disable cursorline for this buffer
	vim.wo.cursorline = false

	vim.api.nvim_set_current_win(win)

	mode_context.render_highlights(menuBuf)
end

return M
