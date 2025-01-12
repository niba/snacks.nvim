---@class snacks.picker.Config
---@field supports_live? boolean

---@class snacks.picker.sources.Config
---@field [string] snacks.picker.Config|{}
local M = {}

M.autocmds = {
  finder = "vim_autocmds",
  format = "autocmd",
  previewer = "preview",
}

---@class snacks.picker.buffers.Config: snacks.picker.Config
---@field hidden? boolean show hidden buffers (unlisted)
---@field unloaded? boolean show loaded buffers
---@field current? boolean show current buffer
---@field nofile? boolean show `buftype=nofile` buffers
---@field sort_lastused? boolean sort by last used
---@field filter? snacks.picker.filter.Config
M.buffers = {
  finder = "buffers",
  format = "file",
  hidden = false,
  unloaded = true,
  current = true,
  sort_lastused = true,
}

M.cliphist = {
  finder = "system_cliphist",
  format = "text",
  previewer = "preview",
  actions = {
    confirm = { "copy", "close" },
  },
}

-- Neovim colorschemes with live preview
M.colorschemes = {
  finder = "vim_colorschemes",
  format = "text",
  previewer = "colorscheme",
  preset = "vertical",
  actions = {
    confirm = function(picker, item)
      picker:close()
      if item then
        picker.preview.state.colorscheme = nil
        vim.schedule(function()
          vim.cmd("colorscheme " .. item.text)
        end)
      end
    end,
  },
}

-- Neovim command history
---@type snacks.picker.history.Config
M.command_history = {
  finder = "vim_history",
  name = "cmd",
  format = "text",
  preset = "nopreview",
  layout = {
    win = { title = " Command History ", title_pos = "center" },
  },
  actions = { confirm = "cmd" },
}

-- Neovim commands
M.commands = {
  finder = "vim_commands",
  format = "text",
  previewer = "preview",
  actions = { confirm = "cmd" },
}

---@class snacks.picker.diagnostics.Config: snacks.picker.Config
---@field filter? snacks.picker.filter.Config
---@field severity? vim.diagnostic.SeverityFilter
M.diagnostics = {
  finder = "diagnostics",
  format = "diagnostic",
  sorter = Snacks.picker.sorter.default({
    fields = {
      "is_current",
      "is_cwd",
      "severity",
      "file",
      "lnum",
    },
  }),
  -- only show diagnostics from the cwd by default
  filter = { cwd = true },
}

---@type snacks.picker.diagnostics.Config
M.diagnostics_buffer = {
  finder = "diagnostics",
  format = "diagnostic",
  sorter = Snacks.picker.sorter.default({
    fields = { "severity", "file", "lnum" },
  }),
  filter = { buf = true },
}

---@class snacks.picker.files.Config: snacks.picker.proc.Config
---@field cmd? string
---@field hidden? boolean show hidden files
---@field ignored? boolean show ignored files
---@field dirs? string[] directories to search
---@field follow? boolean follow symlinks
M.files = {
  finder = "files",
  format = "file",
  hidden = true,
  ignored = false,
  follow = false,
  supports_live = true,
}

-- Find git files
---@class snacks.picker.git.files.Config: snacks.picker.Config
---@field untracked? boolean show untracked files
---@field submodules? boolean show submodule files
M.git_files = {
  finder = "git_files",
  format = "file",
  untracked = false,
  submodules = false,
}

---@class snacks.picker.git.log.Config: snacks.picker.Config
-- Git log
M.git_log = {
  finder = "git_log",
  format = "git_log",
  previewer = "git_show",
}

---@class snacks.picker.grep.Config: snacks.picker.proc.Config
---@field cmd? string
---@field hidden? boolean show hidden files
---@field ignored? boolean show ignored files
---@field dirs? string[] directories to search
---@field follow? boolean follow symlinks
---@field glob? string|string[] glob file pattern(s)
M.grep = {
  finder = "grep",
  format = "file",
  live = true, -- live grep by default
  supports_live = true,
}

---@type snacks.picker.grep.Config
M.grep_word = {
  finder = "grep",
  format = "file",
  search = function()
    return Snacks.picker.util.word()
  end,
  live = false,
  supports_live = true,
}

-- Neovim help tags
---@class snacks.picker.help.Config: snacks.picker.Config
---@field lang? string[] defaults to `vim.opt.helplang`
M.help = {
  finder = "help",
  format = "text",
  preview = {
    file = { ft = "help" },
  },
  win = {
    preview = {
      minimal = true,
    },
  },
  actions = {
    confirm = "help",
  },
}

M.highlights = {
  finder = "vim_highlights",
  format = "hl",
  previewer = "preview",
}

M.jumps = {
  finder = "vim_jumps",
  format = "file",
}

---@class snacks.picker.keymaps.Config: snacks.picker.Config
---@field global? boolean show global keymaps
---@field local? boolean show buffer keymaps
---@field modes? string[]
M.keymaps = {
  finder = "vim_keymaps",
  format = "keymap",
  previewer = "preview",
  global = true,
  ["local"] = true,
  modes = { "n", "v", "x", "s", "o", "i", "c", "t" },
  actions = {
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.api.nvim_input(item.item.lhs)
      end
    end,
  },
}

