# 🍿 picker

<!-- docgen -->

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

### `Snacks.picker()`

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
