---@class snacks.picker.config
local M = {}

---@alias snacks.picker.Extmark vim.api.keyset.set_extmark|{col:number}
---@alias snacks.picker.Text {[1]:string, [2]:string?, virtual?:boolean}
---@alias snacks.picker.Highlights (snacks.picker.Text|snacks.picker.Extmark)[]
---@alias snacks.picker.Formatter fun(item:snacks.picker.Item, picker:snacks.Picker):snacks.picker.Highlights
---@alias snacks.matcher.sorter fun(a:snacks.picker.Item, b:snacks.picker.Item):boolean

---@class snacks.picker.finder.Item: snacks.picker.Item
---@field idx? number
---@field score? number

--- Generic filter used by finders to pre-filter items
---@class snacks.picker.filter.Config
---@field cwd? boolean|string only show files for the given cwd
---@field buf? boolean|number only show items for the current or given buffer
---@field paths? table<string, boolean> only show items that include or exclude the given paths
---@field filter? fun(item:snacks.picker.finder.Item):boolean custom filter function

---@class snacks.picker.Item
---@field [string] any
---@field idx number
---@field score number
---@field match_tick? number
---@field text string
---@field pos? {[1]:number, [2]:number}
---@field end_pos? {[1]:number, [2]:number}
---@field highlights? snacks.picker.Highlights[]

---@class snacks.picker.sources.Config

---@class snacks.picker.list.Config: snacks.win.Config
---@field reverse? boolean

---@class snacks.picker.win.Config
---@field input? snacks.win.Config|{}
---@field list? snacks.picker.list.Config|{}
---@field preview? snacks.win.Config|{}

