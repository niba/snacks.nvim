# 🍿 picker

<!-- docgen -->

## 📦 Setup

```lua
-- lazy.nvim
{
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    picker = {
      -- your picker configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  }
}
```

## ⚙️ Config

```lua
---@class snacks.picker.Config
---@field prompt? string
---@field pattern? string|fun():string Pattern used to filter items by the matcher
---@field search? string|fun():string Initial search string used by finders
---@field cwd? string
---@field live? boolean
---@field ui_select? boolean
---@field preset? string|string[]
---@field auto_confirm? boolean Automatically confirm if there is only one item
---@field format? snacks.picker.Formatter|string
---@field items? snacks.picker.finder.Item[]
---@field finder? snacks.picker.finder|string
---@field matcher? snacks.picker.matcher.Config
---@field sorter? snacks.matcher.sorter
---@field actions? table<string, snacks.picker.Action.spec>
---@field win? snacks.picker.win.Config
---@field layout? snacks.layout.Config|{}
---@field preview? snacks.picker.preview.Config
---@field previewer? snacks.picker.Previewer|string
---@field sources? snacks.picker.sources.Config|{}
---@field icons? snacks.picker.icons
---@field source? string
{
  prompt = " ",
  sources = {},
  ui_select = true, -- replace `vim.ui.select` with the snacks picker
  preview = {
    file = {
      max_size = 1024 * 1024, -- 1MB
      max_line_length = 500,
    },
  },
  win = {
    list = {
      keys = {
        ["<CR>"] = "confirm",
        ["gg"] = "list_top",
        ["G"] = "list_bottom",
        ["i"] = "focus_input",
        ["j"] = "list_down",
        ["k"] = "list_up",
        ["q"] = "close",
        ["<Tab>"] = "select_and_next",
        ["<S-Tab>"] = "select_and_prev",
        ["<Down>"] = "list_down",
        ["<Up>"] = "list_up",
        ["<c-d>"] = "list_scroll_down",
        ["<c-u>"] = "list_scroll_up",
        ["zt"] = "list_scroll_top",
        ["zb"] = "list_scroll_bottom",
        ["zz"] = "list_scroll_center",
        ["/"] = "toggle_focus",
        ["<ScrollWheelDown>"] = "list_scroll_wheel_down",
        ["<ScrollWheelUp>"] = "list_scroll_wheel_up",
        ["<c-f>"] = "preview_scroll_down",
        ["<c-b>"] = "preview_scroll_up",
        ["<c-v>"] = "edit_vsplit",
        ["<c-s>"] = "edit_split",
        ["<c-j>"] = "list_down",
        ["<c-k>"] = "list_up",
        ["<c-n>"] = "list_down",
        ["<c-p>"] = "list_up",
      },
    },
    input = {
      keys = {
        ["<esc>"] = "close",
        ["G"] = "list_bottom",
        ["gg"] = "list_top",
        ["j"] = "list_down",
        ["k"] = "list_up",
        ["/"] = "toggle_focus",
        ["q"] = "close",
        ["<C-w>"] = { "<c-s-w>", mode = { "i" }, expr = true },
        ["<C-Up>"] = { "history_back", mode = { "i", "n" } },
        ["<C-Down>"] = { "history_forward", mode = { "i", "n" } },
        ["<Tab>"] = { "select_and_next", mode = { "i", "n" } },
        ["<S-Tab>"] = { "select_and_prev", mode = { "i", "n" } },
        ["<Down>"] = { "list_down", mode = { "i", "n" } },
        ["<Up>"] = { "list_up", mode = { "i", "n" } },
        ["<c-j>"] = { "list_down", mode = { "i", "n" } },
        ["<c-k>"] = { "list_up", mode = { "i", "n" } },
        ["<c-n>"] = { "list_down", mode = { "i", "n" } },
        ["<c-p>"] = { "list_up", mode = { "i", "n" } },
        ["<c-b>"] = { "preview_scroll_up", mode = { "i", "n" } },
        ["<c-d>"] = { "list_scroll_down", mode = { "i", "n" } },
        ["<c-f>"] = { "preview_scroll_down", mode = { "i", "n" } },
        ["<c-g>"] = { "toggle_live", mode = { "i", "n" } },
        ["<c-u>"] = { "list_scroll_up", mode = { "i", "n" } },
        ["<ScrollWheelDown>"] = { "list_scroll_wheel_down", mode = { "i", "n" } },
        ["<ScrollWheelUp>"] = { "list_scroll_wheel_up", mode = { "i", "n" } },
        ["<c-v>"] = { "edit_vsplit", mode = { "i", "n" } },
        ["<c-s>"] = { "edit_split", mode = { "i", "n" } },
        ["<c-q>"] = { "qf", mode = { "i", "n" } },
        ["<a-q>"] = { "qf_all", mode = { "i", "n" } },
        ["<a-i>"] = { "toggle_ignored", mode = { "i", "n" } },
        ["<a-h>"] = { "toggle_hidden", mode = { "i", "n" } },
      },
    },
    preview = {
      minimal = false,
      wo = {
        cursorline = false,
      },
      keys = {
        ["q"] = "close",
        ["i"] = "focus_input",
        ["<ScrollWheelDown>"] = "list_scroll_wheel_down",
        ["<ScrollWheelUp>"] = "list_scroll_wheel_up",
      },
    },
  },
  layout = {
    win = {
      width = 0.8,
      height = 0.8,
      zindex = 50,
      -- border = "rounded",
    },
    layout = {
      box = "horizontal",
      {
        box = "vertical",
        border = "rounded",
        title = " {source} ",
        title_pos = "center",
        width = 0.5,
        { win = "input", height = 1, border = "bottom" },
        { win = "list", border = "none" },
      },
      { win = "preview", border = "rounded" },
    },
  },
  ---@class snacks.picker.icons
  icons = {
    ui = {
      selected = "● ",
      -- selected = " ",
    },
    diagnostics = {
      Error = " ",
      Warn = " ",
      Hint = " ",
      Info = " ",
    },
    kinds = {
      Array         = " ",
      Boolean       = "󰨙 ",
      Class         = " ",
      Color         = " ",
      Control       = " ",
      Collapsed     = " ",
      Constant      = "󰏿 ",
      Constructor   = " ",
      Copilot       = " ",
      Enum          = " ",
      EnumMember    = " ",
      Event         = " ",
      Field         = " ",
      File          = " ",
      Folder        = " ",
      Function      = "󰊕 ",
      Interface     = " ",
      Key           = " ",
      Keyword       = " ",
      Method        = "󰊕 ",
      Module        = " ",
      Namespace     = "󰦮 ",
      Null          = " ",
      Number        = "󰎠 ",
      Object        = " ",
      Operator      = " ",
      Package       = " ",
      Property      = " ",
      Reference     = " ",
      Snippet       = "󱄽 ",
      String        = " ",
      Struct        = "󰆼 ",
      Text          = " ",
      TypeParameter = " ",
      Unit          = " ",
      Uknown        = " ",
      Value         = " ",
      Variable      = "󰀫 ",
    },
  },
}
```

