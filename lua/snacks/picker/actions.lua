---@class snacks.picker.actions
---@field [string] snacks.picker.Action.spec
local M = {}

local SCROLL_WHEEL_DOWN = Snacks.util.keycode("<ScrollWheelDown>")
local SCROLL_WHEEL_UP = Snacks.util.keycode("<ScrollWheelUp>")

function M.edit(picker)
  picker:close()
  local win = vim.api.nvim_get_current_win()

  -- save position in jump list
  vim.api.nvim_win_call(win, function()
    vim.cmd("normal! m'")
  end)

  local items = picker:selected()
  for _, item in ipairs(items) do
    -- load the buffer
    local buf = item.buf ---@type number
    if not buf then
      local path = assert(Snacks.picker.util.path(item), "Either item.buf or item.file is required")
      buf = vim.fn.bufadd(path)
    end

    if not vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("edit")
      end)
      vim.bo[buf].buflisted = true
    end

    -- set the buffer
    vim.api.nvim_win_set_buf(win, buf)

    -- set the cursor
    if item.pos then
      vim.api.nvim_win_set_cursor(win, { item.pos[1], item.pos[2] })
    elseif item.search then
      vim.cmd(item.search)
      vim.cmd("noh")
    end
    -- center
    vim.cmd("norm! zzzv")
  end
end

M.cancel = function() end

M.confirm = M.edit

---@param items snacks.picker.Item[]
local function setqflist(items)
  local qf = {} ---@type vim.quickfix.entry[]
  for _, item in ipairs(items) do
    qf[#qf + 1] = {
      filename = item.file,
      bufnr = item.buf,
      lnum = item.pos and item.pos[1] or 1,
      col = item.pos and item.pos[2] or 1,
      end_lnum = item.end_pos and item.end_pos[1] or nil,
      end_col = item.end_pos and item.end_pos[2] or nil,
      text = item.text,
      pattern = item.search,
      valid = true,
    }
  end
  vim.fn.setqflist(qf)
  vim.cmd("copen")
end

function M.qf(picker)
  picker:close()
  setqflist(picker:selected())
end

function M.qf_all(picker)
  picker:close()
  setqflist(picker.finder.items)
end

function M.copy(_, item)
  if item then
    vim.fn.setreg("+", item.data or item.text)
  end
end

function M.history_back(picker)
  picker:hist()
end

function M.history_forward(picker)
  picker:hist(true)
end

function M.edit_tab(picker)
  picker:close()
  vim.cmd("tabnew")
  return picker:action("edit")
end

function M.edit_split(picker)
  picker:close()
  vim.cmd("split")
  return picker:action("edit")
end

function M.edit_vsplit(picker)
  picker:close()
  vim.cmd("vsplit")
  return picker:action("edit")
end

--- Toggles the selection of the current item,
--- and moves the cursor to the next item.
function M.select_and_next(picker)
  picker.list:select()
  M.list_down(picker)
end

--- Toggles the selection of the current item,
--- and moves the cursor to the prev item.
function M.select_and_prev(picker)
  picker.list:select()
  M.list_down(picker)
end

function M.cmd(picker, item)
  picker:close()
  if item and item.cmd then
    vim.cmd(item.cmd)
  end
end

function M.search(picker, item)
  picker:close()
  if item then
    vim.api.nvim_input("/" .. item.text)
  end
end

--- Tries to load the session, if it fails, it will open the picker.
function M.load_session(picker)
  picker:close()
  local item = picker:current()
  if not item then
    return
  end
  local dir = item.file
  local session_loaded = false
  vim.api.nvim_create_autocmd("SessionLoadPost", {
    once = true,
    callback = function()
      session_loaded = true
    end,
  })
  vim.defer_fn(function()
    if not session_loaded then
      Snacks.picker.files()
    end
  end, 100)
  vim.fn.chdir(dir)
  local session = Snacks.dashboard.sections.session()
  if session then
    vim.cmd(session.action:sub(2))
  end
end

function M.help(picker)
  local item = picker:current()
  if item then
    picker:close()
    vim.cmd("help " .. item.text)
  end
end

function M.preview_scroll_down(picker)
  picker.preview.win:scroll()
end

function M.preview_scroll_up(picker)
  picker.preview.win:scroll(true)
end

function M.toggle_live(picker)
  if not picker.opts.supports_live then
    Snacks.notify.warn("Live search is not supported for `" .. picker.source_name .. "`", { title = "Snacks Picker" })
    return
  end
  picker.opts.live = not picker.opts.live
  if picker.opts.live then
    if picker.input.filter.search ~= "" then
      local pattern = picker.input.filter.search
      if picker.input.filter.pattern ~= "" then
        pattern = pattern .. " " .. picker.input.filter.pattern
      end
      picker.input:set(pattern, "")
    else
      picker:find()
    end
  else
    picker.input:set("", picker.input.filter.pattern)
  end
  picker.input:update()
end

function M.toggle_focus(picker)
  if vim.api.nvim_get_current_win() == picker.input.win.win then
    picker.list.win:focus()
  else
    picker.input.win:focus()
  end
end

function M.focus_input(picker)
  picker.input.win:focus()
end

function M.focus_list(picker)
  picker.list.win:focus()
end

function M.focus_preview(picker)
  picker.preview.win:focus()
end

function M.toggle_ignored(picker)
  local opts = picker.opts --[[@as snacks.picker.files.Config]]
  opts.ignored = not opts.ignored
  picker:find()
end

function M.toggle_hidden(picker)
  local opts = picker.opts --[[@as snacks.picker.files.Config]]
  opts.hidden = not opts.hidden
  picker:find()
end

function M.list_top(picker)
  picker.list:move(1, true)
end

function M.list_bottom(picker)
  picker.list:move(picker.list:count(), true)
end

function M.list_down(picker)
  picker.list:move(1)
end

function M.list_up(picker)
  picker.list:move(-1)
end

function M.list_scroll_top(picker)
  local cursor = picker.list.cursor
  picker.list:scroll(picker.list.cursor, true)
  picker.list:move(cursor, true)
end

function M.list_scroll_bottom(picker)
  local cursor = picker.list.cursor
  picker.list:scroll(picker.list.cursor - picker.list:height() + 1, true)
  picker.list:move(cursor, true)
end

function M.list_scroll_center(picker)
  local cursor = picker.list.cursor
  picker.list:scroll(picker.list.cursor - math.ceil(picker.list:height() / 2) + 1, true)
  picker.list:move(cursor, true)
end

function M.list_scroll_down(picker)
  picker.list:scroll(picker.list.state.scroll)
end

function M.list_scroll_up(picker)
  picker.list:scroll(-picker.list.state.scroll)
end

function M.list_scroll_wheel_down(picker)
  local mouse_win = vim.fn.getmousepos().winid
  if mouse_win == picker.list.win.win then
    picker.list:scroll(picker.list.state.mousescroll)
  else
    vim.api.nvim_feedkeys(SCROLL_WHEEL_DOWN, "n", true)
  end
end

function M.list_scroll_wheel_up(picker)
  local mouse_win = vim.fn.getmousepos().winid
  if mouse_win == picker.list.win.win then
    picker.list:scroll(-picker.list.state.mousescroll)
  else
    vim.api.nvim_feedkeys(SCROLL_WHEEL_UP, "n", true)
  end
end

return M