---@class snacks.picker.Config
---@field prompt? string
---@field pattern? string|fun():string Pattern used to filter items by the matcher
---@field search? string|fun():string Initial search string used by finders
---@field cwd? string
---@field live? boolean
---@field ui_select? boolean
---@field preset? string|string[]
---@field auto_confirm? boolean Automatically confirm if there is only one item
---@field format? snacks.picker.Formatter|string
---@field items? snacks.picker.finder.Item[]
---@field finder? snacks.picker.finder|string
---@field matcher? snacks.picker.matcher.Config
---@field sorter? snacks.matcher.sorter
---@field actions? table<string, snacks.picker.Action.spec>
---@field win? snacks.picker.win.Config
---@field layout? snacks.layout.Config|{}
---@field preview? snacks.picker.preview.Config
---@field previewer? snacks.picker.Previewer|string
---@field sources? snacks.picker.sources.Config|{}
---@field icons? snacks.picker.icons
---@field source? string
local defaults = {
  prompt = " ",
  sources = {},
  ui_select = true, -- replace `vim.ui.select` with the snacks picker
  preview = {
    file = {
      max_size = 1024 * 1024, -- 1MB
      max_line_length = 500,
    },
  },
  win = {
    list = {
      keys = {
        ["<CR>"] = "confirm",
        ["gg"] = "list_top",
        ["G"] = "list_bottom",
        ["i"] = "focus_input",
        ["j"] = "list_down",
        ["k"] = "list_up",
        ["q"] = "close",
        ["<Tab>"] = "select_and_next",
        ["<S-Tab>"] = "select_and_prev",
        ["<Down>"] = "list_down",
        ["<Up>"] = "list_up",
        ["<c-d>"] = "list_scroll_down",
        ["<c-u>"] = "list_scroll_up",
        ["zt"] = "list_scroll_top",
        ["zb"] = "list_scroll_bottom",
        ["zz"] = "list_scroll_center",
        ["/"] = "toggle_focus",
        ["<ScrollWheelDown>"] = "list_scroll_wheel_down",
        ["<ScrollWheelUp>"] = "list_scroll_wheel_up",
        ["<c-f>"] = { "preview_scroll_down" },
        ["<c-b>"] = { "preview_scroll_up" },
        ["<c-v>"] = { "edit_vsplit" },
        ["<c-s>"] = { "edit_split" },
        ["<c-j>"] = { "list_down", mode = { "i", "n" } },
        ["<c-k>"] = { "list_up", mode = { "i", "n" } },
      },
    },
    input = {
      keys = {
        ["<esc>"] = "close",
        ["G"] = "list_bottom",
        ["gg"] = "list_top",
        ["j"] = "list_down",
        ["k"] = "list_up",
        ["/"] = "toggle_focus",
        ["q"] = "close",
        ["<C-Up>"] = { "history_back", mode = { "i", "n" } },
        ["<C-Down>"] = { "history_forward", mode = { "i", "n" } },
        ["<Tab>"] = { "select_and_next", mode = { "i", "n" } },
        ["<S-Tab>"] = { "select_and_prev", mode = { "i", "n" } },
        ["<Down>"] = { "list_down", mode = { "i", "n" } },
        ["<Up>"] = { "list_up", mode = { "i", "n" } },
        ["<c-j>"] = { "list_down", mode = { "i", "n" } },
        ["<c-k>"] = { "list_up", mode = { "i", "n" } },
        ["<c-b>"] = { "preview_scroll_up", mode = { "i", "n" } },
        ["<c-d>"] = { "list_scroll_down", mode = { "i", "n" } },
        ["<c-f>"] = { "preview_scroll_down", mode = { "i", "n" } },
        ["<c-g>"] = { "toggle_live", mode = { "i", "n" } },
        ["<c-u>"] = { "list_scroll_up", mode = { "i", "n" } },
        ["<ScrollWheelDown>"] = { "list_scroll_wheel_down", mode = { "i", "n" } },
        ["<ScrollWheelUp>"] = { "list_scroll_wheel_up", mode = { "i", "n" } },
        ["<c-v>"] = { "edit_vsplit", mode = { "i", "n" } },
        ["<c-s>"] = { "edit_split", mode = { "i", "n" } },
        ["<c-q>"] = { "qf", mode = { "i", "n" } },
        ["<a-q>"] = { "qf_all", mode = { "i", "n" } },
        ["<a-i>"] = { "toggle_ignored", mode = { "i", "n" } },
        ["<a-h>"] = { "toggle_hidden", mode = { "i", "n" } },
      },
    },
    preview = {
      minimal = false,
      wo = {
        cursorline = false,
      },
      keys = {
        ["q"] = "close",
        ["i"] = "focus_input",
        ["<ScrollWheelDown>"] = "list_scroll_wheel_down",
        ["<ScrollWheelUp>"] = "list_scroll_wheel_up",
      },
    },
  },
  layout = {
    win = {
      width = 0.8,
      height = 0.8,
      zindex = 50,
      -- border = "rounded",
    },
    layout = {
      box = "horizontal",
      {
        box = "vertical",
        border = "rounded",
        title = " {source} ",
        title_pos = "center",
        width = 0.5,
        { win = "input", height = 1, border = "bottom" },
        { win = "list", border = "none" },
      },
      { win = "preview", border = "rounded" },
    },
  },
  ---@class snacks.picker.icons
  icons = {
    ui = {
      selected = "● ",
      -- selected = " ",
    },
    diagnostics = {
      Error = " ",
      Warn = " ",
      Hint = " ",
      Info = " ",
    },
    -- stylua: ignore
    kinds = {
      Array         = " ",
      Boolean       = "󰨙 ",
      Class         = " ",
      Color         = " ",
      Control       = " ",
      Collapsed     = " ",
      Constant      = "󰏿 ",
      Constructor   = " ",
      Copilot       = " ",
      Enum          = " ",
      EnumMember    = " ",
      Event         = " ",
      Field         = " ",
      File          = " ",
      Folder        = " ",
      Function      = "󰊕 ",
      Interface     = " ",
      Key           = " ",
      Keyword       = " ",
      Method        = "󰊕 ",
      Module        = " ",
      Namespace     = "󰦮 ",
      Null          = " ",
      Number        = "󰎠 ",
      Object        = " ",
      Operator      = " ",
      Package       = " ",
      Property      = " ",
      Reference     = " ",
      Snippet       = "󱄽 ",
      String        = " ",
      Struct        = "󰆼 ",
      Text          = " ",
      TypeParameter = " ",
      Unit          = " ",
      Uknown        = " ",
      Value         = " ",
      Variable      = "󰀫 ",
    },
  },
}

