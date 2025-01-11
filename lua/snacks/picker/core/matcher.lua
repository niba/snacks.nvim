local Async = require("snacks.picker.util.async")

---@class snacks.picker.Matcher
---@field opts snacks.picker.matcher.Config
---@field mods snacks.picker.matcher.Mods[][]
---@field one? snacks.picker.matcher.Mods
---@field pattern string
---@field min_score number
---@field tick number
---@field task snacks.picker.Async
---@field live? boolean
local M = {}
M.__index = M

local YIELD_MATCH = 5 -- ms
local clear = require("table.clear")

---@class snacks.picker.matcher.Config
---@field fuzzy? boolean
---@field smartcase? boolean
---@field ignorecase? boolean

---@class snacks.picker.matcher.Mods
---@field pattern string
---@field entropy number higher entropy is less likely to match
---@field field? string
---@field ignorecase? boolean
---@field fuzzy? boolean
---@field word? boolean
---@field exact_suffix? boolean
---@field exact_prefix? boolean
---@field inverse? boolean

-- PERF: reuse tables to avoid allocations and GC
local fuzzy_positions = {} ---@type number[]
local fuzzy_best_positions = {} ---@type number[]
local fuzzy_last_positions = {} ---@type number[]
local fuzzy_fast_positions = {} ---@type number[]

---@param t number[]
function M.clear(t)
  clear(t) -- luajit table.clear is faster
  return t
end

---@param opts? snacks.picker.matcher.Config
function M.new(opts)
  local self = setmetatable({}, M)
  self.opts = vim.tbl_deep_extend("force", {
    fuzzy = true,
    smartcase = true,
    ignorecase = true,
  }, opts or {})
  self.pattern = ""
  self.min_score = 0
  self.task = Async.nop()
  self.mods = {}
  self.live = false
  self.tick = 0
  return self
end

function M:empty()
  return not next(self.mods)
end

function M:running()
  return self.task:running()
end

function M:abort()
  self.task:abort()
end

---@param picker snacks.Picker
---@param opts? {prios?: snacks.picker.Item[]}
function M:run(picker, opts)
  opts = opts or {}
  if self.task:running() then
    return
  end
  ---@async
  self.task = Async.new(function()
    local yield = Async.yielder(YIELD_MATCH)
    local idx = 0

    ---@async
    ---@param item snacks.picker.Item
    local function check(item)
      if self:update(item) and item.score > 0 then
        picker.list:add(item)
      end
      yield()
    end

    -- process high priority items first
    for _, item in ipairs(opts.prios or {}) do
      check(item)
    end

    repeat
      -- then the rest
      while idx < #picker.finder.items do
        idx = idx + 1
        check(picker.finder.items[idx])
      end

      -- suspend till we have more items
      if picker.finder.task:running() then
        Async.suspend()
      end
    until idx >= #picker.finder.items and not picker.finder.task:running()
    -- table.sort(picker.list.items, picker.sorter)

    picker:update()
  end)
end

