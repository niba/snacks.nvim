local M = {}

local uv = vim.uv or vim.loop

---@class snacks.picker
---@field live_grep fun(opts?: snacks.picker.grep.Config): snacks.Picker
---@field grep fun(opts?: snacks.picker.grep.Config): snacks.Picker

---@param opts snacks.picker.grep.Config
---@param filter snacks.picker.Filter
local function get_cmd(opts, filter)
  local cmd = "rg"
  local args = {
    "--color=never",
    "--no-heading",
    "--with-filename",
    "--line-number",
    "--column",
    "--smart-case",
    "--max-columns=500",
    "--max-columns-preview",
  }

  args = vim.deepcopy(args)

  -- hidden
  if opts.hidden then
    table.insert(args, "--hidden")
  end

  -- ignored
  if opts.ignored then
    args[#args + 1] = "--no-ignore"
  end

  -- follow
  if opts.follow then
    args[#args + 1] = "-L"
  end

  local glob = type(opts.glob) == "table" and opts.glob or { opts.glob }
  ---@cast glob string[]
  for _, g in ipairs(glob) do
    args[#args + 1] = "-g"
    args[#args + 1] = g
  end

  -- search pattern
  table.insert(args, filter.search)

  -- dirs
  if opts.dirs and #opts.dirs > 0 then
    local dirs = vim.tbl_map(vim.fs.normalize, opts.dirs) ---@type string[]
    vim.list_extend(args, dirs)
  end

  return cmd, args
end

---@param opts snacks.picker.grep.Config
---@type snacks.picker.finder
function M.grep(opts, filter)
  if filter.search == "" then
    return function() end
  end
  local cwd = not (opts.dirs and #opts.dirs > 0) and vim.fs.normalize(opts and opts.cwd or uv.cwd() or ".") or nil
  local cmd, args = get_cmd(opts, filter)
  return require("snacks.picker.source.proc").proc(vim.tbl_deep_extend("force", {
    cmd = cmd,
    args = args,
    ---@param item snacks.picker.finder.Item
    transform = function(item)
      item.cwd = cwd
      local file, line, col, text = item.text:match("^(.+):(%d+):(%d+):(.+)$")
      if not file then
        if not item.text:match("WARNING") then
          error("invalid grep output: " .. item.text)
        end
        return false
      else
        item.line = text
        item.file = file
        item.pos = { tonumber(line), tonumber(col) }
      end
    end,
  }, opts or {}))
end

return M
