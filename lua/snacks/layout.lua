---@class snacks.layout
local M = {}

M.meta = {
  desc = "Window layouts",
}

---@class snacks.layout.Dim: snacks.win.Dim
---@field depth number

---@class snacks.layout.Base
---@field width? number
---@field min_width? number
---@field max_width? number
---@field height? number
---@field min_height? number
---@field max_height? number
---@field col? number
---@field row? number
---@field border? string
---@field depth? number

---@class snacks.layout.Win: snacks.layout.Base, snacks.win.Config,{}
---@field win string

---@class snacks.layout.Box: snacks.layout.Base
---@field box "horizontal" | "vertical"
---@field id? number
---@field [number] snacks.layout.Win | snacks.layout.Box

---@alias snacks.layout.Widget snacks.layout.Win | snacks.layout.Box

---@class snacks.layout.Config
---@field win? snacks.words.Config|{}
---@field wins table<string, snacks.win>
---@field layout snacks.layout.Box
local defaults = {
  win = {
    width = 0.6,
    height = 0.6,
    zindex = 50,
  },
}

---@class snacks.layout.Layout
---@field opts snacks.layout.Config
---@field win snacks.win
---@field wins table<string, snacks.win|{enabled?:boolean}>
---@field box_wins snacks.win[]
---@field win_opts table<string, snacks.win.Config>
local Layout = {}
Layout.__index = Layout

---@param opts snacks.layout.Config
function Layout.new(opts)
  local self = setmetatable({}, Layout)
  self.opts = opts
  self.win_opts = {}
  self.wins = self.opts.wins or {}
  local win_opts = Snacks.win.resolve(defaults.win, opts.win, {
    show = false,
    focusable = false,
    enter = false,
  })
  self.win = Snacks.win(win_opts)

  -- assign ids to boxes and create box wins if needed
  self.box_wins = {}
  local id = 1

  self:each(function(box)
    ---@cast box snacks.layout.Box
    box.id, id = id, id + 1
    if box.border and box.border ~= "" and box.border ~= "none" then
      self.box_wins[box.id] = Snacks.win(Snacks.win.resolve(box, {
        focusable = false,
        enter = false,
        show = false,
        relative = "win",
        backdrop = false,
        zindex = self.win.opts.zindex + box.depth,
        border = box.border,
      }))
    end
  end, { wins = false })

  for w, win in pairs(self.wins) do
    self.win_opts[w] = vim.deepcopy(win.opts)
    win:on("WinClosed", function()
      self:close()
    end, { win = true })
  end
  self.win:on("VimResized", function()
    self.win:update()
    self:update()
    for _, win in pairs(self.wins) do
      if win.enabled then
        win:update()
      end
    end
    for _, win in pairs(self.box_wins) do
      win:update()
    end
  end)
  return self
end

---@param cb fun(widget: snacks.layout.Widget)
---@param opts? {wins?:boolean, boxes?:boolean}
function Layout:each(cb, opts)
  opts = opts or {}
  local stack = { self.opts.layout }
  while #stack > 0 do
    local box = table.remove(stack)
    box.depth = box.depth or 0
    if box.box then
      ---@cast box snacks.layout.Box
      for _, child in ipairs(box) do
        child.depth = box.depth + 1
        table.insert(stack, child)
      end
      if opts.boxes ~= false then
        cb(box)
      end
    elseif opts.wins ~= false then
      cb(box)
    end
  end
end

function Layout:update()
  local parent = self.win:dim()
  ---@cast parent snacks.layout.Dim
  parent.col, parent.row = 0, 0
  parent.depth = 0
  return self:update_box(vim.deepcopy(self.opts.layout), parent)
end

