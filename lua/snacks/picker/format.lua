---@class snacks.picker.format
---@field [string] snacks.picker.Formatter
local M = {}

function M.severity(item, picker)
  local ret = {} ---@type snacks.picker.Highlights
  local severity = item.severity
  severity = type(severity) == "number" and vim.diagnostic.severity[severity] or severity
  if not severity or type(severity) == "number" then
    return ret
  end
  ---@cast severity string
  local lower = severity:lower()
  local cap = severity:sub(1, 1):upper() .. lower:sub(2)

  ret[#ret + 1] = { picker.opts.icons.diagnostics[cap], "Diagnostic" .. cap, virtual = true }
  ret[#ret + 1] = { " ", virtual = true }
  return ret
end

---@param item snacks.picker.Item
function M.filename(item)
  ---@type snacks.picker.Highlights
  local ret = {}
  if not item.file then
    return ret
  end
  local path = vim.fs.normalize(item.file)
  path = vim.fn.fnamemodify(path, ":~:.")
  local name, cat = path, "file"
  if item.buf and vim.api.nvim_buf_is_loaded(item.buf) then
    name = vim.bo[item.buf].filetype
    cat = "filetype"
  elseif item.dir then
    cat = "directory"
  end

  local icon, hl = Snacks.util.icon(name, cat)
  ret[#ret + 1] = { icon .. " ", hl, virtual = true }

  local dir, file = path:match("^(.*)/(.+)$")
  if dir then
    table.insert(ret, { dir .. "/", "SnacksPickerDir" })
    table.insert(ret, { file, "SnacksPickerFile" })
  else
    table.insert(ret, { path, "SnacksPickerFile" })
  end
  if item.pos then
    table.insert(ret, { ":", "SnacksPickerDelim" })
    table.insert(ret, { tostring(item.pos[1]), "SnacksPickerRow" })
    if item.pos[2] > 0 then
      table.insert(ret, { ":", "SnacksPickerDelim" })
      table.insert(ret, { tostring(item.pos[2]), "SnacksPickerCol" })
    end
  end
  ret[#ret + 1] = { " " }
  return ret
end

function M.file(item, picker)
  ---@type snacks.picker.Highlights
  local ret = {}

  if item.severity then
    vim.list_extend(ret, M.severity(item, picker))
  end

  if item.label then
    table.insert(ret, 1, { item.label, "SnacksPickerLabel" })
    table.insert(ret, 2, { " ", virtual = true })
  end

  vim.list_extend(ret, M.filename(item))

  if item.comment then
    table.insert(ret, { item.comment, "SnacksPickerComment" })
    table.insert(ret, { " " })
  end

  if item.line then
    Snacks.picker.highlight.format(item, item.line, ret)
    table.insert(ret, { " " })
  end
  return ret
end

function M.git_log(item)
  local ret = {} ---@type snacks.picker.Highlights
  ret[#ret + 1] = { item.commit, "SnacksPickerGitCommit" }
  ret[#ret + 1] = { " " }
  local msg = item.msg ---@type string
  local type, scope, breaking, body = msg:match("^(%S+)(%(.-%))(!?):%s*(.*)$")
  if not type then
    type, breaking, body = msg:match("^(%S+)(!?):%s*(.*)$")
  end
  local msg_hl = "SnacksPickerGitMsg"
  if type and body then
    local dimmed = vim.tbl_contains({ "chore", "bot", "build", "ci", "style", "test" }, type)
    msg_hl = dimmed and "SnacksPickerDimmed" or "SnacksPickerGitMsg"
    ret[#ret + 1] =
      { type, breaking ~= "" and "SnacksPickerGitBreaking" or dimmed and "SnacksPickerBold" or "SnacksPickerGitType" }
    if scope and scope ~= "" then
      ret[#ret + 1] = { scope, "SnacksPickerGitScope" }
    end
    if breaking ~= "" then
      ret[#ret + 1] = { "!", "SnacksPickerGitBreaking" }
    end
    ret[#ret + 1] = { ":", "SnacksPickerDelim" }
    ret[#ret + 1] = { " " }
    msg = body
  end
  ret[#ret + 1] = { msg, msg_hl }
  Snacks.picker.highlight.markdown(ret)
  Snacks.picker.highlight.highlight(ret, {
    ["#%d+"] = "SnacksPickerGitIssue",
  })
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { "(" .. item.date .. ")", "SnacksPickerGitDate" }
  return ret
end

function M.lsp_symbol(item, picker)
  local ret = {} ---@type snacks.picker.Highlights
  local kind = item.kind or "Unknown" ---@type string
  local kind_hl = "SnacksPickerIcon" .. kind
  ret[#ret + 1] = { picker.opts.icons.kinds[kind], kind_hl }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { kind:lower() .. string.rep(" ", 10 - #kind), kind_hl }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { item.name:gsub("\r?\n", " ") }
  return ret
end

---@param kind? string
---@param count number
---@return snacks.picker.Formatter
function M.ui_select(kind, count)
  return function(item)
    local ret = {} ---@type snacks.picker.Highlights
    local idx = tostring(item.idx)
    idx = (" "):rep(#tostring(count) - #idx) .. idx
    ret[#ret + 1] = { idx .. ".", "SnacksPickerIdx" }
    ret[#ret + 1] = { " " }

    if kind == "codeaction" then
      ---@type lsp.Command|lsp.CodeAction, lsp.HandlerContext
      local action, ctx = item.item.action, item.item.ctx
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      ret[#ret + 1] = { action.title }
      if client then
        ret[#ret + 1] = { " " }
        ret[#ret + 1] = { ("[%s]"):format(client.name), "SnacksPickerSpecial" }
      end
    else
      ret[#ret + 1] = { item.formatted }
    end
    return ret
  end
end

function M.lines(item)
  local ret = {} ---@type snacks.picker.Highlights
  local line_count = vim.api.nvim_buf_line_count(item.buf)
  local idx = Snacks.picker.util.align(tostring(item.idx), #tostring(line_count), { align = "right" })
  ret[#ret + 1] = { idx, "LineNr", virtual = true }
  ret[#ret + 1] = { "  ", virtual = true }
  ret[#ret + 1] = { item.text }

  local offset = #idx + 2

  for _, extmark in ipairs(item.highlights or {}) do
    extmark = vim.deepcopy(extmark)
    if type(extmark[1]) ~= "string" then
      ---@cast extmark snacks.picker.Extmark
      extmark.col = extmark.col + offset
      if extmark.end_col then
        extmark.end_col = extmark.end_col + offset
      end
    end
    ret[#ret + 1] = extmark
  end
  return ret
end

function M.text(item)
  return {
    { item.text },
  }
end

function M.diagnostic(item, picker)
  local ret = {} ---@type snacks.picker.Highlights
  local diag = item.item ---@type vim.Diagnostic
  if item.severity then
    vim.list_extend(ret, M.severity(item, picker))
  end

  ret[#ret + 1] = { diag.message }
  Snacks.picker.highlight.markdown(ret)
  ret[#ret + 1] = { " " }

  if diag.source then
    ret[#ret + 1] = { diag.source, "SnacksPickerDiagnosticSource" }
    ret[#ret + 1] = { " " }
  end

  if diag.code then
    ret[#ret + 1] = { ("(%s)"):format(diag.code), "SnacksPickerDiagnosticCode" }
    ret[#ret + 1] = { " " }
  end
  vim.list_extend(ret, M.filename(item, picker))
  return ret
end

function M.autocmd(item)
  local ret = {} ---@type snacks.picker.Highlights
  ---@type vim.api.keyset.get_autocmds.ret
  local au = item.item
  local a = Snacks.picker.util.align
  ret[#ret + 1] = { a(au.event, 15), "SnacksPickerAuEvent" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { a(au.pattern, 10), "SnacksPickerAuPattern" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { a(tostring(au.group_name or ""), 15), "SnacksPickerAuGroup" }
  ret[#ret + 1] = { " " }
  if au.command ~= "" then
    Snacks.picker.highlight.format(item, au.command, ret, { lang = "vim" })
  else
    ret[#ret + 1] = { "callback", "Function" }
  end
  return ret
end

function M.hl(item)
  local ret = {} ---@type snacks.picker.Highlights
  ret[#ret + 1] = { item.hl_group, item.hl_group }
  return ret
end

function M.man(item)
  local a = Snacks.picker.util.align
  local ret = {} ---@type snacks.picker.Highlights
  ret[#ret + 1] = { a(item.page, 20), "SnacksPickerManPage" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { ("(%s)"):format(item.section), "SnacksPickerManSection" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { item.desc, "SnacksPickerManDesc" }
  return ret
end

-- Pretty keymaps using which-key icons when available
function M.keymap(item)
  local ret = {} ---@type snacks.picker.Highlights
  ---@type vim.api.keyset.get_keymap
  local k = item.item
  local a = Snacks.picker.util.align

  if package.loaded["which-key"] then
    local Icons = require("which-key.icons")
    local icon, hl = Icons.get({ keymap = k, desc = k.desc })
    if icon then
      ret[#ret + 1] = { a(icon, 3), hl }
    else
      ret[#ret + 1] = { "   " }
    end
  end
  local lhs = vim.fn.keytrans(Snacks.util.keycode(k.lhs))
  ret[#ret + 1] = { k.mode, "SnacksPickerKeymapMode" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { a(lhs, 15), "SnacksPickerKeymapLhs" }
  ret[#ret + 1] = { " " }
  local rhs_len = 0
  if k.rhs and k.rhs ~= "" then
    local rhs = k.rhs or ""
    rhs_len = #rhs
    local cmd = rhs:lower():find("<cmd>")
    if cmd then
      ret[#ret + 1] = { rhs:sub(1, cmd + 4), "NonText" }
      rhs = rhs:sub(cmd + 5)
      local cr = rhs:lower():find("<cr>$")
      if cr then
        rhs = rhs:sub(1, cr - 1)
      end
      Snacks.picker.highlight.format(item, rhs, ret, { lang = "vim" })
      if cr then
        ret[#ret + 1] = { "<CR>", "NonText" }
      end
    elseif rhs:lower():find("^<plug>") then
      ret[#ret + 1] = { "<Plug>", "NonText" }
      local plug = rhs:sub(7):gsub("^%(", ""):gsub("%)$", "")
      ret[#ret + 1] = { "(", "SnacksPickerDelim" }
      Snacks.picker.highlight.format(item, plug, ret, { lang = "vim" })
      ret[#ret + 1] = { ")", "SnacksPickerDelim" }
    elseif rhs:find("v:lua%.") then
      ret[#ret + 1] = { "v:lua", "NonText" }
      ret[#ret + 1] = { ".", "SnacksPickerDelim" }
      Snacks.picker.highlight.format(item, rhs:sub(7), ret, { lang = "lua" })
    else
      ret[#ret + 1] = { k.rhs, "SnacksPickerKeymapRhs" }
    end
  else
    ret[#ret + 1] = { "callback", "Function" }
    rhs_len = 8
  end

  if rhs_len < 15 then
    ret[#ret + 1] = { (" "):rep(15 - rhs_len) }
  end

  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { a(k.desc or "", 20) }

  if item.file then
    ret[#ret + 1] = { " " }
    vim.list_extend(ret, M.filename(item))
  end
  return ret
end

function M.register(item)
  local ret = {} ---@type snacks.picker.Highlights
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { "[", "SnacksPickerDelim" }
  ret[#ret + 1] = { item.reg, "SnacksPickerRegister" }
  ret[#ret + 1] = { "]", "SnacksPickerDelim" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { item.value }
  return ret
end

function M.buffer(item)
  local ret = {} ---@type snacks.picker.Highlights
  ret[#ret + 1] = { Snacks.picker.util.align(tostring(item.buf), 3), "SnacksPickerBufNr" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { Snacks.picker.util.align(item.flags, 2, { align = "right" }), "SnacksPickerBufFlags" }
  ret[#ret + 1] = { " " }
  vim.list_extend(ret, M.filename(item))
  return ret
end

return M
