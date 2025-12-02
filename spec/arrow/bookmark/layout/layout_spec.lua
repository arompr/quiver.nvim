require("spec.helpers")

local Layout = require("arrow.bookmarks.layout.layout_builder")

describe("Layout Builder", function()
	local layout = Layout.new()

	before_each(function()
		layout = Layout.new()
	end)

	it("adds menu items and tracks line numbers", function()
		layout.add_breakline()
		layout.add_menu("Open", "open")
		layout.add_menu("Save", "save")
		local items = layout.get_items()

		assert.are.equal(2, #items)
		assert.are.same({ type = Layout.TYPE.MENU, label = "Open", line = 1, key = "open" }, items[1])
		assert.are.same({ type = Layout.TYPE.MENU, label = "Save", line = 2, key = "save" }, items[2])
	end)

	it("adds arrows and tracks line numbers", function()
		layout.add_arrow("Next", "a")
		layout.add_arrow("Prev", "b")
		local arrows = layout.get_items_by_type(Layout.TYPE.ARROW)

		assert.are.equal(2, #arrows)
		assert.are.same("Next", arrows[1].label)
		assert.are.same("Prev", arrows[2].label)
	end)

	it("adds breaklines correctly", function()
		layout.add_breakline(3)
		local items = layout.get_items()
		assert.are.equal(0, #items)
	end)

	it("supports optional keys and lookup by key", function()
		layout.add_menu("Delete", "delete_key")
		layout.add_arrow("Next Arrow", "next_arrow")

		local deleteItem = layout.get_item_by_key("delete_key")
		assert.is_not_nil(deleteItem)
		assert.are.equal("Delete", deleteItem.label)
		assert.are.equal(Layout.TYPE.MENU, deleteItem.type)

		local nextArrow = layout.get_item_by_key("next_arrow")
		assert.is_not_nil(nextArrow)
		assert.are.equal(Layout.TYPE.ARROW, nextArrow.type)
	end)

	it("retrieves items by type", function()
		layout.add_menu("Open", "open")
		layout.add_arrow("Right", "r")
		layout.add_menu("Save", "save")
		local menus = layout.get_items_by_type(Layout.TYPE.MENU)
		local arrows = layout.get_items_by_type(Layout.TYPE.ARROW)

		assert.are.equal(2, #menus)
		assert.are.equal(1, #arrows)
		assert.are.equal("Open", menus[1].label)
		assert.are.equal("Save", menus[2].label)
		assert.are.equal("Right", arrows[1].label)
	end)

	it("retrieves item at specific line", function()
		layout.add_menu("Open", "open")
		layout.add_arrow("Arrow1", "a")
		layout.add_breakline()
		layout.add_menu("Save", "save")

		local item1 = layout.get_item_at_line(0)
		local item2 = layout.get_item_at_line(1)
		local item3 = layout.get_item_at_line(3)

		assert.are.equal("Open", item1.label)
		assert.are.equal("Arrow1", item2.label)
		assert.are.equal("Save", item3.label)
	end)

	it("increments line numbers correctly with mixed items", function()
		layout.add_menu("A", "A")
		layout.add_breakline(2)
		layout.add_arrow("Arrow", "a")
		layout.add_menu("B", "b")

		local items = layout.get_items()
		assert.are.equal(3, #items)
		assert.are.equal(0, items[1].line)
		assert.are.equal(3, items[2].line)
		assert.are.equal(4, items[3].line)
	end)
end)
