# quiver.nvim -- WIP

> A fork of [arrow.nvim](https://github.com/otavioschwanck/arrow.nvim) that adds **specific key-to-file mappings**, inspired by [harpoon](https://github.com/ThePrimeagen/harpoon), while keeping Arrow’s clean UI and workflow.

I loved using [arrow.nvim](https://github.com/otavioschwanck/arrow.nvim) — it’s elegant, minimal, and makes managing file bookmarks seamless.  
But in large codebases, I ran into one small problem:

- Arrow is **index-based**, so when I rearranged my files, the key assignments would shift.  
- The result: files I kept ended up on a different key than the one I got used to.  

That’s why I created **quiver.nvim**:

- It extends Arrow’s functionality with the ability to **map specific keys directly to files**.  
- This means that, like Harpoon, you can bind a file to a particular letter (`a`, `s`, `d`, etc.) while still benefiting from arrow.nvim’s single-UI experience.  
- If you don’t care about fixed keys, then arrow.nvim is probably what you want to stick to.  

<img width="546" height="445" alt="image" src="https://github.com/user-attachments/assets/4fe97bf0-9a6b-4495-b7ad-682bb2458006" />

## Todos
- [] Add remove functionality
- [] Map keys through usecases
- [] Add toggle to next available key functionality
- [] Add reassign to key functionality
- [] Add assignable keys to menu

## Installation

### Lazy

```lua
return {
  "arompr/quiver.nvim",
  dependencies = {
    { "nvim-tree/nvim-web-devicons" },
    -- or if using `mini.icons`
    -- { "echasnovski/mini.icons" },
  },
  opts = {
    show_icons = true,
    leader_key = 'm', -- Recommended to be a single key
    buffer_leader_key = 'M', -- Per Buffer Mappings
  }
}
```

### Packer

```lua
use { 'arompr/quiver.nvim', config = function()
  require('arrow').setup({
    show_icons = true,
    leader_key = 'm', -- Recommended to be a single key
    buffer_leader_key = 'M', -- Per Buffer Mappings
  })
end }
```

## Usage

Just press the leader_key set on setup and follow you heart. (Is that easy)

## Difference from arrow:

- Key-to-file mapping: Assign specific files to specific keys, avoiding accidental shifts when rearranging bookmarks.
  
## Differences from harpoon:

- Single keymap needed
- Different UI to manage the bookmarks
- Statusline helpers
- Has colors and icons <3
- Has the delete mode to quickly delete items
- Files can be opened vertically or horizontally
- Still has the option to edit file

## Advanced Setup

```lua
{
  show_icons = true,
  separate_by_branch = false, -- Bookmarks will be separated by git branch
  hide_handbook = false, -- set to true to hide the shortcuts on menu.
  hide_buffer_handbook = false, --set to true to hide shortcuts on buffer menu
  save_path = function()
    return vim.fn.stdpath("cache") .. "/arrow"
  end,
  mappings = {
    edit = "e",
    delete_mode = "d",
    clear_all_items = "C",
    toggle = "s",
    open_vertical = "v",
    open_horizontal = "-",
    quit = "q",
    remove = "x",
    next_item = "]",
    prev_item = "["
  },
  custom_actions = {
    open = function(target_file_name, current_file_name) end, -- target_file_name = file selected to be open, current_file_name = filename from where this was called
    split_vertical = function(target_file_name, current_file_name) end,
    split_horizontal = function(target_file_name, current_file_name) end,
  },
  window = { -- controls the appearance and position of an arrow window (see nvim_open_win() for all options)
    width = 50,
    height = "auto",
    row = "auto",
    col = "auto",
    border = "double",
  },
  per_buffer_config = {
    lines = 4, -- Number of lines showed on preview.
    sort_automatically = true, -- Auto sort buffer marks.
    satellite = { -- default to nil, display arrow index in scrollbar at every update
      enable = false,
      overlap = true,
      priority = 1000,
    },
    zindex = 10, --default 50
    treesitter_context = nil, -- it can be { line_shift_down = 2 }, currently not usable, for detail see https://github.com/otavioschwanck/arrow.nvim/pull/43#issue-2236320268
  },
  separate_save_and_remove = false, -- if true, will remove the toggle and create the save/remove keymaps.
  leader_key = ";",
  save_key = "cwd", -- what will be used as root to save the bookmarks. Can be also `git_root` and `git_root_bare`.
  global_bookmarks = false, -- if true, arrow will save files globally (ignores separate_by_branch)
  index_keys = "123456789zxcbnmZXVBNM,afghjklAFGHJKLwrtyuiopWRTYUIOP", -- keys mapped to bookmark index, i.e. 1st bookmark will be accessible by 1, and 12th - by c
  full_path_list = { "update_stuff" } -- filenames on this list will ALWAYS show the file path too.
}
```

You can also map previous and next key:

```lua
vim.keymap.set("n", "H", require("arrow.persist").previous)
vim.keymap.set("n", "L", require("arrow.persist").next)
vim.keymap.set("n", "<C-s>", require("arrow.persist").toggle)
```

### Please, buy otavioschwanck, the original arrow dev a coffee

https://www.buymeacoffee.com/otavioschwanck