## 📚 Types

```lua
---@class snacks.picker.Last
---@field opts snacks.picker.Config
---@field selected snacks.picker.Item[]
---@field filter snacks.picker.Filter
```

```lua
---@alias snacks.picker.Extmark vim.api.keyset.set_extmark|{col:number}
---@alias snacks.picker.Text {[1]:string, [2]:string?, virtual?:boolean}
---@alias snacks.picker.Highlights (snacks.picker.Text|snacks.picker.Extmark)[]
---@alias snacks.picker.Formatter fun(item:snacks.picker.Item, picker:snacks.Picker):snacks.picker.Highlights
---@alias snacks.matcher.sorter fun(a:snacks.picker.Item, b:snacks.picker.Item):boolean
---@alias snacks.picker.Previewer fun(ctx: snacks.picker.preview.ctx):boolean?
```

```lua
---@class snacks.picker.finder.Item: snacks.picker.Item
---@field idx? number
---@field score? number
```

Generic filter used by finders to pre-filter items

```lua
---@class snacks.picker.filter.Config
---@field cwd? boolean|string only show files for the given cwd
---@field buf? boolean|number only show items for the current or given buffer
---@field paths? table<string, boolean> only show items that include or exclude the given paths
---@field filter? fun(item:snacks.picker.finder.Item):boolean custom filter function
```

