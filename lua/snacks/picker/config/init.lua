---@class snacks.picker.config
local M = {}

---@param opts? snacks.picker.Config
function M.get(opts)
  M.setup()
  opts = opts or {}

  local sources = require("snacks.picker.config.sources")
  local defaults = require("snacks.picker.config.defaults").defaults
  defaults.sources = sources
  local user = Snacks.config.picker or {}

  local global = Snacks.config.get("picker", defaults) -- defaults + global user config
  local todo = {
    defaults,
    user,
    opts.source and global.sources[opts.source] or {},
    opts,
  }
  local ret = vim.tbl_deep_extend("force", unpack(todo))
  ret.layouts = ret.layouts or {}
  local layouts = require("snacks.picker.config.layouts")
  for k, v in pairs(layouts or {}) do
    ret.layouts[k] = ret.layouts[k] or v
  end
  return ret
end

--- Resolve the layout configuration
---@param opts snacks.picker.Config|string
function M.layout(opts)
  opts = type(opts) == "string" and { layout = { preset = opts } } or opts
  local layouts = require("snacks.picker.config.layouts")
  local layout = M.resolve(opts.layout or {}, opts.source)
  if layout.layout then
    return layout
  end
  local preset = M.resolve(layout.preset or "custom", opts.source)
  local ret = vim.deepcopy(opts.layouts and opts.layouts[preset] or layouts[preset] or {})
  ret = vim.tbl_deep_extend("force", ret, layout or {})
  ret.preset = nil
  return ret
end

---@generic T
---@generic A
---@param v (fun(...:A):T)|unknown
---@param ... A
---@return T
function M.resolve(v, ...)
  return type(v) == "function" and v(...) or v
end

--- Get the finder
---@param finder string|snacks.picker.finder
---@return snacks.picker.finder
function M.finder(finder)
  if not finder or type(finder) == "function" then
    return finder
  end
  local mod, fn = finder:match("^(.-)_(.+)$")
  if not (mod and fn) then
    mod, fn = finder, finder
  end
  return require("snacks.picker.source." .. mod)[fn]
end

local did_setup = false
function M.setup()
  if did_setup then
    return
  end
  did_setup = true
  require("snacks.picker.config.highlights")
  for source in pairs(Snacks.picker.config.get().sources) do
    Snacks.picker[source] = function(opts)
      return Snacks.picker.pick(source, opts)
    end
  end
end

return M
