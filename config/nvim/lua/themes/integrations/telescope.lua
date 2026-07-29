-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔭 TELESCOPE INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                   ║
-- ║   All Telescope windows · previewer · prompt · results · selection             ║
-- ║   Border styles · title bars · match highlighting · ASH glass UI               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

---Apply Telescope highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🪟 WINDOW BACKGROUNDS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TelescopeNormal",              { fg = p.text,     bg = p.float_bg           })
  hl(0, "TelescopePromptNormal",        { fg = p.text,     bg = p.surface0           })
  hl(0, "TelescopeResultsNormal",       { fg = p.text,     bg = p.float_bg           })
  hl(0, "TelescopePreviewNormal",       { fg = p.text,     bg = p.float_bg           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🖼️  BORDERS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TelescopeBorder",              { fg = p.float_bg, bg = p.float_bg           })
  hl(0, "TelescopePromptBorder",        { fg = p.surface0, bg = p.surface0           })
  hl(0, "TelescopeResultsBorder",       { fg = p.float_bg, bg = p.float_bg           })
  hl(0, "TelescopePreviewBorder",       { fg = p.float_bg, bg = p.float_bg           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🏷️  TITLE BARS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TelescopeTitle",               { fg = p.base,     bg = p.blue,  bold = true })
  hl(0, "TelescopePromptTitle",         { fg = p.base,     bg = p.blue,  bold = true })
  hl(0, "TelescopeResultsTitle",        { fg = p.float_bg, bg = p.float_bg           })
  hl(0, "TelescopePreviewTitle",        { fg = p.base,     bg = p.green, bold = true })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ✨ SELECTION & MATCHING
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TelescopeSelection",           {
    fg   = p.text,
    bg   = p.surface1,
    bold = true,
  })
  hl(0, "TelescopeSelectionCaret",      { fg = p.blue,                bold = true    })
  hl(0, "TelescopeMultiIcon",           { fg = p.mauve                               })
  hl(0, "TelescopeMultiSelection",      { fg = p.mauve,               italic = true  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔤 FUZZY MATCHING
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TelescopeMatching",            {
    fg   = p.yellow,
    bold = true,
  })
  hl(0, "TelescopeMatchingFuzzy",       {
    fg     = p.yellow,
    bold   = true,
    italic = true,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ⌨️  PROMPT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TelescopePromptPrefix",        { fg = p.blue,     bold = true               })
  hl(0, "TelescopePromptCounter",       { fg = p.blue,     italic = true             })
  hl(0, "TelescopePromptText",          { fg = p.text                                })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📋 RESULTS CONTENT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TelescopeResultsClass",        { fg = p.yellow                              })
  hl(0, "TelescopeResultsConstant",     { fg = p.peach                               })
  hl(0, "TelescopeResultsField",        { fg = p.text                                })
  hl(0, "TelescopeResultsFunction",     { fg = p.blue                                })
  hl(0, "TelescopeResultsIdentifier",   { fg = p.text                                })
  hl(0, "TelescopeResultsMethod",       { fg = p.blue                                })
  hl(0, "TelescopeResultsNumber",       { fg = p.peach                               })
  hl(0, "TelescopeResultsOperator",     { fg = p.sky                                 })
  hl(0, "TelescopeResultsStruct",       { fg = p.yellow                              })
  hl(0, "TelescopeResultsVariable",     { fg = p.text                                })
  hl(0, "TelescopeResultsComment",      { fg = p.overlay0, italic = true             })
  hl(0, "TelescopeResultsLineNr",       { fg = p.overlay0                            })
  hl(0, "TelescopeResultsSeparator",    { fg = p.surface1                            })
  hl(0, "TelescopeResultsDiffAdd",      { fg = p.green                               })
  hl(0, "TelescopeResultsDiffChange",   { fg = p.yellow                              })
  hl(0, "TelescopeResultsDiffDelete",   { fg = p.red                                 })
  hl(0, "TelescopeResultsDiffUntracked",{ fg = p.overlay0                            })
  hl(0, "TelescopeResultsGitStatusModified", { fg = p.yellow                        })
  hl(0, "TelescopeResultsGitStatusAdded",    { fg = p.green                         })
  hl(0, "TelescopeResultsGitStatusDeleted",  { fg = p.red                           })
  hl(0, "TelescopeResultsGitStatusUntracked",{ fg = p.overlay0                      })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔍 PREVIEW
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TelescopePreviewLine",         { bg = p.surface1                            })
  hl(0, "TelescopePreviewMatch",        {
    fg   = p.yellow,
    bold = true,
  })
  hl(0, "TelescopePreviewMessageFillchar",{ fg = p.surface1                          })
  hl(0, "TelescopePreviewTruncatedLine",  { fg = p.overlay0                          })
  hl(0, "TelescopePreviewSignColumn",     { link = "SignColumn"                       })
  hl(0, "TelescopePreviewDirectory",      { fg = p.blue,  bold = true                })
  hl(0, "TelescopePreviewSize",           { fg = p.overlay0, italic = true           })
  hl(0, "TelescopePreviewDate",           { fg = p.overlay0, italic = true           })
  hl(0, "TelescopePreviewUser",           { fg = p.mauve                             })
  hl(0, "TelescopePreviewGroup",          { fg = p.blue                              })
  hl(0, "TelescopePreviewLink",           { fg = p.teal, italic = true               })
  hl(0, "TelescopePreviewBlock",          { fg = p.yellow                            })
  hl(0, "TelescopePreviewCharDev",        { fg = p.peach                             })
  hl(0, "TelescopePreviewFifo",           { fg = p.mauve                             })
  hl(0, "TelescopePreviewSocket",         { fg = p.mauve                             })
  hl(0, "TelescopePreviewRead",           { fg = p.teal                              })
  hl(0, "TelescopePreviewWrite",          { fg = p.red                               })
  hl(0, "TelescopePreviewExecute",        { fg = p.green                             })
  hl(0, "TelescopePreviewHyphen",         { fg = p.overlay0                          })
  hl(0, "TelescopePreviewSticky",         { fg = p.mauve, bold = true                })
  hl(0, "TelescopePreviewPipe",           { fg = p.yellow                            })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  EXTENSIONS (fzf-lua, etc.)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TelescopePathSeparator",       { fg = p.overlay0                            })
  hl(0, "TelescopeSymbolWidth",         { fg = p.overlay0                            })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔌 FZF-LUA COMPAT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "FzfLuaNormal",                 { link = "TelescopeNormal"                   })
  hl(0, "FzfLuaBorder",                 { link = "TelescopeBorder"                   })
  hl(0, "FzfLuaTitle",                  { link = "TelescopeTitle"                    })
  hl(0, "FzfLuaPreviewNormal",          { link = "TelescopePreviewNormal"            })
  hl(0, "FzfLuaPreviewBorder",          { link = "TelescopePreviewBorder"            })
  hl(0, "FzfLuaPreviewTitle",           { link = "TelescopePreviewTitle"             })
  hl(0, "FzfLuaCursor",                 { link = "TelescopeSelection"                })
  hl(0, "FzfLuaCursorLine",             { link = "TelescopeSelection"                })
  hl(0, "FzfLuaSearch",                 { link = "TelescopeMatching"                 })
  hl(0, "FzfLuaMatchCurrent",           { link = "TelescopeSelection"                })
  hl(0, "FzfLuaMatchMarked",            { fg = p.mauve                               })
  hl(0, "FzfLuaMatchRanges",            { link = "TelescopeMatching"                 })
  hl(0, "FzfLuaPrompt",                 { fg = p.blue, bold = true                   })
  hl(0, "FzfLuaHeader",                 { fg = p.green, bold = true                  })
  hl(0, "FzfLuaHeaderBind",             { fg = p.mauve                               })
  hl(0, "FzfLuaHeaderText",             { fg = p.overlay0                            })
end

return M