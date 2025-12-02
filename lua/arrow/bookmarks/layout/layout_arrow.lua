---@class LayoutArrow
---@field get_line_number fun(): integer  # The line number of the arrow in the buffer
---@field get_arrow fun():Arrow   # The corresponding arrow object

---Factory function to create a new LayoutArrow
---@param line_number integer
---@param arrow Arrow
---@return LayoutArrow
local function NewLayoutArrow(line_number, arrow)
	local self = {}

	self.get_line_number = function()
		return line_number
	end

	self.get_arrow = function()
		return arrow
	end

	self.line_number = line_number
	self.arrow = arrow

	return self
end

return NewLayoutArrow
