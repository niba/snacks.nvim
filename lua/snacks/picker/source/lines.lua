local M = {}

---@class snacks.picker
---@field lines fun(opts?: snacks.picker.lines.Config): snacks.Picker

---@param opts snacks.picker.lines.Config
---@type snacks.picker.finder
function M.lines(opts)
  local buf = opts.buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local extmarks = require("snacks.picker.util.highlight").get_highlights({ buf = buf })
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  ---@async
  ---@param cb async fun(item: snacks.picker.finder.Item)
  return function(cb)
    for l, line in ipairs(lines) do
      ---@type snacks.picker.finder.Item
      local item = {
        buf = buf,
        text = line,
        pos = { l, 0 },
        highlights = extmarks[l],
      }
      cb(item)
    end
  end
end

return M
