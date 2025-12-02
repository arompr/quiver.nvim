local LayoutArrowSection = require("arrow.bookmarks.layout.layout_arrow_section")
local LayoutMenuSection = require("arrow.bookmarks.layout.layout_menu_section")

---@class Layout
---@field get_arrow_section fun():LayoutArrowSection
---@field get_menu_section fun():LayoutMenuSection
---@field get_layout_arrows fun():LayoutArrow[]
---@field get_arrow_section_start_line fun():integer
---@field get_arrow_section_end_line fun():integer
---@field get_total_lines fun():integer
---@field set_arrows fun(arrows: Arrow[])
---@field set_menu_items fun(items: table<string, LayoutMenuItem>)

---@param layout_arrow_section LayoutArrowSection
---@param layout_menu_section LayoutMenuSection
---@return table
local function Layout(layout_arrow_section, layout_menu_section)
	local self = {}

	local sections = {
		arrow = layout_arrow_section,
		menu = layout_menu_section,
	}

	local function arrange()
		layout_arrow_section.set_start_line(1)
		layout_menu_section.set_start_line(layout_arrow_section.get_end_line() + layout_arrow_section.get_break_lines())
	end

	local function refresh()
		arrange()
	end

	self.get_arrow_section = function()
		return sections.arrow
	end

	self.get_menu_section = function()
		return sections.menu
	end

	self.get_arrow_section_start_line = function()
		return sections.arrow.get_start_line()
	end

	self.get_arrow_section_end_line = function()
		return sections.arrow.get_end_line()
	end

	self.get_layout_arrows = function()
		return sections.arrow.get_layout_arrows()
	end

	self.set_arrows = function(arrows)
		sections.arrow.set_arrows(arrows)
		refresh()
	end

	self.set_menu_items = function(menu_items)
		sections.menu.set_menu_items(menu_items)
		refresh()
	end

	self.get_total_lines = function()
		local last_section = sections[#sections]
		return last_section.get_end_line()
	end

	refresh()

	return self
end

---Factory function to create a new Empty layout
---@return Layout
local function EmptyLayout()
	return Layout(LayoutArrowSection(1, {}), LayoutMenuSection(1, {}))
end

return { Layout = Layout, EmptyLayout = EmptyLayout }
