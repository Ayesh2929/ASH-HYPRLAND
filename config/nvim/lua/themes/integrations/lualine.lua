-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📊 LUALINE INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                     ║
-- ║   Full statusline theme · all modes · git · diagnostics · ASH components      ║
-- ║   Powerline / slant / rounded styles · animated mode colours                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 MODE COLOUR MAPPING — each mode gets a distinct hue
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function mode_colours(p)
  return {
    -- Normal family
    n   = p.blue,
    no  = p.blue,
    nov = p.blue,
    noV = p.blue,
    ["no\22"] = p.blue,
    niI = p.blue,
    niR = p.blue,
    niV = p.blue,
    nt  = p.blue,
    ntT = p.blue,

    -- Insert
    i   = p.green,
    ic  = p.green,
    ix  = p.green,

    -- Visual family
    v   = p.mauve,
    vs  = p.mauve,
    V   = p.mauve,
    Vs  = p.mauve,
    ["\22"]  = p.mauve,
    ["\22s"] = p.mauve,

    -- Select
    s   = p.pink,
    S   = p.pink,
    ["\19"] = p.pink,

    -- Replace
    R   = p.red,
    Rc  = p.red,
    Rx  = p.red,
    Rv  = p.red,
    RV  = p.red,

    -- Command
    c   = p.peach,
    cv  = p.peach,
    r   = p.yellow,
    rm  = p.yellow,
    ["r?"] = p.yellow,

    -- Shell / terminal
    ["!"]  = p.red,
    t      = p.teal,

    -- Confirm
    ix   = p.green,
    ["!"] = p.red,
  }
end

---Build a complete lualine theme table from the palette
---@param p table ASH palette
---@return table Lualine theme
function M.make_theme(p)
  local mc   = mode_colours(p)
  local sl   = p.statusline or p.surface0   -- statusline background
  local base = p.base

  -- Helper: build a section table
  local function sec(fg, bg, bold)
    return { fg = fg, bg = bg, bold = bold or false }
  end

  -- Active mode fg is always p.base (dark text on vivid bg)
  local mode_fg = base

  return {
    normal = {
      a = sec(mode_fg,   p.blue,    true),
      b = sec(p.text,    sl,        false),
      c = sec(p.subtext0, sl,       false),
      x = sec(p.subtext0, sl,       false),
      y = sec(p.text,    sl,        false),
      z = sec(mode_fg,   p.blue,    true),
    },

    insert = {
      a = sec(mode_fg,   p.green,   true),
      b = sec(p.text,    sl,        false),
      c = sec(p.subtext0, sl,       false),
      x = sec(p.subtext0, sl,       false),
      y = sec(p.text,    sl,        false),
      z = sec(mode_fg,   p.green,   true),
    },

    visual = {
      a = sec(mode_fg,   p.mauve,   true),
      b = sec(p.text,    sl,        false),
      c = sec(p.subtext0, sl,       false),
      x = sec(p.subtext0, sl,       false),
      y = sec(p.text,    sl,        false),
      z = sec(mode_fg,   p.mauve,   true),
    },

    replace = {
      a = sec(mode_fg,   p.red,     true),
      b = sec(p.text,    sl,        false),
      c = sec(p.subtext0, sl,       false),
      x = sec(p.subtext0, sl,       false),
      y = sec(p.text,    sl,        false),
      z = sec(mode_fg,   p.red,     true),
    },

    command = {
      a = sec(mode_fg,   p.peach,   true),
      b = sec(p.text,    sl,        false),
      c = sec(p.subtext0, sl,       false),
      x = sec(p.subtext0, sl,       false),
      y = sec(p.text,    sl,        false),
      z = sec(mode_fg,   p.peach,   true),
    },

    terminal = {
      a = sec(mode_fg,   p.teal,    true),
      b = sec(p.text,    sl,        false),
      c = sec(p.subtext0, sl,       false),
      x = sec(p.subtext0, sl,       false),
      y = sec(p.text,    sl,        false),
      z = sec(mode_fg,   p.teal,    true),
    },

    inactive = {
      a = sec(p.overlay0, sl,       false),
      b = sec(p.overlay0, sl,       false),
      c = sec(p.surface2, sl,       false),
      x = sec(p.surface2, sl,       false),
      y = sec(p.overlay0, sl,       false),
      z = sec(p.overlay0, sl,       false),
    },
  }
end

