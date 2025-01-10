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

M.meta = {
  desc = "Picker for selecting items",
}

local ui_select = vim.ui.select

-- create actual picker functions for autocomplete
vim.schedule(M.config.setup)

---@param source? string
---@param opts? snacks.picker.Config
---@overload fun(opts: snacks.picker.Config): snacks.Picker
function M.pick(source, opts)
  if not source and not opts then
    return M.pick("pickers")
  end
  if not opts and type(source) == "table" then
    opts, source = source, nil
  end
  opts = opts or {}
  opts.source = source or opts.source
  return require("snacks.picker.core.picker").new(opts)
end

function M.resume()
  local last = require("snacks.picker.core.picker").last
  if not last then
    Snacks.notify.error("No picker to resume")
    return
  end
  last.opts.pattern = last.filter.pattern
  last.opts.search = last.filter.search
  local ret = M.pick(last.opts)
  ret.list:set_selected(last.selected)
  ret.list:update()
  ret.input:update()
  return ret
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
