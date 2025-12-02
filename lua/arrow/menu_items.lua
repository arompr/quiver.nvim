local Action = require("arrow.actions")

---@class MenuItem
---@field id string
---@field label string

---@type table<string, MenuItem>
local MenuItems = {
	SAVE = { id = Action.SAVE, label = "Save Current File" },
	EDIT = { id = Action.EDIT, label = "Edit Arrow Files" },
	DELETE = { id = Action.DELETE, label = "Delete Mode" },
	REMOVE = { id = Action.REMOVE, label = "Remove current file" },
	CLEAR_ALL = { id = Action.CLEAR_ALL, label = "Clear All Items" },
	OPEN_VERTICAL = { id = Action.OPEN_VERTICAL, label = "Open Vertical" },
	OPEN_HORIZONTAL = { id = Action.OPEN_HORIZONTAL, label = "Open Horizontal" },
	NEXT_ITEM = { id = Action.NEXT_ITEM, label = "Next Item" },
	PREV_ITEM = { id = Action.PREV_ITEM, label = "Prev Item" },
	QUIT = { id = Action.QUIT, label = "Quit" },
}

return MenuItems
