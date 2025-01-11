---@class snacks.picker.config
local M = {}

---@param opts? snacks.picker.Config
function M.get(opts)
  M.setup()
  opts = opts or {}

  local sources = require("snacks.picker.config.sources")
  local presets = require("snacks.picker.config.presets")
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
  local merge = {} ---@type snacks.picker.Config[]

  local layout = defaults.layout.layout

  local function add(o)
    if o then
      o = vim.deepcopy(o) ---@type snacks.picker.Config
      if o.layout and o.layout.layout then
        layout = o.layout.layout
      end
      merge[#merge + 1] = o
    end
  end

  for _, o in ipairs(todo) do
    local preset = o.preset
    preset = type(preset) == "table" and preset or { preset }
    ---@cast preset string[]
    for _, p in ipairs(preset) do
      add(presets[p])
    end
    add(o)
  end

  opts = vim.tbl_deep_extend("force", unpack(merge))
  opts.layout.layout = layout
  return opts
end

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
