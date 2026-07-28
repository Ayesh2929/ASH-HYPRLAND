-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🌲 NEO-TREE INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                    ║
-- ║   File explorer · git status · diagnostics · buffers · sources                 ║
-- ║   Indent markers · expanders · tabs · all highlight groups                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

---Apply Neo-tree highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🪟 WINDOW CHROME
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NeoTreeNormal",                { fg = p.text,    bg = p.base              })
  hl(0, "NeoTreeNormalNC",              { fg = p.subtext0, bg = p.base             })
  hl(0, "NeoTreeEndOfBuffer",           { fg = p.base,    bg = p.base              })
  hl(0, "NeoTreeWinSeparator",          { fg = p.surface1, bg = p.base             })
  hl(0, "NeoTreeSignColumn",            { fg = p.surface1, bg = p.base             })
  hl(0, "NeoTreeCursorLine",            { link = "CursorLine"                      })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🏷️  HEADER / TITLE
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NeoTreeRootName",              { fg = p.blue,    bold = true, italic = true })
  hl(0, "NeoTreeTitleBar",              { fg = p.base,    bg = p.blue, bold = true  })
  hl(0, "NeoTreeFloatTitle",            { fg = p.blue,    bold = true               })
  hl(0, "NeoTreeFloatBorder",           { link = "FloatBorder"                      })
  hl(0, "NeoTreeFloatNormal",           { link = "NormalFloat"                      })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📁 FILES & DIRECTORIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NeoTreeFileName",              { fg = p.text                               })
  hl(0, "NeoTreeFileNameOpened",        { fg = p.blue,    bold = true               })
  hl(0, "NeoTreeDirectoryName",         { fg = p.blue,    bold = true               })
  hl(0, "NeoTreeDirectoryIcon",         { fg = p.blue                               })
  hl(0, "NeoTreeFileIcon",              { fg = p.text                               })
  hl(0, "NeoTreeSymbolicLinkTarget",    { fg = p.teal,    italic = true             })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📊 GIT STATUS BADGES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NeoTreeGitAdded",              { fg = p.green                              })
  hl(0, "NeoTreeGitConflict",           { fg = p.red,     bold = true               })
  hl(0, "NeoTreeGitDeleted",            { fg = p.red                                })
  hl(0, "NeoTreeGitIgnored",            { fg = p.overlay0                           })
  hl(0, "NeoTreeGitModified",           { fg = p.yellow                             })
  hl(0, "NeoTreeGitUnstaged",           { fg = p.yellow                             })
  hl(0, "NeoTreeGitUntracked",          { fg = p.overlay0                           })
  hl(0, "NeoTreeGitStaged",             { fg = p.green,   italic = true             })
  hl(0, "NeoTreeGitRenamed",            { fg = p.teal                               })
  hl(0, "NeoTreeGitNew",                { fg = p.green,   bold = true               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🏥 DIAGNOSTICS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NeoTreeDiagnosticError",       { link = "DiagnosticError"                  })
  hl(0, "NeoTreeDiagnosticWarn",        { link = "DiagnosticWarn"                   })
  hl(0, "NeoTreeDiagnosticInfo",        { link = "DiagnosticInfo"                   })
  hl(0, "NeoTreeDiagnosticHint",        { link = "DiagnosticHint"                   })
  hl(0, "NeoTreeDiagnosticSignError",   { link = "DiagnosticSignError"              })
  hl(0, "NeoTreeDiagnosticSignWarn",    { link = "DiagnosticSignWarn"               })
  hl(0, "NeoTreeDiagnosticSignInfo",    { link = "DiagnosticSignInfo"               })
  hl(0, "NeoTreeDiagnosticSignHint",    { link = "DiagnosticSignHint"               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  TREE CHROME (indent, expanders)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NeoTreeIndentMarker",          { fg = p.surface2                           })
  hl(0, "NeoTreeExpander",              { fg = p.overlay0                           })
  hl(0, "NeoTreeFoldIcon",              { fg = p.overlay0                           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🗂️  SOURCE TABS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NeoTreeTabActive",             { fg = p.text,    bg = p.base,  bold = true })
  hl(0, "NeoTreeTabInactive",           { fg = p.overlay0, bg = p.surface0          })
  hl(0, "NeoTreeTabSeparatorActive",    { fg = p.blue,    bg = p.base               })
  hl(0, "NeoTreeTabSeparatorInactive",  { fg = p.surface1, bg = p.surface0          })
  hl(0, "NeoTreeTabBar",                { fg = p.overlay0, bg = p.surface0          })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📋 BUFFERS SOURCE
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NeoTreeBufferNumber",          { fg = p.peach,   bold = true               })
  hl(0, "NeoTreeModified",              { fg = p.yellow                             })
  hl(0, "NeoTreeCopiedToClipboard",     { fg = p.teal,    italic = true             })
  hl(0, "NeoTreeCutToClipboard",        { fg = p.red,     italic = true             })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎨 MISC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NeoTreeMessage",               { fg = p.overlay0, italic = true             })
  hl(0, "NeoTreeDimText",               { fg = p.overlay0                            })
  hl(0, "NeoTreeHiddenByName",          { fg = p.overlay0                            })
  hl(0, "NeoTreeDotfile",               { fg = p.overlay0, italic = true             })
  hl(0, "NeoTreeGitStatusColumnTitle",  { fg = p.blue,    bold = true                })
  hl(0, "NeoTreeStatusColumnSeparator", { fg = p.surface1                            })
  hl(0, "NeoTreeStatusLine",            { link = "StatusLine"                        })
  hl(0, "NeoTreeStatusLineNC",          { link = "StatusLineNC"                      })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📝 CONTEXT / PREVIEW TEXT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NeoTreePreview",               { fg = p.text,    bg = p.surface0            })
  hl(0, "NeoTreeFileDetails",           { fg = p.overlay0, italic = true             })
  hl(0, "NeoTreeStat",                  { fg = p.overlay0                            })
  hl(0, "NeoTreeStatModified",          { fg = p.yellow                              })
  hl(0, "NeoTreeStatAdded",             { fg = p.green                               })
  hl(0, "NeoTreeStatRemoved",           { fg = p.red                                 })

  -- Mini Files compat
  hl(0, "MiniFilesNormal",              { link = "NeoTreeNormal"                     })
  hl(0, "MiniFilesBorder",              { link = "FloatBorder"                       })
  hl(0, "MiniFilesDirectory",           { fg = p.blue,    bold = true                })
  hl(0, "MiniFilesFile",                { fg = p.text                                })
  hl(0, "MiniFilesTitleFocused",        { fg = p.blue,    bold = true, reverse = true })
  hl(0, "MiniFilesTitle",               { bold = true                                })
  hl(0, "MiniFilesCursorLine",          { link = "CursorLine"                        })
  hl(0, "MiniFilesBorderModified",      { fg = p.yellow                              })
end

return M