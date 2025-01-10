---@class snacks.picker.sorter
local M = {}

---@alias snacks.picker.sorter.Field { name: string, desc: boolean }

---@param opts? { fields: (snacks.picker.sorter.Field|string)[] }
function M.default(opts)
  local fields = {} ---@type snacks.picker.sorter.Field[]
  for _, f in ipairs(opts and opts.fields or { { name = "score", desc = true }, "idx" }) do
    if type(f) == "string" then
      table.insert(fields, { name = f, desc = false })
    else
      table.insert(fields, f)
    end
  end

  ---@param a snacks.picker.Item
  ---@param b snacks.picker.Item
  return function(a, b)
    for _, field in ipairs(fields) do
      local av, bv = a[field.name], b[field.name]
      if (av ~= nil) and (bv ~= nil) and (av ~= bv) then
        if field.desc then
          return av > bv
        else
          return av < bv
        end
      end
    end
    return false
  end
end

function M.idx()
  ---@param a snacks.picker.Item
  ---@param b snacks.picker.Item
  return function(a, b)
    return a.idx < b.idx
  end
end

---@param array snacks.picker.Item[]
---@param left number
---@param right number
---@param pivotIndex number
---@param cmp snacks.picker.sorter
local function partition(array, left, right, pivotIndex, cmp)
  local pivotValue = array[pivotIndex]
  array[pivotIndex], array[right] = array[right], array[pivotIndex]

  local storeIndex = left

  for i = left, right - 1 do
    if cmp(array[i], pivotValue) then
      array[i], array[storeIndex] = array[storeIndex], array[i]
      storeIndex = storeIndex + 1
    end
    array[storeIndex], array[right] = array[right], array[storeIndex]
  end

  return storeIndex
end

---@param array snacks.picker.Item[]
---@param left number
---@param right number
---@param cmp snacks.picker.sorter
local function quicksort(array, left, right, cmp)
  if right > left then
    local pivotNewIndex = partition(array, left, right, left, cmp)
    quicksort(array, left, pivotNewIndex - 1, cmp)
    quicksort(array, pivotNewIndex + 1, right, cmp)
  end
end

---@param items snacks.picker.Item[]
---@param cmp snacks.picker.sorter
function M.quicksort(items, cmp)
  quicksort(items, 1, #items, cmp)
end

return M
