local NewLayoutArrow = require("arrow.bookmarks.layout.layout_arrow")

---@class LayoutArrowSection
---@field get_start_line fun():integer
---@field get_end_line fun():integer
---@field get_layout_arrows fun():LayoutArrow[]
---@field get_arrows fun():Arrow[]
---@field set_arrows fun(arrows: Arrow[])
---@field set_start_line fun(new_start_line: integer)
---@field get_break_lines fun():integer number of blank lines after this section

---Factory function to create a new LayoutArrowSection
---@param start_line integer
---@param arrows Arrow[]
---@return LayoutArrowSection
local function LayoutArrowSection(start_line, arrows)
	local self = {}

	local layout_arrows = {}

	self.get_start_line = function()
		return start_line
	end

	self.get_end_line = function()
		return start_line + #layout_arrows
	end

	self.get_layout_arrows = function()
		return layout_arrows
	end

	self.get_arrows = function()
		return layout_arrows
	end

	self.set_arrows = function(new_arrows)
		layout_arrows = {}
		for i, arrow in ipairs(new_arrows) do
			layout_arrows[i] = NewLayoutArrow(start_line + i - 1, arrow)
		end
	end

	self.get_break_lines = function()
		return 1
	end

	self.set_start_line = function(new_start_line)
		start_line = new_start_line
	end

	self.set_arrows(arrows)

	return self
end

return LayoutArrowSection
