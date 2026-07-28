-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📑 BUFFERLINE INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                  ║
-- ║   Tab bar · active/inactive/visible buffers · modified · diagnostics           ║
-- ║   Separators · groups · pinned · close buttons · premium glass style           ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

---Apply bufferline highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎨 BASE FILL (background of the whole tabline)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "BufferLineFill",               { fg = p.overlay0, bg = p.surface0          })
  hl(0, "BufferLineBackground",         { fg = p.overlay0, bg = p.surface0          })
  hl(0, "BufferLineNumbers",            { fg = p.overlay0, bg = p.surface0          })
  hl(0, "BufferLineCloseButton",        { fg = p.overlay0, bg = p.surface0          })
  hl(0, "BufferLineSeparator",          { fg = p.base,     bg = p.surface0          })
  hl(0, "BufferLineIndicatorVisible",   { fg = p.surface0, bg = p.surface0          })
  hl(0, "BufferLineModified",           { fg = p.yellow,   bg = p.surface0          })
  hl(0, "BufferLineDuplicateInactive",  { fg = p.overlay0, bg = p.surface0, italic = true })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 👁️  VISIBLE (non-active, but focused window)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "BufferLineBufferVisible",      { fg = p.subtext0,  bg = p.surface0         })
  hl(0, "BufferLineNumbersVisible",     { fg = p.subtext0,  bg = p.surface0         })
  hl(0, "BufferLineCloseButtonVisible", { fg = p.subtext0,  bg = p.surface0         })
  hl(0, "BufferLineSeparatorVisible",   { fg = p.base,      bg = p.surface0         })
  hl(0, "BufferLineIndicatorSelected",  { fg = p.blue,      bg = p.surface0         })
  hl(0, "BufferLineModifiedVisible",    { fg = p.yellow,    bg = p.surface0         })
  hl(0, "BufferLineDuplicateVisible",   { fg = p.subtext0,  bg = p.surface0, italic = true })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ✅ SELECTED (active buffer)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "BufferLineBufferSelected",     { fg = p.text,      bg = p.base, bold = true })
  hl(0, "BufferLineNumbersSelected",    { fg = p.blue,      bg = p.base, bold = true })
  hl(0, "BufferLineCloseButtonSelected",{ fg = p.text,      bg = p.base             })
  hl(0, "BufferLineSeparatorSelected",  { fg = p.blue,      bg = p.base             })
  hl(0, "BufferLineModifiedSelected",   { fg = p.yellow,    bg = p.base, bold = true })
  hl(0, "BufferLineDuplicateSelected",  { fg = p.text,      bg = p.base, italic = true })
  hl(0, "BufferLineIndicatorSelected",  { fg = p.blue,      bg = p.base             })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔴 DIAGNOSTICS — inactive
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "BufferLineDiagnostic",         { fg = p.overlay0,  bg = p.surface0         })
  hl(0, "BufferLineHint",               { fg = p.teal,      bg = p.surface0         })
  hl(0, "BufferLineHintDiagnostic",     { fg = p.teal,      bg = p.surface0         })
  hl(0, "BufferLineInfo",               { fg = p.blue,      bg = p.surface0         })
  hl(0, "BufferLineInfoDiagnostic",     { fg = p.blue,      bg = p.surface0         })
  hl(0, "BufferLineWarning",            { fg = p.yellow,    bg = p.surface0         })
  hl(0, "BufferLineWarningDiagnostic",  { fg = p.yellow,    bg = p.surface0         })
  hl(0, "BufferLineError",              { fg = p.red,       bg = p.surface0         })
  hl(0, "BufferLineErrorDiagnostic",    { fg = p.red,       bg = p.surface0         })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 👁️  DIAGNOSTICS — visible (focused window, non-active tab)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "BufferLineDiagnosticVisible",  { fg = p.overlay0,  bg = p.surface0         })
  hl(0, "BufferLineHintVisible",        { fg = p.teal,      bg = p.surface0         })
  hl(0, "BufferLineHintDiagnosticVisible",{ fg = p.teal,    bg = p.surface0         })
  hl(0, "BufferLineInfoVisible",        { fg = p.blue,      bg = p.surface0         })
  hl(0, "BufferLineInfoDiagnosticVisible",{ fg = p.blue,    bg = p.surface0         })
  hl(0, "BufferLineWarningVisible",     { fg = p.yellow,    bg = p.surface0         })
  hl(0, "BufferLineWarningDiagnosticVisible",{ fg = p.yellow, bg = p.surface0       })
  hl(0, "BufferLineErrorVisible",       { fg = p.red,       bg = p.surface0         })
  hl(0, "BufferLineErrorDiagnosticVisible",{ fg = p.red,    bg = p.surface0         })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ✅ DIAGNOSTICS — selected (active buffer)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "BufferLineDiagnosticSelected", { fg = p.overlay0,  bg = p.base             })
  hl(0, "BufferLineHintSelected",       { fg = p.teal,      bg = p.base             })
  hl(0, "BufferLineHintDiagnosticSelected",{ fg = p.teal,   bg = p.base             })
  hl(0, "BufferLineInfoSelected",       { fg = p.blue,      bg = p.base             })
  hl(0, "BufferLineInfoDiagnosticSelected",{ fg = p.blue,   bg = p.base             })
  hl(0, "BufferLineWarningSelected",    { fg = p.yellow,    bg = p.base             })
  hl(0, "BufferLineWarningDiagnosticSelected",{ fg = p.yellow, bg = p.base          })
  hl(0, "BufferLineErrorSelected",      { fg = p.red,       bg = p.base, bold = true })
  hl(0, "BufferLineErrorDiagnosticSelected",{ fg = p.red,   bg = p.base             })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📌 PINNED BUFFERS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "BufferLinePinned",             { fg = p.mauve,     bg = p.surface0         })
  hl(0, "BufferLinePinnedSelected",     { fg = p.mauve,     bg = p.base, bold = true })
  hl(0, "BufferLinePinnedVisible",      { fg = p.mauve,     bg = p.surface0         })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🗂️  GROUPS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "BufferLineGroupSeparator",     { fg = p.blue,      bg = p.surface0, bold = true })
  hl(0, "BufferLineGroupLabel",         { fg = p.base,      bg = p.blue,     bold = true })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  OFFSET / PANELS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "BufferLineOffsetSeparator",    { fg = p.surface1,  bg = p.surface0         })
  hl(0, "BufferLineTruncMarker",        { fg = p.overlay0,  bg = p.surface0         })
  hl(0, "BufferLineTab",                { fg = p.overlay0,  bg = p.surface0         })
  hl(0, "BufferLineTabSelected",        { fg = p.text,      bg = p.base, bold = true })
  hl(0, "BufferLineTabSeparator",       { fg = p.base,      bg = p.surface0         })
  hl(0, "BufferLineTabSeparatorSelected",{ fg = p.blue,     bg = p.base             })
  hl(0, "BufferLineTabClose",           { fg = p.red,       bg = p.surface0         })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📐 SLANT / SLOPE SEPARATORS (for slant style)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- Left slope (inactive → fill)
  hl(0, "BufferLineSlantBackground",    { fg = p.surface0,  bg = p.base             })
  hl(0, "BufferLineSlantSelectedLeft",  { fg = p.base,      bg = p.surface0         })
  hl(0, "BufferLineSlantSelectedRight", { fg = p.surface0,  bg = p.base             })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ⚡ STATUSLINE integration
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- When using "always" or "merging" statusline mode
  hl(0, "BufferLineCurrentSign",        { fg = p.blue,      bg = p.base             })
  hl(0, "BufferLineActiveTab",          { fg = p.blue,      bg = p.surface0         })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎨 LUALINE TABLINE COMPAT (mini.tabline)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "MiniTablineCurrent",           { fg = p.text,      bg = p.base, bold = true })
  hl(0, "MiniTablineHidden",            { fg = p.overlay0,  bg = p.surface0         })
  hl(0, "MiniTablineModifiedCurrent",   { fg = p.yellow,    bg = p.base, bold = true })
  hl(0, "MiniTablineModifiedHidden",    { fg = p.yellow,    bg = p.surface0         })
  hl(0, "MiniTablineModifiedVisible",   { fg = p.yellow,    bg = p.surface0         })
  hl(0, "MiniTablineVisible",           { fg = p.subtext0,  bg = p.surface0         })
  hl(0, "MiniTablineTabpagesection",    { fg = p.base,      bg = p.blue, bold = true })
  hl(0, "MiniTablineFill",              { fg = p.overlay0,  bg = p.surface0         })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎛️  BUFFERLINE OPTS HELPER — generate highlights table for bufferline.setup()
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---Generate bufferline.nvim highlights config table from palette
---@param p table ASH palette
---@return table   Suitable for bufferline.setup({ highlights = ... })
function M.make_highlights(p)
  local fill_bg = p.surface0

  local function make(fg, bg, bold, italic)
    local t = {}
    if fg    then t.fg     = fg    end
    if bg    then t.bg     = bg    end
    if bold  then t.bold   = true  end
    if italic then t.italic= true  end
    return t
  end

  return {
    fill                            = make(p.overlay0, fill_bg),
    background                      = make(p.overlay0, fill_bg),
    numbers                         = make(p.overlay0, fill_bg),
    close_button                    = make(p.overlay0, fill_bg),
    separator                       = make(p.base,     fill_bg),
    modified                        = make(p.yellow,   fill_bg),
    duplicate                       = make(p.overlay0, fill_bg, false, true),

    buffer_visible                  = make(p.subtext0, fill_bg),
    numbers_visible                 = make(p.subtext0, fill_bg),
    close_button_visible            = make(p.subtext0, fill_bg),
    separator_visible               = make(p.base,     fill_bg),
    modified_visible                = make(p.yellow,   fill_bg),
    duplicate_visible               = make(p.subtext0, fill_bg, false, true),

    buffer_selected                 = make(p.text,     p.base, true),
    numbers_selected                = make(p.blue,     p.base, true),
    close_button_selected           = make(p.text,     p.base),
    separator_selected              = make(p.blue,     p.base),
    modified_selected               = make(p.yellow,   p.base, true),
    duplicate_selected              = make(p.text,     p.base, false, true),
    indicator_selected              = make(p.blue,     p.base),

    diagnostic                      = make(p.overlay0, fill_bg),
    hint                            = make(p.teal,     fill_bg),
    hint_diagnostic                 = make(p.teal,     fill_bg),
    info                            = make(p.blue,     fill_bg),
    info_diagnostic                 = make(p.blue,     fill_bg),
    warning                         = make(p.yellow,   fill_bg),
    warning_diagnostic              = make(p.yellow,   fill_bg),
    error                           = make(p.red,      fill_bg),
    error_diagnostic                = make(p.red,      fill_bg),

    hint_selected                   = make(p.teal,     p.base),
    hint_diagnostic_selected        = make(p.teal,     p.base),
    info_selected                   = make(p.blue,     p.base),
    info_diagnostic_selected        = make(p.blue,     p.base),
    warning_selected                = make(p.yellow,   p.base),
    warning_diagnostic_selected     = make(p.yellow,   p.base),
    error_selected                  = make(p.red,      p.base, true),
    error_diagnostic_selected       = make(p.red,      p.base),

    pinned                          = make(p.mauve,    fill_bg),
    pinned_selected                 = make(p.mauve,    p.base, true),
    pinned_visible                  = make(p.mauve,    fill_bg),

    group_separator                 = make(p.blue,     fill_bg, true),
    group_label                     = make(p.base,     p.blue,  true),

    tab                             = make(p.overlay0, fill_bg),
    tab_selected                    = make(p.text,     p.base,  true),
    tab_separator                   = make(p.base,     fill_bg),
    tab_separator_selected          = make(p.blue,     p.base),
    tab_close                       = make(p.red,      fill_bg),

    trunc_marker                    = make(p.overlay0, fill_bg),
    offset_separator                = make(p.surface1, fill_bg),
  }
end

return M