local M = {}

---@enum ItemType
M.TYPE = {
	MENU = "menu",
	ARROW = "arrow",
	TITLE = "title",
	LINE_KEY = "line_key",
	EMPTY = "empty",
}

---@class LayoutItem
---@field type ItemType The type of the item (menu, arrow, empty)
---@field label string The label or text of the item
---@field key string Optional key for lookup
---@field line number Line number of the item in the layout

---@class LayoutBuilder
---@field add_menu fun(label: string, key: string): LayoutBuilder
---@field add_arrow fun(label: string, key: string): LayoutBuilder
---@field add_title fun(label: string): LayoutBuilder
---@field add_breakline fun(count?: number): LayoutBuilder
---@field add_line_key fun(label: string, key: string): LayoutBuilder
---@field get_items fun(): LayoutItem[]
---@field get_all_items fun(): LayoutItem[]
---@field get_items_by_type fun(type_: ItemType): LayoutItem[]
---@field get_item_at_line fun(line: number): LayoutItem|nil
---@field get_item_by_key fun(key: string): LayoutItem|nil

---Create a new layout builder
---@return LayoutBuilder
function M.new()
	-- Internal state
	local items = {} -- array of all items (preserves order)
	local keyMap = {} -- map from key -> item
	local current_line = 0 -- line counter

	---@type LayoutBuilder
	local BUILDER

	local function add_item(type_, label, key)
		local item = {
			type = type_,
			label = label or "",
			key = key,
			line = current_line,
		}

		items[#items + 1] = item
		if key then
			keyMap[key] = item
		end

		current_line = current_line + 1
		return item
	end

	---Add a menu item
	---@param label string
	---@param key string
	---@return LayoutBuilder
	local function add_menu(label, key)
		add_item(M.TYPE.MENU, label, key)
		return BUILDER
	end

	local function add_arrow(label, key)
		add_item(M.TYPE.ARROW, label, key)
		return BUILDER
	end

	local function add_title(label)
		add_item(M.TYPE.TITLE, label)
		return BUILDER
	end

	local function add_breakline(count)
		count = count or 1
		for _ = 1, count do
			add_item(M.TYPE.EMPTY, "")
		end
		return BUILDER
	end

	local function add_line_key(label, key)
		add_item(M.TYPE.LINE_KEY, label, key)
		return BUILDER
	end

	local function get_items()
		local result = {}
		for _, item in ipairs(items) do
			if item.type ~= M.TYPE.EMPTY then
				result[#result + 1] = item
			end
		end
		return result
	end

	local function get_all_items()
		local result = {}
		for _, item in ipairs(items) do
			result[#result + 1] = item
		end
		return result
	end

	local function get_items_by_type(type_)
		local result = {}
		for _, item in ipairs(items) do
			if item.type == type_ then
				result[#result + 1] = item
			end
		end
		return result
	end

	local function get_item_at_line(line)
		for _, item in ipairs(items) do
			if item.line == line then
				return item
			end
		end
		return nil
	end

	local function get_item_by_key(key)
		return keyMap[key]
	end

	BUILDER = {
		add_menu = add_menu,
		add_arrow = add_arrow,
		add_title = add_title,
		add_breakline = add_breakline,
		add_line_key = add_line_key,

		get_items = get_items,
		get_all_items = get_all_items,
		get_items_by_type = get_items_by_type,
		get_item_at_line = get_item_at_line,
		get_item_by_key = get_item_by_key,
	}

	return BUILDER
end

return M