---Apply direct highlight groups used by lualine and ASH statusline components
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl
  local sl = p.statusline or p.surface0

  -- ── Statusline base ────────────────────────────────────────────────────────
  hl(0, "StatusLine",              { fg = p.text,    bg = sl            })
  hl(0, "StatusLineNC",            { fg = p.overlay0, bg = sl           })

  -- ── lualine component groups ───────────────────────────────────────────────
  -- Mode indicators (match mode colours)
  hl(0, "LualineModeNormal",       { fg = p.base,    bg = p.blue,  bold = true })
  hl(0, "LualineModeInsert",       { fg = p.base,    bg = p.green, bold = true })
  hl(0, "LualineModeVisual",       { fg = p.base,    bg = p.mauve, bold = true })
  hl(0, "LualineModeReplace",      { fg = p.base,    bg = p.red,   bold = true })
  hl(0, "LualineModeCommand",      { fg = p.base,    bg = p.peach, bold = true })
  hl(0, "LualineModeTerminal",     { fg = p.base,    bg = p.teal,  bold = true })
  hl(0, "LualineModeSelect",       { fg = p.base,    bg = p.pink,  bold = true })
  hl(0, "LualineModeInactive",     { fg = p.overlay0, bg = sl              })

  -- Git branch
  hl(0, "LualineGitBranch",        { fg = p.mauve,   bg = sl, bold = true   })
  hl(0, "LualineGitAdded",         { fg = p.green,   bg = sl              })
  hl(0, "LualineGitChanged",       { fg = p.yellow,  bg = sl              })
  hl(0, "LualineGitRemoved",       { fg = p.red,     bg = sl              })

  -- File info
  hl(0, "LualineFilename",         { fg = p.text,    bg = sl              })
  hl(0, "LualineFilenameModified", { fg = p.yellow,  bg = sl, bold = true  })
  hl(0, "LualineFilenameReadonly", { fg = p.red,     bg = sl, italic = true })
  hl(0, "LualineFiletype",         { fg = p.blue,    bg = sl              })
  hl(0, "LualineFileformat",       { fg = p.overlay0, bg = sl             })
  hl(0, "LualineEncoding",         { fg = p.overlay0, bg = sl             })

  -- Location
  hl(0, "LualineLocation",         { fg = p.blue,    bg = sl              })
  hl(0, "LualineProgress",         { fg = p.blue,    bg = sl, bold = true  })
  hl(0, "LualineLinecol",          { fg = p.overlay0, bg = sl             })

  -- Diagnostics in statusline
  hl(0, "LualineDiagError",        { fg = p.red,     bg = sl, bold = true  })
  hl(0, "LualineDiagWarn",         { fg = p.yellow,  bg = sl              })
  hl(0, "LualineDiagInfo",         { fg = p.blue,    bg = sl              })
  hl(0, "LualineDiagHint",         { fg = p.teal,    bg = sl              })

  -- LSP
  hl(0, "LualineLspName",          { fg = p.teal,    bg = sl, italic = true })
  hl(0, "LualineLspActive",        { fg = p.green,   bg = sl, bold = true   })
  hl(0, "LualineLspInactive",      { fg = p.overlay0, bg = sl              })

  -- Separators (powerline)
  hl(0, "LualineSeparator",        { fg = p.surface2, bg = sl             })
  hl(0, "LualineSeparatorRight",   { fg = sl,         bg = p.surface2     })

  -- Winbar
  hl(0, "WinBar",                  { fg = p.text,    bg = p.base          })
  hl(0, "WinBarNC",                { fg = p.overlay0, bg = p.base         })
  hl(0, "WinBarFilename",          { fg = p.blue,    bg = p.base, bold = true })
  hl(0, "WinBarFilepath",          { fg = p.overlay0, bg = p.base, italic = true })
  hl(0, "WinBarModified",          { fg = p.yellow,  bg = p.base, bold = true })
  hl(0, "WinBarReadonly",          { fg = p.red,     bg = p.base, italic = true })
  hl(0, "WinBarSeparator",         { fg = p.overlay0, bg = p.base         })
  hl(0, "WinBarNavicSep",          { fg = p.overlay0, bg = p.base         })

  -- ASH custom statusline components
  hl(0, "AshStatusMode",           { fg = p.base,    bg = p.blue, bold = true })
  hl(0, "AshStatusGit",            { fg = p.mauve,   bg = sl              })
  hl(0, "AshStatusLsp",            { fg = p.teal,    bg = sl, italic = true })
  hl(0, "AshStatusCwd",            { fg = p.blue,    bg = sl, italic = true })
  hl(0, "AshStatusTheme",          { fg = p.mauve,   bg = sl              })
  hl(0, "AshStatusTime",           { fg = p.overlay0, bg = sl, italic = true })
  hl(0, "AshStatusCopilot",        { fg = "#6cc644", bg = sl              })
  hl(0, "AshStatusCodeium",        { fg = "#09B6A2", bg = sl              })
  hl(0, "AshStatusOverseer",       { fg = p.yellow,  bg = sl              })
  hl(0, "AshStatusRecording",      { fg = p.red,     bg = sl, bold = true  })
  hl(0, "AshStatusHarpoon",        { fg = p.peach,   bg = sl              })
  hl(0, "AshStatusSearch",         { fg = p.yellow,  bg = sl, bold = true  })
  hl(0, "AshStatusMacro",          { fg = p.red,     bg = sl, bold = true, blink = true })
  hl(0, "AshStatusWakaTime",       { fg = p.teal,    bg = sl              })
end

---Setup lualine with the ASH theme
---@param p table ASH palette
function M.setup(p)
  local ok, lualine = pcall(require, "lualine")
  if not ok then return end

  -- Apply direct highlights first
  M.apply(p)

  -- Generate and apply the lualine theme
  local theme = M.make_theme(p)

  -- Patch the active lualine theme without full reload
  local ok_cfg, cfg = pcall(lualine.get_config)
  if ok_cfg and cfg then
    cfg.options = cfg.options or {}
    cfg.options.theme = theme
    pcall(lualine.setup, cfg)
  end
end

return M