local Async = require("snacks.picker.util.async")
local Buffer = require("string.buffer")

local M = {}

local uv = vim.uv or vim.loop

---@class snacks.picker.proc.Config: snacks.picker.Config
---@field cmd string
---@field args? string[]
---@field env? table<string, string>
---@field cwd? string
---@field transform? fun(item: snacks.picker.finder.Item): boolean?

---@param opts snacks.picker.proc.Config
---@return fun(cb:async fun(item:snacks.picker.finder.Item))
function M.proc(opts)
  assert(opts.cmd, "`opts.cmd` is required")
  ---@async
  return function(cb)
    if opts.transform then
      local _cb = cb
      cb = function(item)
        if opts.transform(item) ~= false then
          _cb(item)
        end
      end
    end
    local stdout = assert(uv.new_pipe())
    opts = vim.tbl_deep_extend("force", {}, opts or {}, {
      stdio = { nil, stdout, nil },
      cwd = opts.cwd and vim.fs.normalize(opts.cwd) or nil,
    })
    local self = Async.running()

    local handle ---@type uv.uv_process_t
    handle = uv.spawn(opts.cmd, opts, function(_code, _signal)
      stdout:close()
      handle:close()
      self:resume()
    end)
    if not handle then
      return Snacks.notify.error("Failed to spawn " .. opts.cmd)
    end

    -- PERF: use jit string buffers to avoid string concatenation
    local prev = Buffer.new()

    local aborted = false
    self:on("abort", function()
      aborted = true
      if not handle:is_closing() then
        handle:kill("sigterm")
        vim.defer_fn(function()
          if not handle:is_closing() then
            handle:kill("sigkill")
          end
        end, 200)
      end
    end)

    ---@param data? string
    local function process(data)
      if aborted then
        return
      end
      if not data then
        return #prev > 0 and cb({ text = prev:get() })
      end
      local from = 1
      while from <= #data do
        local nl = data:find("\n", from, true)
        if nl then
          local cr = data:byte(nl - 2, nl - 2) == 13 -- \r
          local line = data:sub(from, nl - (cr and 2 or 1))
          prev:put(line)
          cb({ text = prev:get() })
          from = nl + 1
        else
          prev:put(data:sub(from))
          break
        end
      end
    end

    stdout:read_start(function(err, data)
      assert(not err, err)
      process(data)
    end)

    while not handle:is_closing() do
      self:suspend()
    end
  end
end

return M
