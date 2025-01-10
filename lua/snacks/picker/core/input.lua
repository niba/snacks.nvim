---@class snacks.picker.input
---@field win snacks.win
---@field totals string
---@field picker snacks.Picker
---@field _statuscolumn string
---@field filter snacks.picker.Filter
local M = {}
M.__index = M

local uv = vim.uv or vim.loop
local ns = vim.api.nvim_create_namespace("snacks.picker.input")

---@param picker snacks.Picker
---@param opts snacks.picker.Config
function M.new(picker, opts)
  local self = setmetatable({}, M)
  self.totals = ""
  self.picker = picker

  local function gets(v)
    return type(v) == "function" and v() or v or "" --[[@as string]]
  end

  self.filter = {
    pattern = gets(opts.pattern),
    search = gets(opts.search),
  }
  self._statuscolumn = self:statuscolumn()

  self.win = Snacks.win(Snacks.win.resolve(opts.win.input, {
    show = false,
    enter = true,
    height = 1,
    text = self.filter.pattern,
    ft = "regex",
    on_win = function()
      vim.fn.prompt_setprompt(self.win.buf, "")
      self.win:focus()
      vim.cmd.startinsert()
      vim.api.nvim_win_set_cursor(self.win.win, { 1, #self:get() + 1 })
      vim.fn.prompt_setcallback(self.win.buf, function()
        self.win:execute("confirm")
      end)
      vim.fn.prompt_setinterrupt(self.win.buf, function()
        self.win:close()
      end)
    end,
    bo = {
      filetype = "snacks_picker_input",
      buftype = "prompt",
    },
    wo = {
      statuscolumn = self._statuscolumn,
      cursorline = false,
      winhighlight = Snacks.picker.config.winhl("SnacksPickerInput"),
    },
  }))

  self.win:on(
    { "TextChangedI", "TextChanged" },
    Snacks.util.throttle(function()
      if not self.win:valid() then
        return
      end
      vim.bo[self.win.buf].modified = false
      self.filter.pattern = self:get()
      picker:filter(self.filter.pattern)
    end, { ms = opts.live and 100 or 30 }),
    { buf = true }
  )
  return self
end

function M:statuscolumn()
  local parts = {} ---@type string[]
  local function add(str, hl)
    if str then
      parts[#parts + 1] = ("%%#%s#%s%%*"):format(hl, str:gsub("%%", "%%"))
    end
  end
  if self.filter.search ~= "" then
    add(self.filter.search, "SnacksPickerInputSearch")
  end
  add(self.picker.opts.prompt or " ", "SnacksPickerPrompt")
  return table.concat(parts, " ")
end

function M:update()
  if not self.win:valid() then
    return
  end
  local sc = self:statuscolumn()
  if self._statuscolumn ~= sc then
    self._statuscolumn = sc
    vim.wo[self.win.win].statuscolumn = sc
  end
  local line = {} ---@type snacks.picker.Highlights
  if self.picker:is_active() then
    line[#line + 1] = { M.spinner(), "SnacksPickerSpinner" }
    line[#line + 1] = { " " }
  end
  local selected = #self.picker.list.selected
  if selected > 0 then
    line[#line + 1] = { ("(%d)"):format(selected), "SnacksPickerTotals" }
    line[#line + 1] = { " " }
  end
  line[#line + 1] = { ("%d/%d"):format(self.picker.list:count(), #self.picker.finder.items), "SnacksPickerTotals" }
  line[#line + 1] = { " " }
  local totals = table.concat(vim.tbl_map(function(v)
    return v[1]
  end, line))
  if self.totals == totals then
    return
  end
  self.totals = totals
  vim.api.nvim_buf_set_extmark(self.win.buf, ns, 0, 0, {
    id = 999,
    virt_text = line,
    virt_text_pos = "right_align",
  })
end

function M:get()
  return self.win:line()
end

---@param pattern? string
---@param search? string
function M:set(pattern, search)
  self.filter.pattern = pattern or ""
  self.filter.search = search or self.filter.search
  vim.api.nvim_buf_set_lines(self.win.buf, 0, -1, false, { self.filter.pattern })
  vim.api.nvim_win_set_cursor(self.win.win, { 1, #self:get() + 1 })
  self.totals = ""
  self._statuscolumn = ""
  self:update()
end

function M.spinner()
  local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
  return spinner[math.floor(uv.hrtime() / (1e6 * 80)) % #spinner + 1]
end

return M