```lua
---@class snacks.picker.Item
---@field [string] any
---@field idx number
---@field score number
---@field match_tick? number
---@field text string
---@field pos? {[1]:number, [2]:number}
---@field end_pos? {[1]:number, [2]:number}
---@field highlights? snacks.picker.Highlights[]
```

```lua
---@class snacks.picker.sources.Config
```

```lua
---@class snacks.picker.preview.Config
---@field man_pager? string MANPAGER env to use for `man` preview
---@field file snacks.picker.preview.file.Config
```

```lua
---@class snacks.picker.preview.file.Config
---@field max_size? number default 1MB
---@field max_line_length? number defaults to 500
---@field ft? string defaults to auto-detect
```

```lua
---@class snacks.picker.list.Config: snacks.win.Config
---@field reverse? boolean
```

```lua
---@class snacks.picker.win.Config
---@field input? snacks.win.Config|{}
---@field list? snacks.picker.list.Config|{}
---@field preview? snacks.win.Config|{}
```

## 📦 Module

```lua
---@class snacks.picker
---@field actions snacks.picker.actions
---@field config snacks.picker.config
---@field format snacks.picker.format
---@field util snacks.picker.util
---@field sorter snacks.picker.sorter
---@field preview snacks.picker.preview
---@field current? snacks.Picker
---@field highlight snacks.picker.highlight
Snacks.picker = {}
```

### `Snacks.picker()`

```lua
---@type fun(source: string, opts: snacks.picker.Config): snacks.Picker
Snacks.picker()
```

```lua
---@type fun(opts: snacks.picker.Config): snacks.Picker
Snacks.picker()
```

### `Snacks.picker.disable()`

```lua
Snacks.picker.disable()
```

### `Snacks.picker.enable()`

```lua
Snacks.picker.enable()
```

### `Snacks.picker.pick()`

```lua
---@param source? string
---@param opts? snacks.picker.Config
---@overload fun(opts: snacks.picker.Config): snacks.Picker
Snacks.picker.pick(source, opts)
```

### `Snacks.picker.select()`

```lua
Snacks.picker.select(...)
```

## 📦 `snacks.picker.core.picker`

```lua
---@class snacks.Picker
---@field opts snacks.picker.Config
---@field finder snacks.picker.Finder
---@field format snacks.picker.Formatter
---@field input snacks.picker.input
---@field layout snacks.layout
---@field list snacks.picker.list
---@field matcher snacks.picker.Matcher
---@field parent_win number
---@field preview snacks.picker.Preview
---@field shown? boolean
---@field sorter snacks.matcher.sorter
---@field updater uv.uv_timer_t
---@field start_time number
---@field source_name string
---@field closed? boolean
---@field hist_idx number
---@field hist_cursor number
local M = {}
```

### `picker:action()`

```lua
---@param actions string|string[]
picker:action(actions)
```

### `picker:close()`

```lua
picker:close()
```

### `picker:current()`

```lua
picker:current()
```

### `picker:debug()`

```lua
---@param name string
---@param start? number
picker:debug(name, start)
```

### `picker:filter()`

```lua
---@param pattern string
picker:filter(pattern)
```

### `picker:find()`

```lua
picker:find()
```

### `picker:hist()`

```lua
---@param forward? boolean
picker:hist(forward)
```

### `picker:is_active()`

```lua
picker:is_active()
```

### `picker:items()`

```lua
---@return fun():snacks.picker.Item?
picker:items()
```

### `picker:progress()`

```lua
picker:progress(ms)
```

### `picker:selected()`

```lua
---@param opts? {fallback?: boolean} If fallback is true (default), then return current item if no selected items
picker:selected(opts)
```

### `picker:show()`

```lua
picker:show()
```

### `picker:show_preview()`

```lua
picker:show_preview()
```

### `picker:update()`

```lua
picker:update()
```


