local M = {}

---@class snacks.picker
---@field recent fun(opts?: snacks.picker.recent.Config): snacks.Picker
---@field projects fun(opts?: snacks.picker.projects.Config): snacks.Picker

--- Get the most recent files, optionally filtered by the
--- current working directory or a custom directory.
---@param opts snacks.picker.recent.Config
function M.files(opts)
  ---@async
  ---@param cb async fun(item: snacks.picker.finder.Item)
  return function(cb)
    local filter = opts.filter or {}
    if opts.only_cwd then
      filter[vim.fs.normalize(opts.cwd or vim.fn.getcwd())] = true
    end
    for file in Snacks.dashboard.oldfiles({ filter = filter }) do
      cb({ file = file, text = file })
    end
  end
end

--- Get the most recent projects based on git roots of recent files.
--- The default action will change the directory to the project root,
--- try to restore the session and open the picker if the session is not restored.
--- You can customize the behavior by providing a custom action.
---@param opts snacks.picker.recent.Config
function M.projects(opts)
  ---@async
  ---@param cb async fun(item: snacks.picker.finder.Item)
  return function(cb)
    local dirs = {} ---@type string[]
    for file in Snacks.dashboard.oldfiles({ filter = opts.filter }) do
      local dir = Snacks.git.get_root(file)
      if dir and not vim.tbl_contains(dirs, dir) then
        table.insert(dirs, dir)
        cb({ file = dir, text = file, dir = dir })
      end
    end
  end
end

return M
