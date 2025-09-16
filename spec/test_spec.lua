---@diagnostic disable: undefined-field

local setup_vim_mock = require("spec.helpers.vim_mock")

-- spec/persist_spec.lua
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
local persist = require("arrow.persist")
local storage = persist.storage

-- Mock config module
local config = require("arrow.config")
config.getState = function(key)
	local states = {
		relative_path = false,
		global_bookmarks = false,
	}
	return states[key]
end

setup_vim_mock()

describe("persist.is_saved", function()
	before_each(function()
		storage.arrow_filenames = {}
	end)

	it("returns nil when filename is not saved", function()
		storage.arrow_filenames = { "file1.txt", "file2.txt" }
		assert.are.equal(nil, persist.is_saved("missing.txt"))
	end)

	it("returns the index of the saved filename", function()
		storage.arrow_filenames = { "file1.txt", "file2.txt" }
		assert.are.equal(1, persist.is_saved("file1.txt"))
		assert.are.equal(2, persist.is_saved("file2.txt"))
	end)

	it("handles relative_path prefix when enabled", function()
		config.getState = function(key)
			local states = {
				relative_path = true,
				global_bookmarks = false,
			}
			return states[key]
		end

		storage.arrow_filenames = { "file1.txt", "file2.txt" }

		assert.are.equal(1, persist.is_saved("file1.txt"))
		assert.are.equal(2, persist.is_saved("file2.txt"))
		assert.are.equal(1, persist.is_saved("./file1.txt"))
	end)
end)
