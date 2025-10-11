local M = {}

local config = require("arrow.config")
local utils = require("arrow.utils")
local git = require("arrow.git")
local icons = require("arrow.integration.icons")

local edit_mode_usecase = require("arrow.usecase.edit_mode_usecase")
local remove_arrow_usecase = require("arrow.usecase.remove_arrow_usecase")
local toggle_arrow_usecase = require("arrow.usecase.toggle_arrow_usecase")
local clear_arrows_usecase = require("arrow.usecase.clear_arrows_usecase")
local go_to_previous_arrow_usecase = require("arrow.usecase.navigation.go_to_previous_arrow_usecase")
local go_to_next_arrow_usecase = require("arrow.usecase.navigation.go_to_next_arrow_usecase")
local get_arrow_usecase = require("arrow.usecase.get_arrow_usecase")

local mode_context = require("arrow.strategy.mode_context")
local save_mode_strategy = require("arrow.strategy.save_mode_strategy")
local default_mode_strategy = require("arrow.strategy.default_mode_strategy")

local store = require("arrow.store.state_store")

local ns_id = vim.api.nvim_create_namespace("arrow")
local ns_id_current_file = vim.api.nvim_create_namespace("ArrowCurrentFile")
local ns_id_delete_mode = vim.api.nvim_create_namespace("ArrowDeleteMode")
local ns_id_file_index = vim.api.nvim_create_namespace("ArrowFileIndex")

local function getActionsMenu()
	local mappings = config.getState("mappings")

	if #store.arrows() == 0 then
		return {
			string.format("%s Save File", mappings.toggle),
		}
	end

	local already_saved = store.current_index() > 0

	local separate_save_and_remove = config.getState("separate_save_and_remove")

	local return_mappings = {
		string.format("%s Edit Arrow File", mappings.edit),
		string.format("%s Clear All Items", mappings.clear_all_items),
		string.format("%s Delete Mode", mappings.delete_mode),
		string.format("%s Open Vertical", mappings.open_vertical),
		string.format("%s Open Horizontal", mappings.open_horizontal),
		string.format("%s Next Item", mappings.next_item),
		string.format("%s Prev Item", mappings.prev_item),
		string.format("%s Quit", mappings.quit),
	}

	if separate_save_and_remove then
		table.insert(return_mappings, 1, string.format("%s Remove Current File", mappings.remove))
		table.insert(return_mappings, 1, string.format("%s Save Current File", mappings.toggle))
	else
		if already_saved == true then
			table.insert(return_mappings, 1, string.format("%s Remove Current File", mappings.toggle))
		else
			table.insert(return_mappings, 1, string.format("%s Save Current File", mappings.toggle))
		end
	end

	return return_mappings
end