Snacks.util.set_hl({
  Match = "Special",
  Search = "Search",
  Prompt = "Special",
  InputSearch = "@keyword",
  Special = "Special",
  Label = "SnacksPickerSpecial",
  Totals = "NonText",
  File = "",
  Dir = "NonText",
  Dimmed = "Conceal",
  Row = "String",
  Col = "LineNr",
  Comment = "Comment",
  Delim = "Delimiter",
  Spinner = "Special",
  Selected = "Number",
  Idx = "Number",
  Bold = "Bold",
  Italic = "Italic",
  Code = "@markup.raw.markdown_inline",
  AuPattern = "String",
  AuEvent = "Constant",
  AuGroup = "Type",
  DiagnosticCode = "Special",
  DiagnosticSource = "Comment",
  Register = "Number",
  KeymapMode = "Number",
  KeymapLhs = "Special",
  KeymapRhs = "NonText",
  GitCommit = "@variable.builtin",
  GitBreaking = "Error",
  GitDate = "String",
  GitIssue = "Number",
  GitType = "Title", -- conventional commit type
  GitScope = "Italic", -- conventional commit scope
  ManSection = "Number",
  ManPage = "Special",
  -- LSP Symbol Kinds
  IconArray = "@punctuation.bracket",
  IconBoolean = "@boolean",
  IconClass = "@type",
  IconConstant = "@constant",
  IconConstructor = "@constructor",
  IconEnum = "@lsp.type.enum",
  IconEnumMember = "@lsp.type.enumMember",
  IconEvent = "Special",
  IconField = "@variable.member",
  IconFile = "Normal",
  IconFunction = "@function",
  IconInterface = "@lsp.type.interface",
  IconKey = "@lsp.type.keyword",
  IconMethod = "@function.method",
  IconModule = "@module",
  IconNamespace = "@module",
  IconNull = "@constant.builtin",
  IconNumber = "@number",
  IconObject = "@constant",
  IconOperator = "@operator",
  IconPackage = "@module",
  IconProperty = "@property",
  IconString = "@string",
  IconStruct = "@lsp.type.struct",
  IconTypeParameter = "@lsp.type.typeParameter",
  IconVariable = "@variable",
}, { prefix = "SnacksPicker", default = true })

---@param opts? snacks.picker.Config
function M.get(opts)
  opts = opts or {}

  local sources = require("snacks.picker.config.sources")
  local presets = require("snacks.picker.config.presets")
  defaults.sources = sources
  local user = Snacks.config.picker or {}

  local global = Snacks.config.get("picker", defaults) -- defaults + global user config
  local todo = {
    defaults,
    user,
    opts.source and global.sources[opts.source] or {},
    opts,
  }
  local merge = {} ---@type snacks.picker.Config[]

  local layout = defaults.layout.layout

  local function add(o)
    if o then
      o = vim.deepcopy(o) ---@type snacks.picker.Config
      if o.layout and o.layout.layout then
        layout = o.layout.layout
      end
      merge[#merge + 1] = o
    end
  end

  for _, o in ipairs(todo) do
    local preset = o.preset
    preset = type(preset) == "table" and preset or { preset }
    ---@cast preset string[]
    for _, p in ipairs(preset) do
      add(presets[p])
    end
    add(o)
  end

  opts = vim.tbl_deep_extend("force", unpack(merge))
  opts.layout.layout = layout
  return opts
end

---@param prefix string
---@param links? table<string, string>
function M.winhl(prefix, links)
  links = links or {}
  local winhl = {
    NormalFloat = "",
    FloatBorder = "Border",
    FloatTitle = "Title",
    FloatFooter = "Footer",
    CursorLine = "CursorLine",
  }
  local ret = {} ---@type string[]
  local groups = {} ---@type table<string, string>
  for k, v in pairs(winhl) do
    groups[v] = links[k] or (prefix == "SnacksPicker" and k or ("SnacksPicker" .. v))
    ret[#ret + 1] = ("%s:%s%s"):format(k, prefix, v)
  end
  Snacks.util.set_hl(groups, { prefix = prefix, default = true })
  return table.concat(ret, ",")
end

---@param finder string|snacks.picker.finder
---@return snacks.picker.finder
function M.finder(finder)
  if not finder or type(finder) == "function" then
    return finder
  end
  local mod, fn = finder:match("^(.-)_(.+)$")
  if not (mod and fn) then
    mod, fn = finder, finder
  end
  return require("snacks.picker.source." .. mod)[fn]
end

local did_setup = false
function M.setup()
  if did_setup then
    return
  end
  did_setup = true
  for source in pairs(Snacks.picker.config.get().sources) do
    Snacks.picker[source] = function(opts)
      return Snacks.picker.pick(source, opts)
    end
  end
end

return M