---@param opts? {pattern?: string, live?: boolean}
function M:init(opts)
  opts = opts or {}
  self.tick = self.tick + 1
  local pattern = vim.trim(opts.pattern or self.pattern)
  self.mods = {}
  self.min_score = 0
  self.pattern = pattern
  self:abort()
  self.one = nil
  self.live = opts.live
  if pattern == "" then
    return
  end
  local is_or = false
  for _, p in ipairs(vim.split(pattern, " +")) do
    if p == "|" then
      is_or = true
    else
      local mods = self:_prepare(p)
      if mods.pattern ~= "" then
        if is_or and #self.mods > 0 then
          table.insert(self.mods[#self.mods], mods)
        else
          table.insert(self.mods, { mods })
        end
      end
      is_or = false
    end
  end
  for _, ors in ipairs(self.mods) do
    -- sort by entropy, lower entropy is more likely to match
    table.sort(ors, function(a, b)
      return a.entropy < b.entropy
    end)
  end
  -- sort by entropy, higher entropy is less likely to match
  table.sort(self.mods, function(a, b)
    return a[1].entropy > b[1].entropy
  end)
  if #self.mods == 1 and #self.mods[1] == 1 then
    self.one = self.mods[1][1]
  end
end

---@param pattern string
---@return snacks.picker.matcher.Mods
function M:_prepare(pattern)
  ---@type snacks.picker.matcher.Mods
  local mods = { pattern = pattern, entropy = 0 }
  local field, p = pattern:match("^([%w_]+):(.*)$")
  if field then
    mods.field = field
    mods.pattern = p
  end
  mods.ignorecase = self.opts.ignorecase
  local is_lower = mods.pattern:lower() == mods.pattern
  if self.opts.smartcase then
    mods.ignorecase = is_lower
  end
  mods.fuzzy = self.opts.fuzzy
  if not mods.fuzzy then
    mods.entropy = mods.entropy + 10
  end
  if mods.pattern:sub(1, 1) == "!" then
    mods.fuzzy, mods.inverse = false, true
    mods.pattern = mods.pattern:sub(2)
    mods.entropy = mods.entropy - 1
  end
  if mods.pattern:sub(1, 1) == "'" then
    mods.fuzzy = false
    mods.pattern = mods.pattern:sub(2)
    mods.entropy = mods.entropy + 10
    if mods.pattern:sub(-1, -1) == "'" then
      mods.word = true
      mods.pattern = mods.pattern:sub(1, -2)
      mods.entropy = mods.entropy + 10
    end
  elseif mods.pattern:sub(1, 1) == "^" then
    mods.fuzzy, mods.exact_prefix = false, true
    mods.pattern = mods.pattern:sub(2)
    mods.entropy = mods.entropy + 20
  end
  if mods.pattern:sub(-1, -1) == "$" then
    mods.fuzzy = false
    mods.exact_suffix = true
    mods.pattern = mods.pattern:sub(1, -2)
    mods.entropy = mods.entropy + 20
  end
  local rare_chars = #mods.pattern:gsub("[%w%s]", "")
  mods.entropy = mods.entropy + math.min(#mods.pattern, 20) + rare_chars * 2
  if not mods.ignorecase and not is_lower then
    mods.entropy = mods.entropy * 2
  end
  return mods
end

---@param item snacks.picker.Item
---@return boolean updated
function M:update(item)
  if item.match_tick == self.tick then
    return false
  end
  local score = self:match(item)
  item.match_tick, item.score = self.tick, score
  return true
end

---@param item snacks.picker.Item
---@param opts? {positions: boolean, force?: boolean}
---@return number score, number[]? positions
function M:match(item, opts)
  opts = opts or {}
  if self:empty() or (self.live and not opts.force) then
    return 1000 -- empty pattern matches everything
  end
  local score = 0
  local positions = opts.positions and {} or nil ---@type number[]?
  if self.one then
    score = self:_match(item, self.one, positions) or 0
    return score, positions
  end
  for _, ors in ipairs(self.mods) do
    local s = 0 ---@type number?
    local p = opts.positions and {} or nil ---@type number[]?
    if #ors == 1 then
      s = self:_match(item, ors[1], p)
    else
      for _, mods in ipairs(ors) do
        s = self:_match(item, mods, p)
        if s then
          break
        end
      end
    end
    if s then
      score, positions = M:merge(score, positions, s, p)
    else
      return 0
    end
  end
  return score, positions
end

---@param score_a? number
---@param positions_a? number[]
---@param score_b? number
---@param positions_b? number[]
function M:merge(score_a, positions_a, score_b, positions_b)
  local positions = positions_a or positions_b
  if positions_a and positions_b then
    table.move(positions_b, 1, #positions_b, #positions + 1, positions)
  end
  return score_a + score_b, positions
end

---@param str string
---@param c number
function M.is_alpha(str, c)
  local b = str:byte(c, c)
  return (b >= 65 and b <= 90) or (b >= 97 and b <= 122)
end

---@param item snacks.picker.Item
---@param mods snacks.picker.matcher.Mods
---@param positions? number[]
---@return number? score
function M:_match(item, mods, positions)
  local str = item.text
  if mods.field then
    if item[mods.field] == nil then
      if mods.inverse then
        return 1000
      end
      return
    end
    str = tostring(item[mods.field])
  end

  str = mods.ignorecase and str:lower() or str
  if mods.fuzzy then
    return self:fuzzy(str, mods.pattern, positions)
  end
  local from, to ---@type number?, number?
  if mods.exact_prefix then
    if str:sub(1, #mods.pattern) == mods.pattern then
      from, to = 1, #mods.pattern
    end
  elseif mods.exact_suffix then
    if str:sub(-#mods.pattern) == mods.pattern then
      from, to = #str - #mods.pattern + 1, #str
    end
  else
    from, to = str:find(mods.pattern, 1, true)

    -- word match
    while mods.word and from and to do
      local bound_left = from == 1 or not M.is_alpha(str, from - 1)
      local bound_right = to == #str or not M.is_alpha(str, to + 1)
      if bound_left and bound_right then
        break
      end
      from, to = str:find(mods.pattern, to + 1, true)
    end
  end
  if mods.inverse then
    if not from then
      return 1000
    end
    return
  end
  if from and to then
    if positions then
      M.positions(from, to, positions)
    end
    return self.score(from, to, #str)
  end
end

---@param from number
---@param to number
---@param positions number[]
function M.positions(from, to, positions)
  for i = from, to do
    table.insert(positions, i)
  end
end

---@param from number
---@param to number
---@param len number
function M.score(from, to, len)
  return 1000 / (to - from + 1) -- calculate compactness score (distance between first and last match)
    -- + (100 / from) -- add bonus for early match
    + (100 / (len + 1)) -- add bonus for string length
end

---@param str string
---@param pattern string
---@param positions? number[]
---@return number? score
function M:fuzzy_fast(str, pattern, positions)
  local n, m, p, c = #str, #pattern, 1, 1
  positions = positions or M.clear(fuzzy_fast_positions)
  while c <= n and p <= m do
    local pos = str:find(pattern:sub(p, p), c, true)
    if not pos then
      break
    end
    positions[p] = pos
    p = p + 1
    c = pos + 1
  end
  return p > m and M.score(positions[1], positions[m], n) or nil
end

--- Does a forward scan followed by a backward scan for each end position,
--- to find the best match.
---@param str string
---@param pattern string
---@param best_positions? number[]
---@return number? score
function M:fuzzy(str, pattern, best_positions)
  local n, m, p, c = #str, #pattern, 1, 1
  -- Find last char positions first for early exit
  best_positions = best_positions or M.clear(fuzzy_best_positions)
  local best_score = -1

  -- initial forward scan
  while c <= n and p <= m do
    local pos = str:find(pattern:sub(p, p), c, true)
    if not pos then
      break
    end
    best_positions[p] = pos
    p = p + 1
    c = pos + 1
  end

  -- no full match
  if p <= m then
    return
  end

  -- calculate score for the initial match
  best_score = M.score(best_positions[1], best_positions[m], n)

  -- early exit for exact match
  if best_positions[m] - best_positions[1] + 1 == m then
    return best_score
  end

  -- find all last positions
  local last_positions = M.clear(fuzzy_last_positions)
  last_positions[1] = best_positions[m]
  local last_p = pattern:sub(m, m)
  while c <= n do
    local pos = str:find(last_p, c, true)
    if not pos then
      break
    end
    table.insert(last_positions, pos)
    c = pos + 1
  end

  local rev = str:reverse()

  -- backward scan from last positions to refine the match
  local positions = M.clear(fuzzy_positions)
  local best = best_positions
  for _, last in ipairs(last_positions) do
    p = m - 1 -- Start from the second last character of the pattern
    positions[m] = last
    c = n - last + 1
    local score = 0
    while c > 0 and p > 0 do
      local pos = rev:find(pattern:sub(p, p), c, true)
      local from = n - pos + 1
      score = M.score(from, last, n)
      if score <= best_score then
        break
      end
      positions[p] = from
      p = p - 1
      c = pos + 1
    end
    if score > best_score then
      best_score = score
      positions, best = best, positions
    end
  end

  if best ~= best_positions then
    table.move(best, 1, m, 1, best_positions)
  end

  return best_score
end

return M
