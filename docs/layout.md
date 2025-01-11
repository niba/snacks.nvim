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
---@field win? snacks.words.Config|{}
---@field wins table<string, snacks.win>
---@field layout snacks.layout.Box
{
  win = {
    width = 0.6,
    height = 0.6,
    zindex = 50,
  },
}
```

## 📚 Types

```lua
---@class snacks.layout.Dim: snacks.win.Dim
---@field depth number
```

```lua
---@class snacks.layout.Base
---@field width? number
---@field min_width? number
---@field max_width? number
---@field height? number
---@field min_height? number
---@field max_height? number
---@field col? number
---@field row? number
---@field border? string
---@field depth? number
```

```lua
---@class snacks.layout.Win: snacks.layout.Base, snacks.win.Config,{}
---@field win string
```

```lua
---@class snacks.layout.Box: snacks.layout.Base
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
---@field win snacks.win
---@field wins table<string, snacks.win|{enabled?:boolean}>
---@field box_wins snacks.win[]
---@field win_opts table<string, snacks.win.Config>
Snacks.layout = {}
```

### `Snacks.layout.new()`

```lua
---@param opts snacks.layout.Config
Snacks.layout.new(opts)
```

### `layout:close()`

```lua
layout:close()
```

### `layout:each()`

```lua
---@param cb fun(widget: snacks.layout.Widget)
---@param opts? {wins?:boolean, boxes?:boolean}
layout:each(cb, opts)
```

### `layout:show()`

```lua
layout:show()
```

### `layout:valid()`

```lua
layout:valid()
```
