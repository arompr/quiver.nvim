local M = {}

local config = require("arrow.config")
local utils = require("arrow.utils")
local ui_utils = require("arrow.bookmarks.ui_utils")
local git = require("arrow.git")

local reorder_arrows_usecase = require("arrow.bookmarks.usecase.reorder_arrows_usecase")
local remove_arrow_usecase = require("arrow.bookmarks.usecase.remove_arrow_usecase")
local toggle_arrow_usecase = require("arrow.bookmarks.usecase.toggle_arrow_usecase")
local clear_arrows_usecase = require("arrow.bookmarks.usecase.clear_arrows_usecase")
local go_to_previous_arrow_usecase = require("arrow.bookmarks.usecase.navigation.go_to_previous_arrow_usecase")
local go_to_next_arrow_usecase = require("arrow.bookmarks.usecase.navigation.go_to_next_arrow_usecase")
local get_arrow_usecase = require("arrow.bookmarks.usecase.get_arrow_usecase")

local mode_context = require("arrow.bookmarks.strategy.mode_context")

local store = require("arrow.bookmarks.store.state_store")

local Style = require("arrow.bookmarks.style")
local Padding = Style.Padding

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
	local show_handbook = not (config.getState("hide_handbook"))
	local filenames = store.filenames()
	local parsedFileNames = ui_utils.format_filenames(filenames)
	local separate_save_and_remove = config.getState("separate_save_and_remove")

	local max_width = 0
	if show_handbook then
		max_width = 13
		if separate_save_and_remove then
			max_width = max_width + 2
		end
	end
	for _, v in pairs(parsedFileNames) do
		if #v > max_width then
			max_width = #v
		end
	end

	local width = max_width + 12
	local height = #filenames + 2

	if show_handbook then
		height = height + 12
		if separate_save_and_remove then
			height = height + 1
		end
	end

	local available_width = width - (2 * #Padding.m)
	local wrapped_line_keys = ui_utils.wrap_str_to_length(config.getState("index_keys"), available_width)
	store.set_line_keys(wrapped_line_keys)

	height = height + #wrapped_line_keys

	local current_config = {
		width = width,
		height = height,
		row = math.ceil((vim.o.lines - height) / 2),
		col = math.ceil((vim.o.columns - width) / 2),
	}

	local is_empty = #store.arrows() == 0

	if is_empty and show_handbook then
		current_config.height = 5
		current_config.width = 18
	elseif is_empty then
		current_config.height = 3
		current_config.width = 18
	end

	local res = vim.tbl_deep_extend("force", current_config, config.getState("window"))

	if res.width == "auto" then
		res.width = current_config.width
	end
	if res.height == "auto" then
		res.height = current_config.height
	end
	if res.row == "auto" then
		res.row = current_config.row
	end
	if res.col == "auto" then
		res.col = current_config.col
	end

	return res
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
	store.set_arrows(get_arrow_usecase.get_arrows())

	local filename
	if config.getState("global_bookmarks") == true then
		filename = vim.fn.expand("%:p")
	else
		filename = utils.get_current_buffer_path()
	end

	mode_context.setup({ close_menu = close_menu })
	mode_context.toggle_default_mode()

	local window_config = M.get_window_config()

	local menuBuf = create_menu_buffer(filename)

	local win = vim.api.nvim_open_win(menuBuf, true, window_config)

	local mappings = config.getState("mappings")

	local separate_save_and_remove = config.getState("separate_save_and_remove")

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

	if separate_save_and_remove then
		vim.keymap.set("n", mappings.toggle, function()
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
	else
		vim.keymap.set("n", mappings.toggle, function()
			toggle_arrow_usecase.toggle(filename)
			close_menu()
		end, menuKeymapOpts)
	end

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

-- Command to trigger the menu
return M
