local LayoutMenuItem = require("arrow.bookmarks.layout.layout_menu_item")

---@class LayoutMenuSection
---@field get_start_line fun():integer
---@field get_end_line fun():integer
---@field set_menu_items fun(items: table<string, string>)
---@field set_start_line fun(new_start_line: integer)
---@field get_menu_items fun()

---Factory function to create a new LayoutMenuSection
---@param start_line integer
---@param menu_items table<string, string>
---@return LayoutMenuSection
local function LayoutMenuSection(start_line, menu_items)
	local self = {}

	local layout_menu_items = {}

	self.set_menu_items = function(new_menu_items)
		layout_menu_items = {}
		for i, menu_item in ipairs(new_menu_items) do
			layout_menu_items[i] = LayoutMenuItem(start_line + i - 1, menu_item)
		end
	end

	self.set_start_line = function(new_start_line)
		start_line = new_start_line
	end

	self.get_start_line = function()
		return start_line
	end

	self.get_end_line = function()
		return start_line + #layout_menu_items
	end

	self.get_break_lines = function()
		return 1
	end

	self.set_menu_items(menu_items)

	return self
end

return LayoutMenuSection
