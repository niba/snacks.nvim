# 🍿 layout

<!-- docgen -->

## 📦 Setup

```lua
-- lazy.nvim
{
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    layout = {
      -- your layout configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  }
}
```

## ⚙️ Config

```lua
---@class snacks.layout.Config
---@field wins table<string, snacks.win>
---@field layout snacks.layout.Box
---@field fullscreen? boolean open in fullscreen
---@field hidden? string[] list of windows that will be excluded from the layout
---@field on_update? fun(layout: snacks.layout)
{
  layout = {
    width = 0.6,
    height = 0.6,
    zindex = 50,
  },
}
```

## 📚 Types

```lua
---@class snacks.layout.Win: snacks.win.Config,{}
---@field depth? number
---@field win string
```

```lua
---@class snacks.layout.Box: snacks.layout.Win,{}
---@field box "horizontal" | "vertical"
---@field id? number
---@field [number] snacks.layout.Win | snacks.layout.Box
```

```lua
---@alias snacks.layout.Widget snacks.layout.Win | snacks.layout.Box
```

## 📦 Module

```lua
---@class snacks.layout
---@field opts snacks.layout.Config
---@field root snacks.win
---@field wins table<string, snacks.win|{enabled?:boolean}>
---@field box_wins snacks.win[]
---@field win_opts table<string, snacks.win.Config>
---@field closed? boolean
Snacks.layout = {}
```

### `Snacks.layout.new()`

```lua
---@param opts snacks.layout.Config
Snacks.layout.new(opts)
```

### `layout:close()`

```lua
---@param opts? {wins?: boolean}
layout:close(opts)
```

### `layout:each()`

```lua
---@param cb fun(widget: snacks.layout.Widget, parent?: snacks.layout.Box)
---@param opts? {wins?:boolean, boxes?:boolean, box?:snacks.layout.Box}
layout:each(cb, opts)
```

### `layout:is_enabled()`

```lua
---@param w string
layout:is_enabled(w)
```

### `layout:is_hidden()`

```lua
---@param win string
layout:is_hidden(win)
```

### `layout:maximize()`

Toggle fullscreen

```lua
layout:maximize()
```

### `layout:show()`

```lua
layout:show()
```

### `layout:toggle()`

```lua
---@param win string
layout:toggle(win)
```

### `layout:valid()`

```lua
layout:valid()
```
