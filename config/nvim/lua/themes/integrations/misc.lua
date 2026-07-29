-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🎨 MISC INTEGRATIONS — ASH THEME ENGINE v5.0 OMEGA                       ║
-- ║   Everything else: marks · illuminate · flash · mini · overseer               ║
-- ║   neotest · harpoon · oil · spectre · copilot · wakatime · and more          ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

---Apply miscellaneous plugin highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ⚡ FLASH.NVIM
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "FlashLabel",              { fg = p.base,    bg = p.red,    bold = true })
  hl(0, "FlashMatch",              { fg = p.text,    bg = p.surface1            })
  hl(0, "FlashCurrent",            { fg = p.base,    bg = p.blue,   bold = true })
  hl(0, "FlashBackdrop",           { fg = p.overlay0                            })
  hl(0, "FlashCursor",             { reverse = true                             })
  hl(0, "FlashPrompt",             { bold = true,    link = "MsgArea"           })
  hl(0, "FlashPromptIcon",         { fg = p.peach,   bold = true                })
  hl(0, "FlashTreesitter",         { fg = p.green,   bold = true, italic = true })
  hl(0, "FlashRemote",             { fg = p.yellow,  bold = true                })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 💡 VIM-ILLUMINATE
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "IlluminatedWordText",     { bg = p.surface1                           })
  hl(0, "IlluminatedWordRead",     { bg = p.diff_add    or p.surface1          })
  hl(0, "IlluminatedWordWrite",    { bg = p.diff_delete or p.surface1          })
  hl(0, "illuminatedWord",         { link = "IlluminatedWordText"              })
  hl(0, "illuminatedCurWord",      { link = "IlluminatedWordText"              })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📍 MARKS.NVIM
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "MarkSignHL",              { fg = p.blue,    bold = true               })
  hl(0, "MarkSignNumHL",           { fg = p.blue,    bold = true               })
  hl(0, "MarkVirtTextHL",          { fg = p.blue,    italic = true             })
  hl(0, "MarkGlobalSignHL",        { fg = p.peach,   bold = true               })
  hl(0, "MarkGlobalVirtTextHL",    { fg = p.peach,   italic = true             })

  -- Bookmark groups
  local bookmark_colours = {
    p.red, p.peach, p.yellow, p.green, p.teal, p.blue, p.mauve, p.pink, p.flamingo,
  }
  for i = 1, 9 do
    local c = bookmark_colours[i] or p.blue
    hl(0, "BookmarkSign"       .. i, { bold = true,   fg = c })
    hl(0, "BookmarkAnnotation" .. i, { italic = true, fg = c })
    hl(0, "BookmarkVirtText"   .. i, { italic = true, fg = c })
    hl(0, "BookmarkNumber"     .. i, { bold = true,   fg = c })
  end

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🧪 NEOTEST
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NeotestPassed",           { fg = p.green,   bold = true               })
  hl(0, "NeotestFailed",           { fg = p.red,     bold = true               })
  hl(0, "NeotestRunning",          { fg = p.yellow,  bold = true               })
  hl(0, "NeotestSkipped",          { fg = p.overlay0                           })
  hl(0, "NeotestUnknown",          { fg = p.overlay0                           })
  hl(0, "NeotestNormal",           { link = "NormalFloat"                      })
  hl(0, "NeotestNormalNC",         { link = "NormalFloat"                      })
  hl(0, "NeotestBorder",           { link = "FloatBorder"                      })
  hl(0, "NeotestDir",              { fg = p.blue,    bold = true               })
  hl(0, "NeotestFile",             { fg = p.text                               })
  hl(0, "NeotestNamespace",        { fg = p.mauve,   bold = true               })
  hl(0, "NeotestIndent",           { fg = p.surface2                           })
  hl(0, "NeotestExpandMarker",     { fg = p.overlay0                           })
  hl(0, "NeotestWinSelect",        { fg = p.blue,    bold = true               })
  hl(0, "NeotestFocused",          { bold = true,    underline = true          })
  hl(0, "NeotestMarked",           { fg = p.yellow,  bold = true               })
  hl(0, "NeotestTarget",           { fg = p.red,     bold = true               })
  hl(0, "NeotestAdapterName",      { fg = p.blue,    bold = true               })
  hl(0, "NeotestOutput",           { link = "Normal"                           })
  hl(0, "NeotestOutputPanel",      { link = "Normal"                           })
  hl(0, "NeotestTest",             { fg = p.text                               })
  hl(0, "NeotestPassedSign",       { fg = p.green,   bold = true               })
  hl(0, "NeotestFailedSign",       { fg = p.red,     bold = true               })
  hl(0, "NeotestRunningSign",      { fg = p.yellow,  bold = true               })
  hl(0, "NeotestSkippedSign",      { fg = p.overlay0                           })
  hl(0, "NeotestPassedText",       { fg = p.green,   italic = true             })
  hl(0, "NeotestFailedText",       { fg = p.red,     italic = true             })
  hl(0, "NeotestRunningText",      { fg = p.yellow,  italic = true             })
  hl(0, "NeotestSkippedText",      { fg = p.overlay0, italic = true            })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ⚙️  OVERSEER
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "OverseerPENDING",         { fg = p.overlay0                           })
  hl(0, "OverseerWAITING",         { fg = p.teal,    bold = true               })
  hl(0, "OverseerRUNNING",         { fg = p.yellow,  bold = true               })
  hl(0, "OverseerSUCCESS",         { fg = p.green,   bold = true               })
  hl(0, "OverseerFAILURE",         { fg = p.red,     bold = true               })
  hl(0, "OverseerCANCELED",        { fg = p.overlay0, bold = true              })
  hl(0, "OverseerTask",            { fg = p.blue,    bold = true               })
  hl(0, "OverseerTaskBorder",      { fg = p.surface2                           })
  hl(0, "OverseerOutput",          { link = "Normal"                           })
  hl(0, "OverseerComponent",       { fg = p.mauve,   italic = true             })
  hl(0, "OverseerField",           { fg = p.blue                               })
  hl(0, "OverseerNormal",          { link = "NormalFloat"                      })
  hl(0, "OverseerBorder",          { link = "FloatBorder"                      })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎣 HARPOON
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "HarpoonNormal",           { link = "NormalFloat"                      })
  hl(0, "HarpoonBorder",           { link = "FloatBorder"                      })
  hl(0, "HarpoonTitle",            { fg = p.blue,    bold = true               })
  hl(0, "HarpoonNumberActive",     { fg = p.peach,   bold = true               })
  hl(0, "HarpoonNumberInactive",   { fg = p.overlay0                           })
  hl(0, "HarpoonFileActive",       { fg = p.blue,    bold = true               })
  hl(0, "HarpoonFileInactive",     { fg = p.text                               })
  hl(0, "HarpoonCurrent",          { fg = p.blue,    bold = true, underline = true })
  hl(0, "HarpoonGutter",           { fg = p.peach,   bold = true               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🛢️  OIL.NVIM
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "OilNormal",               { link = "NormalFloat"                      })
  hl(0, "OilNormalNC",             { link = "NormalFloat"                      })
  hl(0, "OilBorder",               { link = "FloatBorder"                      })
  hl(0, "OilTitle",                { fg = p.blue,    bold = true               })
  hl(0, "OilDir",                  { fg = p.blue,    bold = true               })
  hl(0, "OilDirIcon",              { fg = p.blue                               })
  hl(0, "OilFile",                 { fg = p.text                               })
  hl(0, "OilLink",                 { fg = p.teal,    italic = true             })
  hl(0, "OilLinkTarget",           { fg = p.teal                               })
  hl(0, "OilExecutable",           { fg = p.green,   bold = true               })
  hl(0, "OilHidden",               { fg = p.overlay0, italic = true            })
  hl(0, "OilGitAdded",             { fg = p.green,   bold = true               })
  hl(0, "OilGitModified",          { fg = p.yellow,  bold = true               })
  hl(0, "OilGitDeleted",           { fg = p.red,     bold = true               })
  hl(0, "OilGitRenamed",           { fg = p.teal                               })
  hl(0, "OilGitUntracked",         { fg = p.overlay0                           })
  hl(0, "OilGitConflict",          { fg = p.red,     bold = true               })
  hl(0, "OilPermissionRead",       { fg = p.yellow,  bold = true               })
  hl(0, "OilPermissionWrite",      { fg = p.red,     bold = true               })
  hl(0, "OilPermissionExecute",    { fg = p.green,   bold = true               })
  hl(0, "OilPermissionNone",       { fg = p.overlay0                           })
  hl(0, "OilSize",                 { fg = p.overlay0, italic = true            })
  hl(0, "OilMtime",                { fg = p.overlay0, italic = true            })
  hl(0, "OilMtimeRecent",          { fg = p.teal,    italic = true             })
  hl(0, "OilModified",             { fg = p.yellow,  bold = true               })
  hl(0, "OilDirPath",              { fg = p.overlay0, italic = true            })
  hl(0, "OilCursor",               { link = "CursorLine"                       })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔍 SPECTRE
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "SpectreNormal",           { link = "NormalFloat"                      })
  hl(0, "SpectreSearch",           {
    bold      = true,
    underline = true,
    fg        = p.peach,
  })
  hl(0, "SpectreReplace",          { bold = true, fg = p.green                 })
  hl(0, "SpectreFile",             { bold = true, link = "Directory"           })
  hl(0, "SpectreBody",             { link = "Normal"                           })
  hl(0, "SpectreHeader",           { bold = true, link = "Title"               })
  hl(0, "SpectreChangeAll",        { bold = true, fg = p.blue                  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌊 CODEIUM / COPILOT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "CopilotSuggestion",       { fg = p.overlay0, italic = true, nocombine = true })
  hl(0, "CopilotAnnotation",       { fg = "#6cc644",  bold = true              })
  hl(0, "CodeiumSuggestion",       { fg = p.overlay0, italic = true, nocombine = true })
  hl(0, "CodeiumEnabled",          { bold = true, fg = "#09B6A2"               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ⏱️  WAKATIME
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "WakaTimeActive",          { bold = true,   fg = p.green               })
  hl(0, "WakaTimeInactive",        { italic = true, fg = p.overlay0            })
  hl(0, "WakaTimeProject",         { bold = true,   fg = p.blue                })
  hl(0, "WakaTimeLanguage",        { italic = true, fg = p.mauve               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📡 NAVIC (breadcrumb)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  local navic_kinds = {
    File          = p.blue,
    Module        = p.mauve,
    Namespace     = p.mauve,
    Package       = p.peach,
    Class         = p.yellow,
    Method        = p.blue,
    Property      = p.text,
    Field         = p.teal,
    Constructor   = p.yellow,
    Enum          = p.teal,
    Interface     = p.teal,
    Function      = p.blue,
    Variable      = p.text,
    Constant      = p.peach,
    String        = p.green,
    Number        = p.peach,
    Boolean       = p.peach,
    Array         = p.teal,
    Object        = p.mauve,
    Key           = p.red,
    Null          = p.overlay0,
    EnumMember    = p.green,
    Struct        = p.yellow,
    Event         = p.red,
    Operator      = p.blue,
    TypeParameter = p.teal,
  }

  for kind, colour in pairs(navic_kinds) do
    hl(0, "NavicIcons" .. kind,    { bold = false, fg = colour                 })
    hl(0, "NavicText" .. kind,     { fg = colour                               })
  end

  hl(0, "NavicSeparator",          { fg = p.overlay0                           })
  hl(0, "NavicText",               { fg = p.text                               })
  hl(0, "NavicBackground",         { link = "WinBar"                           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 💡 LIGHTBULB
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "LightBulbSign",           { fg = p.yellow,  bold = true               })
  hl(0, "LightBulbVirtualText",    { fg = p.yellow,  italic = true             })
  hl(0, "LightBulbStatus",         { fg = p.yellow,  bold = true               })
  hl(0, "LightBulbFloat",          { link = "NormalFloat"                      })
  hl(0, "LightBulbFloatBorder",    { link = "FloatBorder"                      })
  hl(0, "LightBulbPulse",          { fg = p.peach,   bold = true               })
  hl(0, "LightBulbNumHl",          { link = "LightBulbSign"                    })
  hl(0, "LightBulbLine",           { bg = p.surface0                           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔭 GLANCE.NVIM
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "GlanceNormal",            { link = "NormalFloat"                      })
  hl(0, "GlanceBorderTop",         { link = "FloatBorder"                      })
  hl(0, "GlanceBorder",            { link = "FloatBorder"                      })
  hl(0, "GlancePreviewMatch",      { fg = p.peach,   bold = true, underline = true })
  hl(0, "GlanceListMatch",         { fg = p.blue,    bold = true               })
  hl(0, "GlanceListFilename",      { fg = p.blue,    bold = true               })
  hl(0, "GlanceListFilepath",      { fg = p.overlay0, italic = true            })
  hl(0, "GlanceListCount",         { fg = p.teal,    bold = true               })
  hl(0, "GlanceFoldIcon",          { fg = p.overlay0                           })
  hl(0, "GlanceIndent",            { fg = p.surface2                           })
  hl(0, "GlanceWinSeparator",      { link = "WinSeparator"                     })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ✏️  INC-RENAME
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "IncRenamePreviewReference",{ underline = true, sp = p.blue, bg = p.surface1 })
  hl(0, "IncRenameCurrentWord",    {
    bold      = true,
    underline = true,
    sp        = p.peach,
    fg        = p.peach,
    bg        = p.surface0,
  })
  hl(0, "IncRenameNewWord",        { bold = true, fg = p.green, bg = p.surface0 })
  hl(0, "IncRenameError",          { bold = true, fg = p.red,   bg = p.surface0 })
  hl(0, "IncRenameCount",          { bold = true, fg = p.teal                  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📐 TREESITTER-CONTEXT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "TreesitterContext",        { link = "NormalFloat"                      })
  hl(0, "TreesitterContextLineNumber",{ link = "LineNr"                        })
  hl(0, "TreesitterContextSeparator",{ link = "FloatBorder"                    })
  hl(0, "TreesitterContextBottom",  { underline = true, sp = p.blue            })
  hl(0, "TreesitterContextLineNumberBottom", { underline = true                })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🗺️  WHICHKEY EXTRA (not in whichkey.lua)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- Additional colour groups used by which-key v3
  hl(0, "WhichKeyDescription",      { fg = p.text,    italic = false           })
  hl(0, "WhichKeyDescGroup",        { fg = p.blue,    bold = true              })
  hl(0, "WhichKeyThumbterm",        { fg = p.overlay0                          })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎭 MULTICURSOR
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "MultiCursor",              { bold = true, fg = p.base, bg = p.blue    })
  hl(0, "MultiCursorCursor",        { bold = true, reverse = true              })
  hl(0, "MultiCursorVisual",        { bg = p.surface1                          })
  hl(0, "MultiCursorSign",          { bold = true, fg = p.blue                 })
  hl(0, "MultiCursorMatch",         {
    underline = true,
    sp        = p.blue,
    bg        = p.surface1,
  })
  hl(0, "MultiCursorDisabled",      { fg = p.overlay0                          })
  hl(0, "MultiCursorFlash",         { bold = true, fg = p.base, bg = p.peach  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📋 YANKY.NVIM
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "YankyYanked",              { bold = true, bg = p.diff_add   or p.surface0 })
  hl(0, "YankyPut",                 { bold = true, bg = p.info_bg    or p.surface0 })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🏋️  HARDTIME / PRECOGNITION
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "PrecognitionHighlight",     { italic = true, fg = p.overlay0           })
  hl(0, "PrecognitionWordHint",      { italic = true, fg = p.blue               })
  hl(0, "PrecognitionCharHint",      { italic = true, fg = p.green              })
  hl(0, "PrecognitionLineHint",      { italic = true, fg = p.yellow             })
  hl(0, "PrecognitionSectionHint",   { italic = true, fg = p.mauve              })
  hl(0, "PrecognitionMatchHint",     { italic = true, fg = p.peach              })
  hl(0, "PrecognitionScrollHint",    { italic = true, fg = p.teal               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌐 REST.NVIM
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "RestNvimMethodGET",         { bold = true, fg = p.green                })
  hl(0, "RestNvimMethodPOST",        { bold = true, fg = p.blue                 })
  hl(0, "RestNvimMethodPUT",         { bold = true, fg = p.yellow               })
  hl(0, "RestNvimMethodPATCH",       { bold = true, fg = p.peach                })
  hl(0, "RestNvimMethodDELETE",      { bold = true, fg = p.red                  })
  hl(0, "RestNvimStatus2xx",         { bold = true, fg = p.green                })
  hl(0, "RestNvimStatus3xx",         { bold = true, fg = p.blue                 })
  hl(0, "RestNvimStatus4xx",         { bold = true, fg = p.yellow               })
  hl(0, "RestNvimStatus5xx",         { bold = true, fg = p.red                  })
  hl(0, "RestNvimHeader",            { italic = true, fg = p.blue               })
  hl(0, "RestNvimURL",               { underline = true, fg = p.blue            })
  hl(0, "RestNvimVariable",          { bold = true, fg = p.mauve                })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🗄️  DADBOD UI
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DBUITableName",            { bold = true,   fg = p.blue                })
  hl(0, "DBUISourceName",           { bold = true,   fg = p.yellow              })
  hl(0, "DBUIKeyName",              { italic = true, fg = p.mauve               })
  hl(0, "DBUIResultValue",          { fg = p.green                              })
  hl(0, "DBUIResultValueNull",      { italic = true, fg = p.overlay0            })
  hl(0, "DBUIFocusedTable",         { bold = true,   fg = p.green               })
  hl(0, "DBUITable",                { fg = p.text                               })
  hl(0, "DBUISource",               { bold = true,   fg = p.yellow              })
  hl(0, "DBUISourceSchema",         { italic = true, fg = p.teal                })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 LAZY.NVIM (supplement to ash-dynamic core)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "LazyH1",                   { fg = p.base,   bg = p.blue,  bold = true  })
  hl(0, "LazyH2",                   { fg = p.blue,   bold = true                })
  hl(0, "LazyNormal",               { link = "NormalFloat"                      })
  hl(0, "LazyBorder",               { link = "FloatBorder"                      })
  hl(0, "LazyButton",               { fg = p.text,   bg = p.surface0            })
  hl(0, "LazyButtonActive",         { fg = p.base,   bg = p.blue,  bold = true  })
  hl(0, "LazyDimmedButton",         { fg = p.overlay0, bg = p.surface0          })
  hl(0, "LazySpecial",              { fg = p.blue                               })
  hl(0, "LazyLocal",                { fg = p.green                              })
  hl(0, "LazyCommit",               { fg = p.green                              })
  hl(0, "LazyDimmed",               { fg = p.overlay0                           })
  hl(0, "LazyProp",                 { fg = p.overlay0                           })
  hl(0, "LazyValue",                { fg = p.teal                               })
  hl(0, "LazyTaskOutput",           { fg = p.text                               })
  hl(0, "LazyTaskError",            { fg = p.red                                })
  hl(0, "LazyProgressDone",         { bold = true, fg = p.green                 })
  hl(0, "LazyProgressTodo",         { bold = true, fg = p.overlay0              })
  hl(0, "LazyReasonPlugin",         { fg = p.mauve                              })
  hl(0, "LazyReasonEvent",          { fg = p.yellow                             })
  hl(0, "LazyReasonKeys",           { fg = p.teal                               })
  hl(0, "LazyReasonSource",         { fg = p.blue                               })
  hl(0, "LazyReasonImport",         { fg = p.text                               })
  hl(0, "LazyReasonCmd",            { fg = p.peach                              })
  hl(0, "LazyReasonFt",             { fg = p.teal                               })
  hl(0, "LazyReasonStart",          { fg = p.text                               })
  hl(0, "LazyReasonRuntime",        { fg = p.mauve                              })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎵 CAVA VISUALIZER (if using cava in terminal)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "CavaNormal",               { fg = p.blue                               })
  hl(0, "CavaTitle",                { bold = true, fg = p.blue                  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🐛 UNDOTREE
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "UndotreeNode",             { bold = true, fg = p.blue                  })
  hl(0, "UndotreeNodeCurrent",      {
    bold   = true,
    italic = true,
    fg     = p.peach,
    bg     = p.surface0,
  })
  hl(0, "UndotreeSeq",              { fg = p.yellow                             })
  hl(0, "UndotreeNext",             { fg = p.green                              })
  hl(0, "UndotreeCurrent",          { bold = true, fg = p.peach                 })
  hl(0, "UndotreeHead",             { bold = true, underline = true, fg = p.peach })
  hl(0, "UndotreeBranch",           { fg = p.teal                               })
  hl(0, "UndotreeTimeStamp",        { fg = p.overlay0, italic = true            })
  hl(0, "UndotreeSavedBig",         { bold = true, fg = p.green                 })
  hl(0, "UndotreeSavedSmall",       { fg = p.green                              })
  hl(0, "UndotreeFirstNode",        { bold = true, fg = p.mauve                 })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎯 LEETCODE.NVIM
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "LeetCodeEasy",              { bold = true, fg = p.green                 })
  hl(0, "LeetCodeMedium",            { bold = true, fg = p.yellow                })
  hl(0, "LeetCodeHard",              { bold = true, fg = p.red                   })
  hl(0, "LeetCodeAccepted",          { bold = true, fg = p.green                 })
  hl(0, "LeetCodeWrongAnswer",       { bold = true, fg = p.red                   })
  hl(0, "LeetCodeRuntime",           { bold = true, fg = p.blue                  })
  hl(0, "LeetCodeMemory",            { bold = true, fg = p.mauve                 })
  hl(0, "LeetCodeTitle",             { bold = true, fg = p.blue                  })
  hl(0, "LeetCodeTag",               { italic = true, fg = p.mauve               })
  hl(0, "LeetCodeDate",              { italic = true, fg = p.teal                 })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📓 OBSIDIAN.NVIM
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "ObsidianTodo",              { bold = true,   fg = p.yellow              })
  hl(0, "ObsidianDone",              { bold = true,   fg = p.green               })
  hl(0, "ObsidianRightArrow",        { bold = true,   fg = p.peach               })
  hl(0, "ObsidianTilde",             { bold = true,   fg = p.red                 })
  hl(0, "ObsidianImportant",         { bold = true,   fg = p.red                 })
  hl(0, "ObsidianBullet",            { bold = true,   fg = p.blue                })
  hl(0, "ObsidianRef",               { underline = true, fg = p.blue             })
  hl(0, "ObsidianExtLinkIcon",       { fg = p.blue                               })
  hl(0, "ObsidianTag",               { italic = true, fg = p.mauve               })
  hl(0, "ObsidianBlockID",           { italic = true, fg = p.overlay0             })
  hl(0, "ObsidianHighlightText",     { bg = p.surface0, fg = p.yellow             })
  hl(0, "ObsidianDate",              { italic = true, fg = p.teal                 })
  hl(0, "ObsidianFrontMatterKey",    { bold = true,   fg = p.blue                 })
  hl(0, "ObsidianFrontMatterValue",  { fg = p.green                              })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📓 NEORG
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@neorg.headings.1.prefix",  { bold = true, fg = p.blue                  })
  hl(0, "@neorg.headings.2.prefix",  { bold = true, fg = p.green                 })
  hl(0, "@neorg.headings.3.prefix",  { bold = true, fg = p.yellow                })
  hl(0, "@neorg.headings.4.prefix",  { bold = true, fg = p.red                   })
  hl(0, "@neorg.headings.5.prefix",  { bold = true, fg = p.mauve                 })
  hl(0, "@neorg.headings.6.prefix",  { bold = true, fg = p.teal                  })
  hl(0, "@neorg.headings.1.title",   { bold = true, fg = p.blue                  })
  hl(0, "@neorg.headings.2.title",   { bold = true, fg = p.green                 })
  hl(0, "@neorg.headings.3.title",   { bold = true, fg = p.yellow                })
  hl(0, "@neorg.headings.4.title",   { bold = true, fg = p.red                   })
  hl(0, "@neorg.headings.5.title",   { bold = true, fg = p.mauve                 })
  hl(0, "@neorg.headings.6.title",   { bold = true, fg = p.teal                  })
  hl(0, "@neorg.todo_items.done.1",  { bold = true, fg = p.green                 })
  hl(0, "@neorg.todo_items.undone.1",{ fg = p.overlay0                           })
  hl(0, "@neorg.todo_items.pending.1",{ bold = true, fg = p.yellow               })
  hl(0, "@neorg.todo_items.urgent.1",{ bold = true, fg = p.red                   })
  hl(0, "@neorg.markup.bold",        { bold = true                               })
  hl(0, "@neorg.markup.italic",      { italic = true                             })
  hl(0, "@neorg.markup.verbatim",    { fg = p.teal, bg = p.surface0              })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🦆 YAZI.NVIM
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "YaziFloat",                 { link = "NormalFloat"                      })
  hl(0, "YaziBorder",                { link = "FloatBorder"                      })
  hl(0, "YaziTitle",                 { bold = true, fg = p.blue                  })
  hl(0, "YaziDirectory",             { bold = true, fg = p.blue                  })
  hl(0, "YaziFilename",              { bold = true, fg = p.text                  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🤖 AVANTE / CODECOMPANION (supplement to ai/ modules)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "AvanteTitle",               { bold = true, fg = p.mauve                 })
  hl(0, "AvanteAI",                  { bold = true, fg = p.mauve                 })
  hl(0, "AvanteUser",                { bold = true, fg = p.blue                  })
  hl(0, "AvanteConflictCurrent",     { bg = p.diff_add    or p.surface0          })
  hl(0, "AvanteConflictIncoming",    { bg = p.info_bg     or p.surface0          })
  hl(0, "AvanteThinking",            { bold = true, italic = true, fg = p.yellow })
  hl(0, "CodeCompanionChatHeader",   { bold = true, fg = p.blue                  })
  hl(0, "CodeCompanionStreaming",    { bold = true, italic = true, fg = p.mauve  })
  hl(0, "CodeCompanionRoleUser",     { bold = true, fg = p.blue                  })
  hl(0, "CodeCompanionRoleAssistant",{ bold = true, fg = p.mauve                 })
end

return M