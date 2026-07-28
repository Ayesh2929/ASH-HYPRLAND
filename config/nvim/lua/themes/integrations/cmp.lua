-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ⚡ CMP INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                          ║
-- ║   nvim-cmp · all item kinds · ghost text · documentation float                 ║
-- ║   Source labels · fuzzy match · deprecated · ASH premium completion UI         ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- All LSP completion item kinds with their colours
local KIND_COLOURS = function(p)
  return {
    Text          = p.text,
    Method        = p.blue,
    Function      = p.blue,
    Constructor   = p.sapphire,
    Field         = p.text,
    Variable      = p.text,
    Class         = p.yellow,
    Interface     = p.teal,
    Module        = p.blue,
    Property      = p.text,
    Unit          = p.peach,
    Value         = p.green,
    Enum          = p.teal,
    Keyword       = p.mauve,
    Snippet       = p.green,
    Color         = p.mauve,
    File          = p.blue,
    Reference     = p.teal,
    Folder        = p.blue,
    EnumMember    = p.teal,
    Constant      = p.peach,
    Struct        = p.yellow,
    Event         = p.red,
    Operator      = p.sky,
    TypeParameter = p.teal,
    -- AI sources
    Copilot       = "#6cc644",
    Codeium       = "#09B6A2",
    Supermaven    = "#6f6c99",
    TabNine       = "#ca42f0",
    -- Other sources
    Buffer        = p.text,
    Path          = p.peach,
    Emoji         = p.yellow,
    Calc          = p.peach,
    Spell         = p.green,
    Cmdline       = p.blue,
    Git           = "#f05133",
    Rg            = p.mauve,
    Treesitter    = p.green,
    NvimLua       = p.blue,
    Luasnip       = p.green,
  }
end

---Apply nvim-cmp highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl     = vim.api.nvim_set_hl
  local kinds  = KIND_COLOURS(p)

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🪟 WINDOW CHROME
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "CmpNormal",                   { fg = p.text,    bg = p.float_bg           })
  hl(0, "CmpBorder",                   { fg = p.border,  bg = p.float_bg           })
  hl(0, "CmpScrollbar",                { link = "PmenuSbar"                        })
  hl(0, "CmpScrollbarThumb",           { link = "PmenuThumb"                       })
  hl(0, "CmpCursorLine",               { link = "PmenuSel"                         })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📝 ITEM TEXT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "CmpItemAbbr",                 { fg = p.text,    bg = "NONE"               })
  hl(0, "CmpItemAbbrDeprecated",       {
    fg            = p.overlay0,
    bg            = "NONE",
    strikethrough = true,
  })
  hl(0, "CmpItemAbbrMatch",            {
    fg   = p.blue,
    bg   = "NONE",
    bold = true,
  })
  hl(0, "CmpItemAbbrMatchFuzzy",       {
    fg     = p.blue,
    bg     = "NONE",
    bold   = true,
    italic = true,
  })
  hl(0, "CmpItemMenu",                 {
    fg     = p.overlay0,
    bg     = "NONE",
    italic = true,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 👻 GHOST TEXT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "CmpGhostText",                {
    fg     = p.overlay0,
    italic = true,
    nocombine = true,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📖 DOCUMENTATION FLOAT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "CmpDoc",                      { fg = p.text,    bg = p.float_bg           })
  hl(0, "CmpDocBorder",                { fg = p.border,  bg = p.float_bg           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🏷️  ITEM KINDS — icon + text highlight
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  for kind, colour in pairs(kinds) do
    hl(0, "CmpItemKind" .. kind,       { fg = colour, bg = "NONE"                  })
    hl(0, "CmpItemKindIcon" .. kind,   { fg = colour, bg = "NONE"                  })
  end

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔌 SOURCE BADGES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "CmpSourceLsp",                { bold = true, fg = p.blue                  })
  hl(0, "CmpSourceSnippet",            { bold = true, fg = p.green                 })
  hl(0, "CmpSourceBuffer",             { bold = true, fg = p.text                  })
  hl(0, "CmpSourcePath",               { bold = true, fg = p.peach                 })
  hl(0, "CmpSourceCopilot",            { bold = true, fg = "#6cc644"               })
  hl(0, "CmpSourceCodeium",            { bold = true, fg = "#09B6A2"               })
  hl(0, "CmpSourceSupermaven",         { bold = true, fg = "#6f6c99"               })
  hl(0, "CmpSourceGit",                { bold = true, fg = "#f05133"               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔌 BLINK.CMP (alternative completion engine)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "BlinkCmpMenu",                { fg = p.text,   bg = p.float_bg            })
  hl(0, "BlinkCmpMenuBorder",          { fg = p.border, bg = p.float_bg            })
  hl(0, "BlinkCmpMenuSelection",       { fg = p.base,   bg = p.blue                })
  hl(0, "BlinkCmpScrollBarThumb",      { link = "PmenuThumb"                       })
  hl(0, "BlinkCmpScrollBarGutter",     { link = "PmenuSbar"                        })
  hl(0, "BlinkCmpLabel",               { fg = p.text                               })
  hl(0, "BlinkCmpLabelDeprecated",     { fg = p.overlay0, strikethrough = true     })
  hl(0, "BlinkCmpLabelMatch",          { fg = p.blue,   bold = true                })
  hl(0, "BlinkCmpLabelDetail",         { fg = p.overlay0, italic = true            })
  hl(0, "BlinkCmpLabelDescription",    { fg = p.overlay0, italic = true            })
  hl(0, "BlinkCmpGhostText",           { fg = p.overlay0, italic = true            })
  hl(0, "BlinkCmpDoc",                 { fg = p.text,   bg = p.float_bg            })
  hl(0, "BlinkCmpDocBorder",           { fg = p.border, bg = p.float_bg            })
  hl(0, "BlinkCmpDocSeparator",        { fg = p.surface1                           })
  hl(0, "BlinkCmpDocCursorLine",       { link = "PmenuSel"                         })
  hl(0, "BlinkCmpSignatureHelp",       { fg = p.text,   bg = p.float_bg            })
  hl(0, "BlinkCmpSignatureHelpBorder", { fg = p.border, bg = p.float_bg            })
  hl(0, "BlinkCmpSignatureHelpActiveParameter", {
    bold      = true,
    underline = true,
    sp        = p.blue,
  })

  for kind, colour in pairs(kinds) do
    hl(0, "BlinkCmpKind" .. kind,      { fg = colour                               })
  end
end

return M