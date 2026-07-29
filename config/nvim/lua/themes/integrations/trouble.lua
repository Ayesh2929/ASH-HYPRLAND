-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🚨 TROUBLE INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                     ║
-- ║   Diagnostics panel · LSP references · quickfix · todo-comments               ║
-- ║   All severity levels · file tree · fold icons · ASH premium UI               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

---Apply Trouble highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🪟 PANEL CHROME
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TroubleNormal",             { fg = p.text,    bg = p.base            })
  hl(0, "TroubleNormalNC",           { fg = p.subtext0, bg = p.base           })
  hl(0, "TroubleBorder",             { link = "FloatBorder"                   })
  hl(0, "TroubleWinSeparator",       { link = "WinSeparator"                  })
  hl(0, "TroubleEndOfBuffer",        { fg = p.base,    bg = p.base            })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🏷️  HEADER / TITLE
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TroubleHeader",             { fg = p.blue,    bold = true             })
  hl(0, "TroubleCount",              { fg = p.yellow,  bold = true             })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📁 FILE PATHS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TroubleFile",               { fg = p.blue                            })
  hl(0, "TroubleFilename",           { fg = p.blue,    bold = true             })
  hl(0, "TroubleBasename",           { fg = p.blue                            })
  hl(0, "TroubleDirectory",          { fg = p.overlay0, italic = true          })
  hl(0, "TroubleRelDir",             { fg = p.overlay0, italic = true          })
  hl(0, "TroubleSource",             { fg = p.overlay0, italic = true          })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📍 LOCATION
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TroublePos",                { fg = p.overlay0                         })
  hl(0, "TroubleLocation",           { fg = p.overlay0                         })
  hl(0, "TroubleCode",               { fg = p.peach,   italic = true           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔴 DIAGNOSTIC SEVERITY
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TroubleError",              { fg = p.red,     bold = true             })
  hl(0, "TroubleWarning",            { fg = p.yellow,  bold = true             })
  hl(0, "TroubleInformation",        { fg = p.blue,    bold = true             })
  hl(0, "TroubleHint",               { fg = p.teal,    bold = true             })
  hl(0, "TroubleOther",              { fg = p.overlay0                         })

  -- Sign column icons
  hl(0, "TroubleSignError",          { link = "DiagnosticSignError"            })
  hl(0, "TroubleSignWarning",        { link = "DiagnosticSignWarn"             })
  hl(0, "TroubleSignInformation",    { link = "DiagnosticSignInfo"             })
  hl(0, "TroubleSignHint",           { link = "DiagnosticSignHint"             })
  hl(0, "TroubleSignOther",          { fg = p.overlay0                         })

  -- Inline text colour
  hl(0, "TroubleTextError",          { fg = p.text                             })
  hl(0, "TroubleTextWarning",        { fg = p.text                             })
  hl(0, "TroubleTextInformation",    { fg = p.text                             })
  hl(0, "TroubleTextHint",           { fg = p.text                             })
  hl(0, "TroubleTextOther",          { fg = p.text                             })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌲 TREE CHROME
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TroubleIndent",             { fg = p.surface2                         })
  hl(0, "TroubleIndentFoldOpen",     { fg = p.overlay0                         })
  hl(0, "TroubleIndentFoldClosed",   { fg = p.overlay0                         })
  hl(0, "TroubleIndentWs",           { fg = p.surface1                         })
  hl(0, "TroubleFoldIcon",           { fg = p.overlay0                         })
  hl(0, "TroubleIconError",          { fg = p.red                              })
  hl(0, "TroubleIconWarning",        { fg = p.yellow                           })
  hl(0, "TroubleIconInformation",    { fg = p.blue                             })
  hl(0, "TroubleIconHint",           { fg = p.teal                             })
  hl(0, "TroubleIconOther",          { fg = p.overlay0                         })
  hl(0, "TroubleIconDirectory",      { fg = p.blue                             })
  hl(0, "TroubleIconFile",           { fg = p.text                             })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🖱️  SELECTION
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TroubleSelected",           { link = "CursorLine"                     })
  hl(0, "TroubleFocused",            { link = "CursorLine"                     })
  hl(0, "TroubleText",               { fg = p.text                             })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ✅ TODO-COMMENTS (trouble mode: todo)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TodoFgTODO",               { fg = p.blue                              })
  hl(0, "TodoFgFIXME",              { fg = p.red                               })
  hl(0, "TodoFgHACK",               { fg = p.yellow                            })
  hl(0, "TodoFgNOTE",               { fg = p.teal                              })
  hl(0, "TodoFgPERF",               { fg = p.mauve                             })
  hl(0, "TodoFgWARN",               { fg = p.yellow                            })
  hl(0, "TodoFgDOCS",               { fg = p.teal                              })
  hl(0, "TodoFgTEST",               { fg = p.green                             })
  hl(0, "TodoFgASH",                { fg = p.peach                             })
  hl(0, "TodoFgOMEGA",              { fg = p.mauve                             })

  hl(0, "TodoBgTODO",               { fg = p.base, bg = p.blue,   bold = true  })
  hl(0, "TodoBgFIXME",              { fg = p.base, bg = p.red,    bold = true  })
  hl(0, "TodoBgHACK",               { fg = p.base, bg = p.yellow, bold = true  })
  hl(0, "TodoBgNOTE",               { fg = p.base, bg = p.teal,   bold = true  })
  hl(0, "TodoBgPERF",               { fg = p.base, bg = p.mauve,  bold = true  })
  hl(0, "TodoBgWARN",               { fg = p.base, bg = p.yellow, bold = true  })
  hl(0, "TodoBgDOCS",               { fg = p.base, bg = p.teal,   bold = true  })
  hl(0, "TodoBgTEST",               { fg = p.base, bg = p.green,  bold = true  })
  hl(0, "TodoBgASH",                { fg = p.base, bg = p.peach,  bold = true  })
  hl(0, "TodoBgOMEGA",              { fg = p.base, bg = p.mauve,  bold = true  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📋 QUICKFIX COMPAT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "QuickFixLine",              { link = "CursorLine"                     })
  hl(0, "qfLineNr",                  { fg = p.yellow                           })
  hl(0, "qfFileName",                { fg = p.blue                             })
  hl(0, "qfSeparator",               { fg = p.overlay0                         })
  hl(0, "qfError",                   { fg = p.red                              })
end

return M