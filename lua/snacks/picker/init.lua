---@class snacks.picker
---@field actions snacks.picker.actions
---@field config snacks.picker.config
---@field format snacks.picker.format
---@field util snacks.picker.util
---@field sorter snacks.picker.sorter
---@field preview snacks.picker.preview
---@field current? snacks.Picker
---@field highlight snacks.picker.highlight
---@overload fun(opts: snacks.picker.Config): snacks.Picker
---@overload fun(source: string, opts: snacks.picker.Config): snacks.Picker
local M = setmetatable({}, {
  __call = function(M, ...)
    return M.pick(...)
  end,
  __index = function(M, k)
    if k == "setup" then
      return
    end
    local mods = { "actions", "config", "format", "preview", "util", "sorter", highlight = "util.highlight" }
    for m, mod in pairs(mods) do
      mod = mod == k and k or m == k and mod or nil
      if mod then
        ---@diagnostic disable-next-line: no-unknown
        M[k] = require("snacks.picker." .. mod)
        return rawget(M, k)
      end
    end
    M.config.setup()
    return rawget(M, k)
  end,
})

---@type snacks.meta.Meta
M.meta = {
  desc = "Picker for selecting items",
  needs_setup = true,
  merge = { config = "config.defaults", picker = "core.picker" },
}

local ui_select = vim.ui.select

-- create actual picker functions for autocomplete
vim.schedule(M.config.setup)

---@param source? string
---@param opts? snacks.picker.Config
---@overload fun(opts: snacks.picker.Config): snacks.Picker
function M.pick(source, opts)
  if not opts and type(source) == "table" then
    opts, source = source, nil
  end
  opts = opts or {}
  opts.source = source or opts.source
  if not opts.source then
    opts.source = "pickers"
    return M.pick(opts)
  end
  return require("snacks.picker.core.picker").new(opts)
end

function M.select(...)
  return require("snacks.picker.select").select(...)
end

function M.enable()
  local config = M.config.get()
  if config.ui_select then
    vim.ui.select = M.select
    -- FIXME: remove
    vim.defer_fn(function()
      vim.ui.select = M.select
    end, 100)
  end
end

function M.disable()
  vim.ui.select = ui_select
end

---@private
function M.health()
  require("snacks.picker.core._health").health()
end

return M
