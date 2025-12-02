require("spec.helpers")

local LayoutArrowSection = require("arrow.bookmarks.layout.layout_arrow_section")

describe("LayoutArrowSection", function()
	local function make_arrows(n)
		local arrows = {}
		for i = 1, n do
			table.insert(arrows, { key = string.char(96 + i), filename = "path_to_file" })
		end
		return arrows
	end

	it("when there are no arrows then end line equals start line", function()
		local layout_arrow_section = LayoutArrowSection(1, make_arrows(0))
		assert.are.equal(layout_arrow_section.get_start_line(), layout_arrow_section.get_end_line())
	end)

	it("when there is one arrow then end line is one more than start line", function()
		local layout_arrow_section = LayoutArrowSection(1, make_arrows(1))
		assert.are.equal(layout_arrow_section.get_start_line() + 1, layout_arrow_section.get_end_line())
	end)

	it("when there are n arrows then end line is n more than start line", function()
		local n = 2
		local layout_arrow_section = LayoutArrowSection(1, make_arrows(n))
		assert.are.equal(layout_arrow_section.get_start_line() + n, layout_arrow_section.get_end_line())
	end)
end)
