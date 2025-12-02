---@class LayoutMenuItem
---@field get_line_number fun():integer
---@field get_name fun():string

---Factory function to create a new LayoutMenuItem
---@param line_number integer
---@param name string
---@return LayoutMenuItem
local function LayoutMenuItem(line_number, name)
	local self = {}

	self.get_line_number = function()
		return line_number
	end

	self.get_name = function()
		return name
	end

	return self
end

return LayoutMenuItem
