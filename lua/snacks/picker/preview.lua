---@class snacks.picker.preview
local M = {}

local uv = vim.uv or vim.loop
local ns = vim.api.nvim_create_namespace("snacks.picker.preview")

---@class snacks.picker.preview.Config
---@field file snacks.picker.preview.file.Config

---@class snacks.picker.preview.file.Config
---@field max_size? number default 1MB
---@field max_line_length? number defaults to 500
---@field ft? string defaults to auto-detect

---@alias snacks.picker.Previewer fun(ctx: snacks.picker.preview.ctx):boolean?

---@param ctx snacks.picker.preview.ctx
function M.directory(ctx)
  ctx.preview:reset()
  local ls = {} ---@type {file:string, type:"file"|"directory"}[]
  for file, t in vim.fs.dir(ctx.item.file) do
    ls[#ls + 1] = { file = file, type = t }
  end
  vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, vim.split(string.rep("\n", #ls), "\n"))
  vim.bo[ctx.buf].modifiable = false
  table.sort(ls, function(a, b)
    if a.type ~= b.type then
      return a.type == "directory"
    end
    return a.file < b.file
  end)
  for i, item in ipairs(ls) do
    local cat = item.type == "directory" and "directory" or "file"
    local hl = item.type == "directory" and "Directory" or nil
    local path = item.file
    local icon, icon_hl = Snacks.util.icon(path, cat)
    local line = { { icon .. " ", icon_hl }, { path, hl } }
    vim.api.nvim_buf_set_extmark(ctx.buf, ns, i - 1, 0, {
      virt_text = line,
    })
  end
end

---@param ctx snacks.picker.preview.ctx
function M.preview(ctx)
  if ctx.item.preview == "file" then
    return M.file(ctx)
  end
  assert(type(ctx.item.preview) == "table", "item.preview must be a table")
  ctx.preview:reset()
  local lines = vim.split(ctx.item.preview.text, "\n")
  vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
  ctx.preview:highlight({ ft = ctx.item.preview.ft })
  ctx.preview:loc()
end

---@param ctx snacks.picker.preview.ctx
function M.file(ctx)
  if ctx.item.buf and vim.api.nvim_buf_is_loaded(ctx.item.buf) then
    local name = vim.api.nvim_buf_get_name(ctx.item.buf)
    name = uv.fs_stat(name) and vim.fn.fnamemodify(name, ":t") or name
    ctx.preview:set_title(name)
    vim.api.nvim_win_set_buf(ctx.win, ctx.item.buf)
  else
    local path = assert(Snacks.picker.util.path(ctx.item), "item.file is required: " .. vim.inspect(ctx.item))
    -- re-use existing preview when path is the same
    if path ~= Snacks.picker.util.path(ctx.prev) then
      ctx.preview:reset()

      local name = vim.fn.fnamemodify(path, ":t")
      ctx.preview:set_title(name)

      local stat = uv.fs_stat(path)
      if not stat then
        ctx.preview:notify("file not found: " .. path, "error")
        return false
      end
      if stat.type == "directory" then
        return M.directory(ctx)
      end
      local max_size = ctx.picker.opts.preview.file.max_size or (1024 * 1024)
      if stat.size > max_size then
        ctx.preview:notify("large file > 1MB", "warn")
        return false
      end
      if stat.size == 0 then
        ctx.preview:notify("empty file", "warn")
        return false
      end

      local file = assert(io.open(path, "r"))

      local lines = {}
      for line in file:lines() do
        ---@cast line string
        if #line > ctx.picker.opts.preview.file.max_line_length then
          line = line:sub(1, ctx.picker.opts.preview.file.max_line_length) .. "..."
        end
        -- Check for binary data in the current line
        if line:find("[%z\1-\8\13\14\16-\31]") then
          ctx.preview:notify("binary file", "warn")
          return
        end
        table.insert(lines, line)
      end

      file:close()

      vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
      vim.bo[ctx.buf].modifiable = false
      ctx.preview:highlight({ file = path, ft = ctx.picker.opts.preview.file.ft, buf = ctx.buf })
    end
  end
  ctx.preview:loc()
end

---@param cmd string[]
---@param ctx snacks.picker.preview.ctx
function M.cmd(cmd, ctx)
  local buf = ctx.preview:scratch()
  local killed = false
  local chan = vim.api.nvim_open_term(buf, {})
  local output = {} ---@type string[]
  local jid = vim.fn.jobstart(cmd, {
    height = vim.api.nvim_win_get_height(ctx.win),
    width = vim.api.nvim_win_get_width(ctx.win),
    pty = true,
    cwd = ctx.item.cwd,
    env = {
      PAGER = "cat",
      DELTA_PAGER = "cat",
    },
    on_stdout = function(_, data)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      data = table.concat(data, "\n")
      local ok = pcall(vim.api.nvim_chan_send, chan, data)
      if ok then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd("norm! gg")
        end)
      end
      table.insert(output, data)
    end,
    on_exit = function(_, code)
      if not killed and code ~= 0 then
        Snacks.notify.error(
          ("Terminal **cmd** `%s` failed with code `%d`:\n- `vim.o.shell = %q`\n\nOutput:\n%s"):format(
            cmd,
            code,
            vim.o.shell,
            vim.trim(table.concat(output, ""))
          )
        )
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    callback = function()
      killed = true
      vim.fn.jobstop(jid)
      vim.fn.chanclose(chan)
    end,
  })
  if jid <= 0 then
    Snacks.notify.error(("Failed to start terminal **cmd** `%s`"):format(cmd))
  end
end

---@param ctx snacks.picker.preview.ctx
function M.git_show(ctx)
  local cmd = {
    "git",
    "-c",
    "delta." .. vim.o.background .. "=true",
    "show",
    ctx.item.commit,
  }
  M.cmd(cmd, ctx)
end

---@param ctx snacks.picker.preview.ctx
function M.colorscheme(ctx)
  if not ctx.preview.state.colorscheme then
    ctx.preview.state.colorscheme = vim.g.colors_name or "default"
    ctx.preview.state.background = vim.o.background
    ctx.preview.win:on("WinClosed", function()
      if not ctx.preview.state.colorscheme then
        return
      end
      vim.schedule(function()
        vim.cmd("colorscheme " .. ctx.preview.state.colorscheme)
        vim.o.background = ctx.preview.state.background
      end)
    end, { win = true })
  end
  vim.schedule(function()
    vim.cmd("colorscheme " .. ctx.item.text)
  end)
  Snacks.picker.preview.file(ctx)
end

---@param ctx snacks.picker.preview.ctx
function M.man(ctx)
  local buf = ctx.preview:scratch()
  vim.api.nvim_buf_call(buf, function()
    local ok, err = pcall(require("man").read_page, ctx.item.ref)
    if not ok then
      ctx.preview:notify(("Could not display man page `%s`:\n%s"):format(ctx.item.ref, err or "error"), "error")
    end
  end)
end

return M
