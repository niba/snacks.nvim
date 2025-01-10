local M = {}

---@class snacks.picker
---@field pickers fun(opts?: snacks.picker.Config): snacks.Picker

---@param opts snacks.picker.Config
---@type snacks.picker.finder
function M.pickers(opts)
  local me = debug.getinfo(1, "S").source:sub(2)
  local config = vim.fn.fnamemodify(me, ":p:h:h") .. "/config/sources.lua"
  config = vim.fs.normalize(config)
  ---@async
  ---@param cb async fun(item: snacks.picker.finder.Item)
  return function(cb)
    ---@type string[]
    local sources = vim.tbl_keys(opts.sources or {})
    table.sort(sources)
    for _, source in ipairs(sources) do
      cb({
        file = config,
        text = source,
        search = ("/^M\\.%s = {"):format(source),
      })
    end
  end
end

return M
