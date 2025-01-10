---@class snacks.picker.topk
---@field data any[]
---@field cmp fun(a:any, b:any):boolean
---@field capacity number
---@field min? any
local M = {}
M.__index = M

---@class snacks.picker.topk.Config
---@field cmp? fun(a, b):boolean
---@field capacity number

---@param opts? snacks.picker.topk.Config
function M.new(opts)
  opts = opts or {}
  local self = setmetatable({}, M)
  self.cmp = opts.cmp or function(a, b)
    return a > b -- default is max topk
  end
  self.data = {}
  self.capacity = assert(opts.capacity)
  return self
end

function M:clear()
  self.data = {}
end

function M:_add(value)
  local low, high = 1, #self.data
  while low <= high do
    local mid = math.floor((low + high) / 2) --[[@as number]]
    if self.cmp(value, self.data[mid]) then
      high = mid - 1
    else
      low = mid + 1
    end
  end
  table.insert(self.data, low, value)
end

---@generic T
---@param value T
---@return boolean added, T? prev
function M:add(value)
  if self.capacity == 0 then
    return false
  end
  if #self.data < self.capacity then
    self:_add(value)
    return true
  elseif self.cmp(value, self.data[#self.data]) then
    local prev = table.remove(self.data)
    self:_add(value)
    return true, prev
  end
  return false
end

function M:count()
  return #self.data
end

function M:min()
  return self.data[1]
end

function M:max()
  return self.data[#self.data]
end

function M:get()
  local ret = {}
  for i = 1, #self.data do
    table.insert(ret, self.data[i])
  end
  return ret
end

return M
