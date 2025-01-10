local M = {}

local uv = vim.uv or vim.loop

---@class snacks.picker
---@field git_files fun(opts?: snacks.picker.git.files.Config): snacks.Picker
---@field git_log fun(opts?: snacks.picker.git.log.Config): snacks.Picker

---@param opts snacks.picker.git.files.Config
---@type snacks.picker.finder
function M.files(opts)
  local args = { "-c", "core.quotepath=false", "ls-files", "--exclude-standard", "--cached" }
  if opts.untracked then
    table.insert(args, "--others")
  elseif opts.submodules then
    table.insert(args, "--recurse-submodules")
  end
  local cwd = vim.fs.normalize(opts and opts.cwd or uv.cwd() or ".") or nil
  return require("snacks.picker.source.proc").proc(vim.tbl_deep_extend("force", {
    cmd = "git",
    args = args,
    ---@param item snacks.picker.finder.Item
    transform = function(item)
      item.cwd = cwd
      item.file = item.text
    end,
  }, opts or {}))
end

---@param opts snacks.picker.git.log.Config
---@type snacks.picker.finder
function M.log(opts)
  local args = {
    "log",
    "--pretty=format:%h %s (%cr)",
    "--abbrev-commit",
    "--decorate",
    "--date=short",
    "--color=never",
    "--no-show-signature",
  }
  local cwd = vim.fs.normalize(opts and opts.cwd or uv.cwd() or ".") or nil
  return require("snacks.picker.source.proc").proc(vim.tbl_deep_extend("force", {
    cmd = "git",
    args = args,
    ---@param item snacks.picker.finder.Item
    transform = function(item)
      local commit, msg, date = item.text:match("(%S+) (.*) %((.*)%)")
      item.cwd = cwd
      item.commit = commit
      item.msg = msg
      item.date = date
      item.file = item.text
    end,
  }, opts or {}))
end

return M