---@param filenames string[]
---@return string[]
local function format_file_names(filenames)
	local full_path_list = config.getState("full_path_list")
	local formatted_names = {}

	-- Table to store occurrences of file names (tail)
	local name_occurrences = {}

	for _, full_path in ipairs(filenames) do
		local tail = vim.fn.fnamemodify(full_path, ":t:r") -- Get the file name without extension

		if vim.fn.isdirectory(full_path) == 1 then
			local parsed_path = full_path

			if parsed_path:sub(#parsed_path, #parsed_path) == "/" then
				parsed_path = parsed_path:sub(1, #parsed_path - 1)
			end

			local splitted_path = vim.split(parsed_path, "/")
			local folder_name = splitted_path[#splitted_path]

			if name_occurrences[folder_name] then
				table.insert(name_occurrences[folder_name], full_path)
			else
				name_occurrences[folder_name] = { full_path }
			end
		else
			if not name_occurrences[tail] then
				name_occurrences[tail] = { full_path }
			else
				table.insert(name_occurrences[tail], full_path)
			end
		end
	end

	for _, full_path in ipairs(filenames) do
		local tail = vim.fn.fnamemodify(full_path, ":t:r")
		local tail_with_extension = vim.fn.fnamemodify(full_path, ":t")

		if vim.fn.isdirectory(full_path) == 1 then
			if not (string.sub(full_path, #full_path, #full_path) == "/") then
				full_path = full_path .. "/"
			end

			local path = vim.fn.fnamemodify(full_path, ":h")

			local display_path = path

			local splitted_path = vim.split(display_path, "/")

			if #splitted_path > 1 then
				local folder_name = splitted_path[#splitted_path]

				local location = vim.fn.fnamemodify(full_path, ":h:h")

				if #name_occurrences[folder_name] > 1 or config.getState("always_show_path") then
					table.insert(formatted_names, string.format("%s . %s", folder_name .. "/", location))
				else
					table.insert(formatted_names, string.format("%s", folder_name .. "/"))
				end
			else
				if config.getState("always_show_path") then
					table.insert(formatted_names, full_path .. " . /")
				else
					table.insert(formatted_names, full_path)
				end
			end
		elseif
			not (config.getState("always_show_path"))
			and #name_occurrences[tail] == 1
			and not (vim.tbl_contains(full_path_list, tail))
		then
			table.insert(formatted_names, tail_with_extension)
		else
			local path = vim.fn.fnamemodify(full_path, ":h")
			local display_path = path

			if vim.tbl_contains(full_path_list, tail) then
				display_path = vim.fn.fnamemodify(full_path, ":h")
			end

			table.insert(formatted_names, string.format("%s . %s", tail_with_extension, display_path))
		end
	end

	return formatted_names
end

local function closeMenu()
	local win = vim.fn.win_getid()
	vim.api.nvim_win_close(win, true)
end

local function renderBuffer(buffer)
	vim.bo[buffer].modifiable = true

	local show_icons = config.getState("show_icons")
	local buf = buffer or vim.api.nvim_get_current_buf()
	local lines = { "" }

	local arrows = store.arrows()
	local filenames = store.filenames()
	local formattedFilenames = format_file_names(filenames)

	store.clear_highlights()
	store.set_current_index(0)

	mode_context.setup_keymaps({
		buf = buf,
		openFile = M.openFile,
	})

	-- Render arrows
	for i, arrow in ipairs(arrows) do
		vim.highlight.range(buf, ns_id, "ArrowDeleteMode", { i + 3, 0 }, { i + 3, -1 })

		local parsed_filename = filenames[i]
		if parsed_filename:sub(1, 2) == "./" then
			parsed_filename = parsed_filename:sub(3)
		end

		if parsed_filename == vim.b[buf].filename then
			store.set_current_index(i)
		end

		local fileName = formattedFilenames[i]
		if show_icons then
			local icon, hl_group = icons.get_file_icon(filenames[i])
			store.add_highlight(hl_group)
			fileName = icon .. " " .. fileName
		end

		table.insert(lines, string.format("   %s %s", arrow.key, fileName))
	end

	-- Handle empty list
	if #store.arrows() == 0 then
		table.insert(lines, "   No files yet.")
	end

	table.insert(lines, "")

	local actionsMenu = getActionsMenu()
	if not config.getState("hide_handbook") then
		for _, action in ipairs(actionsMenu) do
			table.insert(lines, "   " .. action)
		end
	end

	table.insert(lines, "")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buffer].modifiable = false
	vim.bo[buf].buftype = "nofile"
end

local function render_highlights(buffer)
	local actionsMenu = getActionsMenu()
	local mappings = config.getState("mappings")
	local arrows = store.arrows()
	local current_index = store.current_index()

	vim.api.nvim_buf_clear_namespace(buffer, -1, 0, -1)
	local menuBuf = buffer or vim.api.nvim_get_current_buf()

	local line = vim.api.nvim_buf_get_lines(menuBuf, current_index, current_index + 1, false)[1]
	vim.api.nvim_buf_set_extmark(menuBuf, ns_id_current_file, current_index, 0, {
		end_col = #line,
		hl_group = "ArrowCurrentFile",
	})

	for i, _ in ipairs(arrows) do
		if vim.b.arrow_current_mode == "delete_mode" then
			vim.api.nvim_buf_set_extmark(menuBuf, ns_id_delete_mode, i, 3, {
				end_col = 4,
				hl_group = "ArrowDeleteMode",
			})
		else
			vim.api.nvim_buf_set_extmark(menuBuf, ns_id_file_index, i, 3, {
				end_col = 4,
				hl_group = "ArrowFileIndex",
			})
		end
	end

	if config.getState("show_icons") then
		for k, v in pairs(store.highlights()) do
			vim.api.nvim_buf_add_highlight(menuBuf, -1, v, k, 5, 8)
		end
	end

	for i = #arrows + 3, #arrows + #actionsMenu + 3 do
		vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowAction", i - 1, 3, 4)
	end

	-- Find the line containing "d - Delete Mode"
	local saveModeLine = -1
	local deleteModeLine = -1
	local verticalModeLine = -1
	local horizontalModelLine = -1

	for i, action in ipairs(actionsMenu) do
		if action:find(mappings.toggle .. " Save Current File") then
			saveModeLine = i - 1
		end

		if action:find(mappings.delete_mode .. " Delete Mode") then
			deleteModeLine = i - 1
		end

		if action:find(mappings.open_vertical .. " Open Vertical") then
			verticalModeLine = i - 1
		end

		if action:find(mappings.open_horizontal .. " Open Horizontal") then
			horizontalModelLine = i - 1
		end
	end

	if saveModeLine >= 0 then
		if vim.b.arrow_current_mode == "save_mode" then
			vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowSaveMode", #arrows + saveModeLine + 2, 0, -1)
		end
	end

	if deleteModeLine >= 0 then
		if vim.b.arrow_current_mode == "delete_mode" then
			vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowDeleteMode", #arrows + deleteModeLine + 2, 0, -1)
		end
	end

	if verticalModeLine >= 0 then
		if vim.b.arrow_current_mode == "vertical_mode" then
			vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowAction", #arrows + verticalModeLine + 2, 0, -1)
		end
	end

	if horizontalModelLine >= 0 then
		if vim.b.arrow_current_mode == "horizontal_mode" then
			vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowAction", #arrows + horizontalModelLine + 2, 0, -1)
		end
	end

	local pattern = " %. .-$"
	local line_number = 1

	while line_number <= #arrows + 1 do
		local line_content = vim.api.nvim_buf_get_lines(menuBuf, line_number - 1, line_number, false)[1]

		local match_start, match_end = string.find(line_content, pattern)
		if match_start then
			vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowAction", line_number - 1, match_start - 1, match_end)
		end

		line_number = line_number + 1
	end
end

-- Function to create the menu buffer with a list format
local function createMenuBuffer(filename)
	local buf = vim.api.nvim_create_buf(false, true)

	vim.b[buf].filename = filename
	vim.b[buf].arrow_current_mode = ""

	renderBuffer(buf)

	return buf
end

function M.openFile(key)
	local arrow = get_arrow_usecase.get_arrow_by_key(key)
	if arrow == nil then
		return
	end
	local filename = arrow.filename

	if vim.b.arrow_current_mode == "delete_mode" then
		remove_arrow_usecase.remove_arrow(filename)

		renderBuffer(vim.api.nvim_get_current_buf())
		render_highlights(vim.api.nvim_get_current_buf())
	else
		if not filename then
			print("Invalid file number")

			return
		end

		local action

		filename = vim.fn.fnameescape(filename)

		if vim.b.arrow_current_mode == "" or not vim.b.arrow_current_mode then
			action = config.getState("open_action")
		elseif vim.b.arrow_current_mode == "vertical_mode" then
			action = config.getState("vertical_action")
		elseif vim.b.arrow_current_mode == "horizontal_mode" then
			action = config.getState("horizontal_action")
		end

		closeMenu()
		vim.api.nvim_exec_autocmds("User", { pattern = "ArrowOpenFile" })

		if
			config.getState("global_bookmarks") == true
			or config.getState("save_key_name") == "cwd"
			or config.getState("save_key_name") == "git_root_bare"
		then
			action(filename, vim.b.filename)
		else
			action(config.getState("save_key_cached") .. "/" .. filename, vim.b.filename)
		end
	end
end

function M.getWindowConfig()
	local show_handbook = not (config.getState("hide_handbook"))
	local filenames = store.filenames()
	local parsedFileNames = format_file_names(filenames)
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
		height = height + 10
		if separate_save_and_remove then
			height = height + 1
		end
	end

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

function M.openMenu(bufnr)
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

	save_mode_strategy.setup({
		closeMenu = closeMenu,
		renderBuffer = renderBuffer,
		render_highlights = render_highlights,
	})

	mode_context.set_strategy(default_mode_strategy)

	local menuBuf = createMenuBuffer(filename)

	local window_config = M.getWindowConfig()

	local win = vim.api.nvim_open_win(menuBuf, true, window_config)

	local mappings = config.getState("mappings")

	local separate_save_and_remove = config.getState("separate_save_and_remove")

	local menuKeymapOpts = { noremap = true, silent = true, buffer = menuBuf, nowait = true }

	vim.keymap.set("n", config.getState("leader_key"), closeMenu, menuKeymapOpts)

	local buffer_leader_key = config.getState("buffer_leader_key")
	if buffer_leader_key then
		vim.keymap.set("n", buffer_leader_key, function()
			closeMenu()

			vim.schedule(function()
				require("arrow.buffer_ui").openMenu(call_buffer)
			end)
		end, menuKeymapOpts)
	end

	vim.keymap.set("n", mappings.quit, closeMenu, menuKeymapOpts)
	vim.keymap.set("n", mappings.edit, function()
		closeMenu()
		edit_mode_usecase.open_edit_mode()
	end, menuKeymapOpts)

	if separate_save_and_remove then
		vim.keymap.set("n", mappings.toggle, function()
			filename = filename or utils.get_current_buffer_path()
			if vim.b.arrow_current_mode == "save_mode" then
				vim.b.arrow_current_mode = ""
				mode_context.set_strategy(default_mode_strategy)
			else
				vim.b.arrow_current_mode = "save_mode"
				mode_context.set_strategy(save_mode_strategy)
			end

			renderBuffer(menuBuf)
			render_highlights(menuBuf)
			-- save_arrow_usecase.save_arrow(filename)
			-- closeMenu()
		end, menuKeymapOpts)

		vim.keymap.set("n", mappings.remove, function()
			filename = filename or utils.get_current_buffer_path()
			remove_arrow_usecase.remove_arrow(filename)
			closeMenu()
		end, menuKeymapOpts)
	else
		vim.keymap.set("n", mappings.toggle, function()
			toggle_arrow_usecase.toggle(filename)
			closeMenu()
		end, menuKeymapOpts)
	end

	vim.keymap.set("n", mappings.clear_all_items, function()
		clear_arrows_usecase.clear()
		closeMenu()
	end, menuKeymapOpts)

	vim.keymap.set("n", mappings.next_item, function()
		closeMenu()
		go_to_next_arrow_usecase.next()
	end, menuKeymapOpts)

	vim.keymap.set("n", mappings.prev_item, function()
		closeMenu()
		go_to_previous_arrow_usecase.previous()
	end, menuKeymapOpts)

	vim.keymap.set("n", "<Esc>", closeMenu, menuKeymapOpts)

	vim.keymap.set("n", mappings.delete_mode, function()
		if vim.b.arrow_current_mode == "delete_mode" then
			vim.b[menuBuf].arrow_current_mode = ""
		else
			vim.b[menuBuf].arrow_current_mode = "delete_mode"
		end

		renderBuffer(menuBuf)
		render_highlights(menuBuf)
	end, menuKeymapOpts)

	vim.keymap.set("n", mappings.open_vertical, function()
		if vim.b.arrow_current_mode == "vertical_mode" then
			vim.b.arrow_current_mode = ""
		else
			vim.b.arrow_current_mode = "vertical_mode"
		end

		renderBuffer(menuBuf)
		render_highlights(menuBuf)
	end, menuKeymapOpts)

	vim.keymap.set("n", mappings.open_horizontal, function()
		if vim.b.arrow_current_mode == "horizontal_mode" then
			vim.b.arrow_current_mode = ""
		else
			vim.b.arrow_current_mode = "horizontal_mode"
		end

		renderBuffer(menuBuf)
		render_highlights(menuBuf)
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

	render_highlights(menuBuf)
end

-- Command to trigger the menu
return M
