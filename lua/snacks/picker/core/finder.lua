local Async = require("snacks.picker.util.async")

---@class snacks.picker.Finder
---@field _find snacks.picker.finder
---@field task snacks.picker.Async
---@field items snacks.picker.finder.Item[]
---@field filter? snacks.picker.Filter
local M = {}
M.__index = M

---@alias snacks.picker.finder fun(opts:snacks.picker.Config, filter:snacks.picker.Filter): (snacks.picker.finder.Item[] | fun(cb:async fun(item:snacks.picker.finder.Item)))

local YIELD_FIND = 5 -- ms

---@param find snacks.picker.finder
function M.new(find)
  local self = setmetatable({}, M)
  self._find = find
  self.task = Async.nop()
  self.items = {}
  return self
end

function M:running()
  return self.task:running()
end

function M:abort()
  self.task:abort()
end

function M:count()
  return #self.items
end

---@param search string
function M:changed(search)
  search = vim.trim(search)
  return not self.filter or self.filter.search ~= search
end

---@param picker snacks.Picker
function M:run(picker)
  self.task:abort()
  self.items = {}
  local yield ---@type fun()
  collectgarbage("stop") -- moar speed
  self.filter = picker.input.filter:clone({ trim = true })
  local finder = self._find(picker.opts, self.filter)
  local limit = picker.opts.limit or math.huge
  if type(finder) == "table" then
    local items = finder --[[@as snacks.picker.finder.Item[] ]]
    finder = function(cb)
      for _, item in ipairs(items) do
        cb(item)
      end
    end
  end
  ---@cast finder fun(cb:async fun(item:snacks.picker.finder.Item))
  self.task = Async.new(function()
    ---@async
    finder(function(item)
      if #self.items >= limit then
        self.task:abort()
        if coroutine.running() then
          Async.yield()
        end
        return
      end
      item.idx = #self.items + 1
      self.items[item.idx] = item
      picker.matcher.task:resume()
      yield = yield or Async.yielder(YIELD_FIND)
      yield()
    end)
  end):on("done", function()
    collectgarbage("restart")
    picker.matcher.task:resume()
    picker:update()
  end)
end

return M
