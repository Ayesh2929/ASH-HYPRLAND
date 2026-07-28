-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📏 INDENT INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                      ║
-- ║   indent-blankline.nvim · mini.indentscope · highlight.nvim                   ║
-- ║   Context column · scope animation · rainbow · ASH premium indent guides      ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

---Apply indent guide highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  -- Shared base colours
  local indent_col    = p.indent_guide or p.surface1
  local scope_col     = p.overlay0

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📏 INDENT-BLANKLINE.NVIM (ibl)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  -- Standard indent guide
  hl(0, "IblIndent",                { fg = indent_col, nocombine = true       })
  -- Current scope highlight
  hl(0, "IblScope",                 { fg = scope_col,  nocombine = true       })
  -- Whitespace (trailing)
  hl(0, "IblWhitespace",            { fg = indent_col, nocombine = true       })
  -- Scope whitespace
  hl(0, "IblScopeWhitespace",       { fg = scope_col,  nocombine = true       })

  -- Character-level overrides
  hl(0, "IblChar",                  { fg = indent_col, nocombine = true       })
  hl(0, "IblScopeChar",             { fg = p.blue,     nocombine = true       })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌈 RAINBOW INDENT (ibl rainbow extension)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 7-colour rainbow matching treesitter rainbow brackets
  hl(0, "RainbowDelimiterRed",      { fg = p.red                              })
  hl(0, "RainbowDelimiterYellow",   { fg = p.yellow                           })
  hl(0, "RainbowDelimiterBlue",     { fg = p.blue                             })
  hl(0, "RainbowDelimiterOrange",   { fg = p.peach                            })
  hl(0, "RainbowDelimiterGreen",    { fg = p.green                            })
  hl(0, "RainbowDelimiterViolet",   { fg = p.mauve                            })
  hl(0, "RainbowDelimiterCyan",     { fg = p.teal                             })

  -- Rainbow indent guides (level-based)
  hl(0, "IndentBlanklineIndent1",   { fg = p.red,   nocombine = true          })
  hl(0, "IndentBlanklineIndent2",   { fg = p.yellow, nocombine = true         })
  hl(0, "IndentBlanklineIndent3",   { fg = p.blue,  nocombine = true          })
  hl(0, "IndentBlanklineIndent4",   { fg = p.peach, nocombine = true          })
  hl(0, "IndentBlanklineIndent5",   { fg = p.green, nocombine = true          })
  hl(0, "IndentBlanklineIndent6",   { fg = p.mauve, nocombine = true          })
  hl(0, "IndentBlanklineIndent7",   { fg = p.teal,  nocombine = true          })

  -- Scope highlight variants
  hl(0, "IndentBlanklineScope1",    { fg = p.red,   bold = true, nocombine = true })
  hl(0, "IndentBlanklineScope2",    { fg = p.yellow, bold = true, nocombine = true })
  hl(0, "IndentBlanklineScope3",    { fg = p.blue,  bold = true, nocombine = true })
  hl(0, "IndentBlanklineScope4",    { fg = p.peach, bold = true, nocombine = true })
  hl(0, "IndentBlanklineScope5",    { fg = p.green, bold = true, nocombine = true })
  hl(0, "IndentBlanklineScope6",    { fg = p.mauve, bold = true, nocombine = true })
  hl(0, "IndentBlanklineScope7",    { fg = p.teal,  bold = true, nocombine = true })

  -- Context line highlights
  hl(0, "IndentBlanklineContextChar",{ fg = scope_col, nocombine = true      })
  hl(0, "IndentBlanklineContextStart",{ underline = true, sp = scope_col      })
  hl(0, "IndentBlanklineContextSpaceChar", { fg = indent_col, nocombine = true })
  hl(0, "IndentBlanklineChar",       { fg = indent_col, nocombine = true      })
  hl(0, "IndentBlanklineSpaceChar",  { fg = indent_col, nocombine = true      })
  hl(0, "IndentBlanklineSpaceCharBlankline",{ fg = indent_col, nocombine = true })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎯 MINI.INDENTSCOPE
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "MiniIndentscopeSymbol",    {
    fg        = p.blue,
    nocombine = true,
  })
  hl(0, "MiniIndentscopeSymbolOff", {
    fg        = indent_col,
    nocombine = true,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📍 HIGHLIGHT.NVIM — context highlighting
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "HighlightedIndentGuide",   { fg = p.blue,     nocombine = true       })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📏 SNACKS.INDENT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "SnacksIndent",             { fg = indent_col, nocombine = true       })
  hl(0, "SnacksIndentScope",        { fg = p.blue,     nocombine = true       })

  -- Rainbow levels for snacks indent
  hl(0, "SnacksIndentRainbow1",     { fg = p.red,   nocombine = true          })
  hl(0, "SnacksIndentRainbow2",     { fg = p.yellow, nocombine = true         })
  hl(0, "SnacksIndentRainbow3",     { fg = p.blue,  nocombine = true          })
  hl(0, "SnacksIndentRainbow4",     { fg = p.peach, nocombine = true          })
  hl(0, "SnacksIndentRainbow5",     { fg = p.green, nocombine = true          })
  hl(0, "SnacksIndentRainbow6",     { fg = p.mauve, nocombine = true          })
  hl(0, "SnacksIndentRainbow7",     { fg = p.teal,  nocombine = true          })

  -- Chunk highlight
  hl(0, "SnacksIndentChunk",        { fg = p.blue,     nocombine = true       })
end

---Generate ibl highlight groups config (for ibl.setup highlights = ...)
---@param p table ASH palette
---@return table
function M.make_ibl_highlights(p)
  return {
    indent = {
      { highlight = "IblIndent", priority = 1 },
    },
    scope = {
      { highlight = "IblScope",  priority = 2 },
    },
    chunk = {
      { highlight = "IblScopeChar", priority = 2 },
    },
    rainbow = {
      { highlight = "IndentBlanklineIndent1" },
      { highlight = "IndentBlanklineIndent2" },
      { highlight = "IndentBlanklineIndent3" },
      { highlight = "IndentBlanklineIndent4" },
      { highlight = "IndentBlanklineIndent5" },
      { highlight = "IndentBlanklineIndent6" },
      { highlight = "IndentBlanklineIndent7" },
    },
  }
end

return M