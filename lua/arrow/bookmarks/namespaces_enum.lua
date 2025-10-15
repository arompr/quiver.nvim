---@enum Namespaces
local Namespaces = {
	FILE_INDEX = vim.api.nvim_create_namespace("arrow_file_index"),
	CURRENT_FILE = vim.api.nvim_create_namespace("arrow_current_file"),
	ACTION = vim.api.nvim_create_namespace("arrow_action"),
	DELETE_MODE = vim.api.nvim_create_namespace("arrow_delete_mode"),
	SAVE_MODE = vim.api.nvim_create_namespace("arrow_save_mode"),
}

return Namespaces