---@param box snacks.layout.Box
---@param parent snacks.layout.Dim
function Layout:update_box(box, parent)
  local size_main = box.box == "horizontal" and "width" or "height"
  local pos_main = box.box == "horizontal" and "col" or "row"
  box.col = box.col or 0
  box.row = box.row or 0

  local dim, border = self:dim_box(box, parent)
  local orig_dim = vim.deepcopy(dim)
  dim.col = dim.col + border.left
  dim.row = dim.row + border.top
  local free = vim.deepcopy(dim)

  local function size(child)
    return child[size_main] or 0
  end

  local dims = {} ---@type table<number, snacks.win.Dim>
  local flex = 0
  for c, child in ipairs(box) do
    flex = flex + (size(child) == 0 and 1 or 0)
    if size(child) > 0 then
      dims[c] = self:resolve(child, dim)
      free[size_main] = free[size_main] - dims[c][size_main]
    end
  end
  local free_main = free[size_main]
  for c, child in ipairs(box) do
    if size(child) == 0 then
      free[size_main] = math.floor(free_main / flex)
      flex = flex - 1
      free_main = free_main - free[size_main]
      dims[c] = self:resolve(child, free)
    end
  end
  -- assert(free[size_main] >= 0, "not enough space for children")
  -- fix positions
  local offset = 0
  for c, child in ipairs(box) do
    local wins = self:get_wins(child)
    for _, win in ipairs(wins) do
      win.opts[pos_main] = win.opts[pos_main] + offset
    end
    offset = offset + dims[c][size_main]
  end

  dim.width = dim.width + border.left + border.right
  dim.height = dim.height + border.top + border.bottom

  local box_win = self.box_wins[box.id]
  if box_win then
    box_win.opts.win = self.win.win
    box_win.opts.col = orig_dim.col
    box_win.opts.row = orig_dim.row
    box_win.opts.width = orig_dim.width
    box_win.opts.height = orig_dim.height
  end

  return dim
end

---@param widget snacks.layout.Widget
---@param ret? snacks.win[]
function Layout:get_wins(widget, ret)
  ret = ret or {}
  if widget.box then
    for _, child in ipairs(widget) do
      self:get_wins(child, ret)
    end
    if self.box_wins[widget.id] then
      table.insert(ret, self.box_wins[widget.id])
    end
  else
    table.insert(ret, self.wins[widget.win])
  end
  return ret
end

---@param widget snacks.layout.Widget
---@param parent snacks.layout.Dim
function Layout:resolve(widget, parent)
  if widget.box then
    ---@cast widget snacks.layout.Box
    return self:update_box(widget, parent)
  else
    assert(widget.win, "widget must have win or box")
    ---@cast widget snacks.layout.Win
    return self:update_win(widget, parent)
  end
end

---@param widget snacks.layout.Box
---@param parent snacks.layout.Dim
function Layout:dim_box(widget, parent)
  local opts = vim.deepcopy(widget) --[[@as snacks.win.Config]]
  -- adjust max width / height
  opts.max_width = math.min(parent.width, opts.max_width or parent.width)
  opts.max_height = math.min(parent.height, opts.max_height or parent.height)
  local fake_win = setmetatable({ opts = opts }, Snacks.win)
  local ret = fake_win:dim(parent)
  ---@cast ret snacks.layout.Dim
  ret.depth = parent.depth + 1
  return ret, fake_win:border_size()
end

---@param win snacks.layout.Win
---@param parent snacks.layout.Dim
function Layout:update_win(win, parent)
  local w = self.wins[win.win]
  w.enabled = true
  assert(w, ("win %s not part of layout"):format(win.win))
  -- add win opts from layout
  w.opts = vim.tbl_extend(
    "force",
    vim.deepcopy(self.win_opts[win.win] or {}),
    {
      width = 0,
      height = 0,
      enter = false,
    },
    win,
    {
      relative = "win",
      win = self.win.win,
      backdrop = false,
      zindex = self.win.opts.zindex + parent.depth,
    }
  )
  -- adjust max width / height
  w.opts.max_width = math.min(parent.width, w.opts.max_width or parent.width)
  w.opts.max_height = math.min(parent.height, w.opts.max_height or parent.height)
  -- resolve width / height relative to parent box
  local dim = w:dim(parent)
  w.opts.width, w.opts.height = dim.width, dim.height
  local border = w:border_size()
  w.opts.col, w.opts.row = parent.col, parent.row
  dim.width = dim.width + border.left + border.right
  dim.height = dim.height + border.top + border.bottom
  -- dim.col = dim.col + border.left
  -- dim.row = dim.row + border.top
  return dim
end

function Layout:close()
  for _, win in pairs(self.wins) do
    win:close()
  end
  for _, win in pairs(self.box_wins) do
    win:close()
  end
  self.win:close()
end

function Layout:valid()
  return self.win:valid()
end

function Layout:show()
  if self:valid() then
    return
  end
  self.win:show()
  self:update()
  for _, win in pairs(self.wins) do
    if win.enabled then
      win:show()
      win:update()
    end
  end
  for _, win in pairs(self.box_wins) do
    win:show()
    win:update()
  end
end

M.new = Layout.new

return M