-- Search lines in the current buffer
---@class snacks.picker.lines.Config: snacks.picker.Config
---@field buf? number
M.lines = {
  finder = "lines",
  format = "lines",
}

-- Loclist
---@type snacks.picker.qf.Config
M.loclist = {
  finder = "qf",
  format = "file",
  qf_win = 0,
}

---@class snacks.picker.lsp.Config: snacks.picker.Config
---@field include_current? boolean default false
---@field unique_lines? boolean include only locations with unique lines
---@field filter? snacks.picker.filter.Config

-- LSP declarations
---@type snacks.picker.lsp.Config
M.lsp_declarations = {
  finder = "lsp_declarations",
  format = "file",
  include_current = false,
  auto_confirm = true,
}

-- LSP definitions
---@type snacks.picker.lsp.Config
M.lsp_definitions = {
  finder = "lsp_definitions",
  format = "file",
  include_current = false,
  auto_confirm = true,
}

-- LSP implementations
---@type snacks.picker.lsp.Config
M.lsp_implementations = {
  finder = "lsp_implementations",
  format = "file",
  include_current = false,
  auto_confirm = true,
}

-- LSP references
---@class snacks.picker.lsp.references.Config: snacks.picker.lsp.Config
---@field include_declaration? boolean default true
M.lsp_references = {
  finder = "lsp_references",
  format = "file",
  include_declaration = true,
  include_current = false,
  auto_confirm = true,
}

-- LSP document symbols
---@class snacks.picker.lsp.symbols.Config: snacks.picker.Config
---@field filter table<string, string[]|boolean>? symbol kind filter
M.lsp_symbols = {
  finder = "lsp_symbols",
  format = "lsp_symbol",
  filter = {
    default = {
      "Class",
      "Constructor",
      "Enum",
      "Field",
      "Function",
      "Interface",
      "Method",
      "Module",
      "Namespace",
      "Package",
      "Property",
      "Struct",
      "Trait",
    },
    -- set to `true` to include all symbols
    markdown = true,
    help = true,
    -- you can specify a different filter for each filetype
    lua = {
      "Class",
      "Constructor",
      "Enum",
      "Field",
      "Function",
      "Interface",
      "Method",
      "Module",
      "Namespace",
      -- "Package", -- remove package since luals uses it for control flow structures
      "Property",
      "Struct",
      "Trait",
    },
  },
}

-- LSP type definitions
---@type snacks.picker.lsp.Config
M.lsp_type_definitions = {
  finder = "lsp_type_definitions",
  format = "file",
  include_current = false,
  auto_confirm = true,
}

M.man = {
  finder = "system_man",
  format = "man",
  previewer = "man",
  actions = {
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.schedule(function()
          vim.cmd("Man " .. item.ref)
        end)
      end
    end,
  },
}

---@class snacks.picker.marks.Config: snacks.picker.Config
---@field global? boolean show global marks
---@field local? boolean show buffer marks
M.marks = {
  finder = "vim_marks",
  format = "file",
  global = true,
  ["local"] = true,
}

-- List all available sources
M.pickers = {
  finder = "pickers",
  format = "text",
  actions = {
    confirm = function(picker, item)
      picker:close()
      if item then
        Snacks.picker(item.text)
      end
    end,
  },
}

-- Open recent projects
---@class snacks.picker.projects.Config: snacks.picker.Config
---@field filter? snacks.picker.filter.Config
M.projects = {
  finder = "recent_projects",
  format = "file",
  actions = {
    confirm = "load_session",
  },
  win = {
    preview = {
      minimal = true,
    },
  },
}

-- Quickfix list
---@type snacks.picker.qf.Config
M.qflist = {
  finder = "qf",
  format = "file",
}

-- Find recent files
---@class snacks.picker.recent.Config: snacks.picker.Config
---@field filter? snacks.picker.filter.Config
M.recent = {
  finder = "recent_files",
  format = "file",
  filter = {
    paths = {
      [vim.fn.stdpath("data")] = false,
      [vim.fn.stdpath("cache")] = false,
      [vim.fn.stdpath("state")] = false,
    },
  },
}

-- Neovim registers
M.registers = {
  finder = "vim_registers",
  format = "register",
  previewer = "preview",
  actions = {
    confirm = { "copy", "close" },
  },
}

-- Special picker that resumes the last picker
M.resume = {}

-- Neovim search history
---@type snacks.picker.history.Config
M.search_history = {
  finder = "vim_history",
  name = "search",
  format = "text",
  preset = "nopreview",
  layout = {
    win = { title = " Search History ", title_pos = "center" },
  },
  actions = { confirm = "search" },
}

-- Open a project from zoxide
M.zoxide = {
  finder = "files_zoxide",
  format = "file",
  actions = {
    confirm = "load_session",
  },
  win = {
    preview = {
      minimal = true,
    },
  },
}

return M
