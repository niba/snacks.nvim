---@class snacks.picker.presets
---@field [string] snacks.picker.Config|{}
local M = {}

M.telescope = {
  layout = {
    win = {
      backdrop = false,
      width = 0.8,
      height = 0.9,
      zindex = 50,
      border = "none",
    },
    layout = {
      box = "horizontal",
      {
        box = "vertical",
        { win = "list", title = " Results ", title_pos = "center", border = "rounded" },
        { win = "input", height = 1, border = "rounded", title = "{source} {live}", title_pos = "center" },
      },
      {
        win = "preview",
        width = 0.45,
        border = "rounded",
        title = " Preview ",
        title_pos = "center",
      },
    },
  },
  win = {
    list = {
      reverse = true,
    },
  },
}

M.ivy = {
  layout = {
    win = {
      backdrop = false,
      row = -1,
      width = 0,
      height = 0.4,
      zindex = 50,
      border = "none",
    },
    layout = {
      box = "horizontal",
      {
        box = "vertical",
        { win = "input", height = 1, border = "none" },
        { win = "list", border = "none" },
      },
      { win = "preview", width = 0.6, border = "left" },
    },
  },
}

M.dropdown = {
  layout = {
    win = {
      backdrop = false,
      row = 1,
      width = 0.4,
      height = 0.8,
      zindex = 50,
      border = "none",
    },
    layout = {
      box = "vertical",
      { win = "preview", height = 0.4, border = "rounded" },
      {
        box = "vertical",
        border = "rounded",
        title = "{source} {live}",
        title_pos = "center",
        { win = "input", height = 1, border = "bottom" },
        { win = "list", border = "none" },
      },
    },
  },
}

M.vertical = {
  layout = {
    win = {
      backdrop = false,
      row = 1,
      width = 0.4,
      height = 0.6,
      zindex = 50,
      border = "rounded",
      title = "{source} {live}",
      title_pos = "center",
    },
    layout = {
      box = "vertical",
      { win = "input", height = 1, border = "bottom" },
      { win = "list", border = "none" },
      { win = "preview", height = 0.4, border = "top" },
    },
  },
}

M.vscode = {
  layout = {
    win = {
      backdrop = false,
      row = 1,
      width = 0.4,
      height = 0.4,
      zindex = 50,
      border = "none",
    },
    layout = {
      box = "vertical",
      { win = "input", height = 1, border = "rounded", title = "{source} {live}", title_pos = "center" },
      { win = "list", border = "hpad" },
    },
  },
}

M.nopreview = {
  layout = {
    win = {
      width = 0.5,
      height = 0.5,
      zindex = 50,
      border = "rounded",
      title = "{source} {live}",
      title_pos = "center",
    },
    layout = {
      box = "vertical",
      { win = "input", height = 1, border = "bottom" },
      { win = "list", border = "none" },
    },
  },
}

return M
