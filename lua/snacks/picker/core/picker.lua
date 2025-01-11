local Async = require("snacks.picker.util.async")
local Finder = require("snacks.picker.core.finder")

local uv = vim.uv or vim.loop
Async.BUDGET = 20

---@class snacks.Picker
---@field opts snacks.picker.Config
---@field finder snacks.picker.Finder
---@field format snacks.picker.Formatter
---@field input snacks.picker.input
---@field layout snacks.layout
---@field list snacks.picker.list
---@field matcher snacks.picker.Matcher
---@field parent_win number
---@field preview snacks.picker.Preview
---@field shown? boolean
---@field sorter snacks.matcher.sorter
---@field updater uv.uv_timer_t
---@field start_time number
---@field source_name string
---@field closed? boolean
---@field hist_idx number
---@field hist_cursor number
local M = {}
M.__index = M

--- Keep track of garbage collection
---@type table<snacks.Picker,boolean>
M._pickers = setmetatable({}, { __mode = "k" })
--- These are active, so don't garbage collect them
---@type table<snacks.Picker,boolean>
M._active = {}

---@class snacks.picker.Last
---@field opts snacks.picker.Config
---@field selected snacks.picker.Item[]
---@field filter snacks.picker.Filter

---@type snacks.picker.Last?
M.last = nil

---@type string[]
M.history = {}

---@private
---@param opts? snacks.picker.Config
function M.new(opts)
  local self = setmetatable({}, M)
  self.opts = Snacks.picker.config.get(opts)
  if self.opts.source == "resume" then
    return M.resume()
  end
  self.start_time = uv.hrtime()
  Snacks.picker.current = self
  self.parent_win = vim.api.nvim_get_current_win()
  local actions = require("snacks.picker.core.actions").get(self)
  self.opts.win.input.actions = actions
  self.opts.win.list.actions = actions
  self.opts.win.preview.actions = actions
  self.hist_idx = #M.history + 1
  self.hist_cursor = self.hist_idx

  self.sorter = self.opts.sorter or require("snacks.picker.sorter").default()

  self.updater = assert(uv.new_timer())
  self.matcher = require("snacks.picker.core.matcher").new(self.opts.matcher)

  self.finder = Finder.new(Snacks.picker.config.finder(self.opts.finder) or function()
    return function(cb)
      for _, it in ipairs(self.opts.items or {}) do
        cb(it)
      end
    end
  end)

  local format = type(self.opts.format) == "string" and Snacks.picker.format[self.opts.format]
    or self.opts.format
    or Snacks.picker.format.file
  ---@cast format snacks.picker.Formatter
  self.format = format

  M._pickers[self] = true
  M._active[self] = true

  self.list = require("snacks.picker.core.list").new(self)
  self.input = require("snacks.picker.core.input").new(self, self.opts)
  self.preview = require("snacks.picker.core.preview").new(self.opts)

  self.layout = Snacks.layout.new(vim.tbl_deep_extend("force", self.opts.layout or {}, {
    win = {
      wo = {
        winhighlight = Snacks.picker.highlight.winhl("SnacksPicker"),
      },
    },
    wins = {
      input = self.input.win,
      list = self.list.win,
      preview = self.preview.win,
    },
  }))

  M.last = {
    opts = self.opts,
    selected = {},
    filter = self.input.filter,
  }

  local boxwhl = Snacks.picker.highlight.winhl("SnacksPickerBox")
  self.source_name = Snacks.picker.util.title(self.opts.source or "search")
  local wins = { self.layout.win }
  vim.list_extend(wins, vim.tbl_values(self.layout.wins))
  vim.list_extend(wins, vim.tbl_values(self.layout.box_wins))
  for _, win in pairs(self.layout.box_wins) do
    win.opts.wo.winhighlight = boxwhl
  end
  for _, win in pairs(wins) do
    if win.opts.title then
      win.opts.title = Snacks.picker.util.tpl(win.opts.title, { source = self.source_name })
    end
  end
  self.layout:each(function(widget)
    ---@cast widget snacks.layout.Win
    if widget.title then
      widget.title = Snacks.picker.util.tpl(widget.title, { source = self.source_name })
    end
  end, { boxes = false })

  -- properly close the picker when the window is closed
  self.input.win:on("WinClosed", function()
    self:close()
  end, { win = true })

  -- close if we enter a window that is not part of the picker
  self.input.win:on("WinEnter", function()
    local current = vim.api.nvim_get_current_win()
    if not vim.tbl_contains({ self.input.win.win, self.list.win.win, self.preview.win.win }, current) then
      self:close()
    end
  end)

  local show_preview = self.show_preview
  self.show_preview = Snacks.util.throttle(function()
    show_preview(self)
  end, { ms = 60 })

  self:find()
  return self
end

