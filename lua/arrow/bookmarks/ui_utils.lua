local config = require("arrow.config")
local store = require("arrow.bookmarks.store.state_store")

local M = {}

function M.get_actions_menu()
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
function M.format_filenames(filenames)
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

-- Wrap str based on available width minus padding
function M.wrap_str_to_length(str, max_length)
	-- base case: if string is shorter than or equal to max_length
	if #str <= max_length then
		return { str }
	end

	-- take first max_length characters as the current line
	local line = str:sub(1, max_length)
	-- remaining str after current line
	local remaining = str:sub(max_length + 1)

	-- recursively wrap the remaining str
	local rest = M.wrap_str_to_length(remaining, max_length)

	-- prepend current line to the list
	table.insert(rest, 1, line)

	return rest
end

return M
