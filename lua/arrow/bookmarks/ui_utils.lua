local config = require("arrow.config")
local store = require("arrow.bookmarks.store.state_store")

local M = {}

---@param filename string
---@return string
function M.format_filename(filename)
	local full_path_list = config.getState("full_path_list")

	-- Detect whether it's a directory
	local is_dir = vim.fn.isdirectory(filename) == 1
	local tail = vim.fn.fnamemodify(filename, ":t:r")
	local tail_with_extension = vim.fn.fnamemodify(filename, ":t")

	-- Normalize trailing slash for directories
	if is_dir and not filename:match("/$") then
		filename = filename .. "/"
	end

	if is_dir then
		local path = vim.fn.fnamemodify(filename, ":h")
		local splitted_path = vim.split(path, "/")
		local folder_name = splitted_path[#splitted_path]

		local location = vim.fn.fnamemodify(filename, ":h:h")

		return string.format("%s/", folder_name)
	else
		local path = vim.fn.fnamemodify(filename, ":h")
		local display_path = path

		-- If this filename (without extension) is in the full_path_list, show path
		if vim.tbl_contains(full_path_list, tail) then
			return string.format("%s . %s", tail_with_extension, display_path)
		else
			return tail_with_extension
		end
	end
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

				if #name_occurrences[folder_name] > 1 then
					table.insert(formatted_names, string.format("%s . %s", folder_name .. "/", location))
				else
					table.insert(formatted_names, string.format("%s", folder_name .. "/"))
				end
			else
				table.insert(formatted_names, full_path)
			end
		elseif #name_occurrences[tail] == 1 and not (vim.tbl_contains(full_path_list, tail)) then
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

--- Smart dynamic truncation: prefix ... suffix.extension
--- @param filename string
--- @param max_width integer
--- @param min_prefix integer? default=5
--- @param min_suffix integer? default=5
--- @return string
function M.smart_truncate(filename, max_width, min_prefix, min_suffix)
	min_prefix = min_prefix or 5
	min_suffix = min_suffix or 5

	if #filename <= max_width then
		return filename
	end

	-- Extract extension
	local basename, extension = filename:match("^(.*)%.([^%.]+)$")
	if not basename then
		basename = filename
		extension = ""
	end

	local ext_len = #extension > 0 and (#extension + 1) or 0 -- include dot
	local ellipsis = "…"
	local ell_len = 1

	-- available for prefix+suffix
	local remaining = max_width - ext_len - ell_len
	if remaining <= 0 then
		return filename:sub(1, max_width - ell_len) .. ellipsis
	end

	-- compute prefix/suffix split
	local prefix_len = math.floor(remaining * 0.6)
	local suffix_len = remaining - prefix_len

	-- enforce minimums
	if prefix_len < min_prefix then
		prefix_len = min_prefix
	end
	if suffix_len < min_suffix then
		suffix_len = min_suffix
	end

	-- adjust if sum is too large
	if prefix_len + suffix_len > remaining then
		-- reduce suffix first, then prefix
		local excess = prefix_len + suffix_len - remaining
		suffix_len = math.max(min_suffix, suffix_len - excess)
		if prefix_len + suffix_len > remaining then
			prefix_len = math.max(min_prefix, remaining - suffix_len)
		end
	end

	local prefix = basename:sub(1, prefix_len)
	local suffix = basename:sub(-suffix_len)

	if #extension > 0 then
		return prefix .. ellipsis .. suffix .. "." .. extension
	else
		return prefix .. ellipsis .. suffix
	end
end

--- Split filename at the dots: returns { "name", "ext1", "ext2", ... }
local function split_parts(filename)
	local parts = {}
	for part in filename:gmatch("[^%.]+") do
		table.insert(parts, part)
	end
	return parts
end

--- Smart truncation:
--- prefix….ext1.ext2.ext3  (ellipsis + dot)
---
--- @param filename string
--- @param max_width integer
--- @param min_prefix integer? default=5
--- @return string
function M.truncate_keep_ext_progressive(filename, max_width, min_prefix)
	min_prefix = min_prefix or 5
	if #filename <= max_width then
		return filename
	end

	local ellipsis = "…." -- NOTE: Unicode ellipsis + dot
	local ell_len = 2 -- "….": length 2

	-- Split filename: { basename, ext1, ext2, ... }
	local parts = split_parts(filename)
	if #parts == 1 then
		-- no extension, fallback
		return filename:sub(1, max_width - ell_len) .. ellipsis
	end

	local basename = table.remove(parts, 1)

	-- Try progressively shorter extension suffixes
	for start_i = 1, #parts do
		local suffix = table.concat({ unpack(parts, start_i) }, ".")
		suffix = suffix -- no leading dot; the leading dot comes from ellipsis
		local full_suffix = ellipsis .. suffix

		local remain_for_prefix = max_width - #full_suffix
		if remain_for_prefix >= min_prefix then
			local prefix = basename:sub(1, remain_for_prefix)
			return prefix .. full_suffix
		end
	end

	-- Fallback: try only last extension (like "js")
	local suffix = parts[#parts]
	local full_suffix = ellipsis .. suffix
	local available = max_width - #full_suffix

	if available >= min_prefix then
		return basename:sub(1, available) .. full_suffix
	end

	-- Total fallback: brute cut
	return filename:sub(1, max_width - ell_len) .. ellipsis
end

function M.truncate_left(filename, path, max_width)
	local sep = "/"
	local fullname = (path == "" and filename) or (path .. sep .. filename)

	---------------------------------------------------------------------------
	-- CASE 0: fits fully
	---------------------------------------------------------------------------
	if vim.fn.strdisplaywidth(fullname) <= max_width then
		local p_start = 0
		local p_end = (path == "" and 0) or (#path + 1)
		local f_start = p_end
		local f_end = vim.fn.strdisplaywidth(fullname)
		return fullname, p_start, p_end, f_start, f_end
	end

	---------------------------------------------------------------------------
	-- CASE 1: left truncation with guaranteed usage of full max_width
	---------------------------------------------------------------------------
	local ell = "…"
	local ell_length = vim.fn.strdisplaywidth(ell)
	local take = max_width - ell_length
	if take < 1 then
		local only = ell:sub(1, max_width)
		return only, 0, 0, #only, #only
	end

	-- Always fill the line fully
	local visible = fullname:sub(vim.fn.strdisplaywidth(fullname) - take + 1)
	local truncated = ell .. visible -- final string length = max_width

	-- Detect slash to split path/filename ranges
	local slash_pos = truncated:match("^.*()/") -- returns position after slash

	if not slash_pos then
		local p_start = 0
		local p_end = 0
		local f_start = ell_length
		local f_end = vim.fn.strdisplaywidth(truncated)
		return truncated, p_start, p_end, f_start, f_end
	end

	local p_start = 0
	local p_end = slash_pos -- include slash
	local f_start = p_end
	local f_end = vim.fn.strdisplaywidth(truncated)
	return truncated, p_start, p_end, f_start, f_end
end

--- Split a full filepath into filename and directory path.
--- Examples:
---   "/a/b/c/init.lua" -> "init.lua", "a/b/c"
---   "src/module/foo.js" -> "foo.js", "src/module"
---   "file.txt" -> "file.txt", ""
---@param filepath string
---@return string filename
---@return string path
function M.split_filepath(filepath)
	-- Normalize backslashes on Windows (same as Snacks)
	filepath = filepath:gsub("\\", "/")

	-- Trim trailing slash (Snacks does this to avoid empty segments)
	if filepath:sub(-1) == "/" then
		filepath = filepath:sub(1, -2)
	end

	-- Find the last slash using Lua pattern search
	local slash = filepath:match("^.*()/")

	if slash then
		local filename = filepath:sub(slash + 1)
		local directory = filepath:sub(1, slash - 1)
		return filename, directory
	else
		-- No slash → only a filename
		return filepath, ""
	end
end

return M