---@private
function M.resume()
  local last = M.last
  if not last then
    Snacks.notify.error("No picker to resume")
    return M.new({ source = "pickers" })
  end
  last.opts.pattern = last.filter.pattern
  last.opts.search = last.filter.search
  local ret = M.new(last.opts)
  ret.list:set_selected(last.selected)
  ret.list:update()
  ret.input:update()
  return ret
end

---@param name string
---@param start? number
function M:debug(name, start)
  do
    return
  end
  local delta = (uv.hrtime() - (start or self.start_time)) / 1e6
  Snacks.notify.info(("`%s` took %.2fms"):format(name, delta))
end

function M:show_preview()
  if not self.preview.win:valid() then
    return
  end
  self.preview:preview(self)
end

function M:show()
  if self.shown or self.closed then
    return
  end
  self.shown = true
  self.layout:show()
  self.input.win:focus()
end

---@return fun():snacks.picker.Item?
function M:items()
  local i = 0
  local n = self.finder:count()
  return function()
    i = i + 1
    if i <= n then
      return self.list:get(i)
    end
  end
end

function M:current()
  return self.list:current()
end

---@param opts? {fallback?: boolean} If fallback is true (default), then return current item if no selected items
function M:selected(opts)
  opts = opts or {}
  local ret = vim.deepcopy(self.list.selected)
  if #ret == 0 and opts.fallback ~= false then
    return { self:current() }
  end
  return ret
end

function M:close()
  if self.closed then
    return
  end
  M.last.selected = self:selected({ fallback = false })
  self.closed = true
  Snacks.picker.current = nil
  local current = vim.api.nvim_get_current_win()
  if (current == self.input.win.win or current == self.list.win.win) and vim.api.nvim_win_is_valid(self.parent_win) then
    vim.api.nvim_set_current_win(self.parent_win)
  end
  self.layout:close()
  self.updater:stop()
  M._active[self] = nil
  vim.schedule(function()
    self.list:clear()
    self.finder.items = {}
    self.matcher:abort()
    self.finder:abort()
  end)
end

function M:is_active()
  return self.finder:running() or self.matcher:running()
end

function M:progress(ms)
  if self.updater:is_active() then
    return
  end
  self.updater = vim.defer_fn(function()
    self:update()
    if self:is_active() then
      -- slower progress when we filled topk
      local topk, height = self.list.topk:count(), self.list.state.height or 50
      self:progress(topk > height and 30 or 10)
    end
  end, ms or 10)
end

function M:update()
  if self.closed then
    return
  end

  -- Schedule the update if we are in a fast event
  if vim.in_fast_event() then
    return vim.schedule(function()
      self:update()
    end)
  end

  local count = self.finder:count()
  -- Check if we should show the picker
  if not self.shown then
    -- Always show live pickers
    if self.opts.live then
      self:show()
    elseif not self:is_active() then
      if count == 0 then
        -- no results found
        local msg = "No results"
        if self.opts.source then
          msg = ("No results found for `%s`"):format(self.opts.source)
        end
        Snacks.notify.warn(msg, { title = "Snacks Picker" })
        self:close()
        return
      elseif count == 1 and self.opts.auto_confirm then
        self:debug("auto_confirm")
        -- auto confirm if only one result
        self:action("confirm")
        self:close()
        return
      else
        -- show the picker if we have results
        self.list:unpause()
        self:show()
        self:debug("show")
      end
    elseif count > 1 or (count == 1 and not self.opts.auto_confirm) then -- show the picker if we have results
      self:show()
      self:debug("show")
    end
  end

  if self.shown then
    if not self:is_active() then
      self.list:unpause()
    end
    -- update list and input
    if not self.list.paused then
      self.input:update()
    end
    self.list:update()
  end
end

---@param actions string|string[]
function M:action(actions)
  return self.input.win:execute(actions)
end

function M:find()
  self.list:clear()
  self.finder:run(self)
  self.matcher:run(self)
  self:progress()
end

---@param forward? boolean
function M:hist(forward)
  M.history[self.hist_idx] = self.input.filter.pattern
  self.hist_cursor = self.hist_cursor + (forward and 1 or -1)
  self.hist_cursor = math.min(math.max(self.hist_cursor, 1), #M.history)
  self.input:set(M.history[self.hist_cursor], "")
end

---@param pattern string
function M:filter(pattern)
  pattern = vim.trim(pattern)
  if self.matcher.pattern == pattern then
    return
  end
  M.history[self.hist_idx] = pattern
  self.matcher:init({ pattern = pattern, live = self.opts.live })

  if self.opts.live then
    -- pause rapid list updates to prevent flickering
    -- of the search results
    self.list:pause(60)
    return self:find()
  end

  local prios = {} ---@type snacks.picker.Item[]
  -- add current topk items to be checked first
  vim.list_extend(prios, self.list.topk:get())
  if not self.matcher:empty() then
    -- next add the rest of the matched items
    vim.list_extend(prios, self.list.items, 1, 1000)
  end

  self.list:clear()
  self.matcher:run(self, { prios = prios })
  self:progress()
end

return M
