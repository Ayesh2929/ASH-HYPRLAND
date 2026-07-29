-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔧 LSP INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                         ║
-- ║   Semantic tokens · diagnostics · codelens · references · inlay hints          ║
-- ║   Sign column icons · virtual text · float windows · all severities            ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- Premium Nerd Font v3 diagnostic icons
local DIAG_ICONS = {
  Error = " ",
  Warn  = " ",
  Info  = " ",
  Hint  = "󰌵 ",
}

---Register diagnostic sign icons
local function register_signs()
  for severity, icon in pairs(DIAG_ICONS) do
    local name = "DiagnosticSign" .. severity
    vim.fn.sign_define(name, {
      text   = icon,
      texthl = name,
      numhl  = name .. "Nr",
      linehl = "",
    })
  end
end

---Apply LSP highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  register_signs()

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔴 DIAGNOSTIC SIGN COLUMN
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DiagnosticSignError",          { fg = p.red,    bold = true })
  hl(0, "DiagnosticSignWarn",           { fg = p.yellow, bold = true })
  hl(0, "DiagnosticSignInfo",           { fg = p.blue,   bold = true })
  hl(0, "DiagnosticSignHint",           { fg = p.teal,   bold = true })
  hl(0, "DiagnosticSignOk",             { fg = p.green,  bold = true })

  -- Number column variants
  hl(0, "DiagnosticSignErrorNr",        { fg = p.red,    bold = true })
  hl(0, "DiagnosticSignWarnNr",         { fg = p.yellow, bold = true })
  hl(0, "DiagnosticSignInfoNr",         { fg = p.blue,   bold = true })
  hl(0, "DiagnosticSignHintNr",         { fg = p.teal,   bold = true })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📝 DIAGNOSTIC TEXT (buffer inline)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DiagnosticError",              { fg = p.red                })
  hl(0, "DiagnosticWarn",               { fg = p.yellow             })
  hl(0, "DiagnosticInfo",               { fg = p.blue               })
  hl(0, "DiagnosticHint",               { fg = p.teal               })
  hl(0, "DiagnosticOk",                 { fg = p.green              })
  hl(0, "DiagnosticDeprecated",         {
    strikethrough = true,
    fg            = p.overlay0,
  })
  hl(0, "DiagnosticUnnecessary",        { fg = p.overlay0           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 〰️  DIAGNOSTIC UNDERLINES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DiagnosticUnderlineError",     { undercurl = true, sp = p.red    })
  hl(0, "DiagnosticUnderlineWarn",      { undercurl = true, sp = p.yellow })
  hl(0, "DiagnosticUnderlineInfo",      { undercurl = true, sp = p.blue   })
  hl(0, "DiagnosticUnderlineHint",      { undercurl = true, sp = p.teal   })
  hl(0, "DiagnosticUnderlineOk",        { undercurl = true, sp = p.green  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔮 VIRTUAL TEXT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DiagnosticVirtualTextError",   {
    italic = true,
    fg     = p.red,
    bg     = p.error_bg or p.surface0,
  })
  hl(0, "DiagnosticVirtualTextWarn",    {
    italic = true,
    fg     = p.yellow,
    bg     = p.warning_bg or p.surface0,
  })
  hl(0, "DiagnosticVirtualTextInfo",    {
    italic = true,
    fg     = p.blue,
    bg     = p.info_bg or p.surface0,
  })
  hl(0, "DiagnosticVirtualTextHint",    {
    italic = true,
    fg     = p.teal,
    bg     = p.hint_bg or p.surface0,
  })
  hl(0, "DiagnosticVirtualTextOk",      {
    italic = true,
    fg     = p.green,
    bg     = p.surface0,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 💬 FLOATING DIAGNOSTICS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DiagnosticFloatingError",      { link = "DiagnosticError" })
  hl(0, "DiagnosticFloatingWarn",       { link = "DiagnosticWarn"  })
  hl(0, "DiagnosticFloatingInfo",       { link = "DiagnosticInfo"  })
  hl(0, "DiagnosticFloatingHint",       { link = "DiagnosticHint"  })
  hl(0, "DiagnosticFloatingOk",         { link = "DiagnosticOk"    })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔍 LSP REFERENCES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "LspReferenceText",             {
    bg   = p.surface1,
    bold = false,
  })
  hl(0, "LspReferenceRead",             {
    bg   = p.diff_add or p.surface1,
  })
  hl(0, "LspReferenceWrite",            {
    bg   = p.diff_delete or p.surface1,
    bold = true,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 💡 INLAY HINTS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "LspInlayHint",                 {
    italic = true,
    fg     = p.overlay0,
    bg     = p.surface0,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔭 CODE LENS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "LspCodeLens",                  { fg = p.overlay0, italic = true })
  hl(0, "LspCodeLensSeparator",         { fg = p.surface2               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ✍️  SIGNATURE HELP
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "LspSignatureActiveParameter",  {
    bold      = true,
    underline = true,
    sp        = p.blue,
    fg        = p.text,
    bg        = p.surface0,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🏷️  SEMANTIC TOKENS — universal
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  local lsp_hl = {
    -- Types
    { "@lsp.type.class",          { fg = p.yellow                          } },
    { "@lsp.type.comment",        { fg = p.overlay0,   italic = true        } },
    { "@lsp.type.decorator",      { fg = p.mauve,      italic = true        } },
    { "@lsp.type.enum",           { fg = p.yellow                          } },
    { "@lsp.type.enumMember",     { fg = p.teal                            } },
    { "@lsp.type.event",          { fg = p.red                             } },
    { "@lsp.type.function",       { fg = p.blue                            } },
    { "@lsp.type.interface",      { fg = p.teal,       italic = true        } },
    { "@lsp.type.keyword",        { fg = p.mauve,      bold = true          } },
    { "@lsp.type.macro",          { fg = p.mauve,      bold = true          } },
    { "@lsp.type.method",         { fg = p.blue                            } },
    { "@lsp.type.modifier",       { fg = p.yellow                          } },
    { "@lsp.type.namespace",      { fg = p.blue,       italic = true        } },
    { "@lsp.type.number",         { fg = p.peach                           } },
    { "@lsp.type.operator",       { fg = p.sky                             } },
    { "@lsp.type.parameter",      { fg = p.text,       italic = true        } },
    { "@lsp.type.property",       { fg = p.text                            } },
    { "@lsp.type.struct",         { fg = p.yellow                          } },
    { "@lsp.type.type",           { fg = p.yellow                          } },
    { "@lsp.type.typeParameter",  { fg = p.teal,       italic = true        } },
    { "@lsp.type.variable",       { fg = p.text                            } },
    { "@lsp.type.builtinType",    { fg = p.sky                             } },
    { "@lsp.type.label",          { fg = p.blue                            } },
    { "@lsp.type.unresolvedReference", { fg = p.red, underline = true       } },
    { "@lsp.type.string",         { fg = p.green                           } },
    { "@lsp.type.boolean",        { fg = p.peach,      bold = true          } },
    { "@lsp.type.genericType",    { fg = p.teal,       italic = true        } },
    { "@lsp.type.selfParameter",  { fg = p.yellow,     bold = true          } },
    { "@lsp.type.clsParameter",   { fg = p.peach,      bold = true          } },
    { "@lsp.type.concept",        { fg = p.teal,       italic = true, bold = true } },
    { "@lsp.type.typeAlias",      { fg = p.yellow,     italic = true        } },
    { "@lsp.type.attributeBracket",{ fg = p.overlay0                       } },
    { "@lsp.type.deriveHelper",   { fg = p.mauve,      italic = true        } },
    { "@lsp.type.formatSpecifier",{ fg = p.sky                             } },
    { "@lsp.type.escapeSequence", { fg = p.pink,       bold = true          } },
    { "@lsp.type.errorTag",       { fg = p.red,        bold = true          } },
    { "@lsp.type.atom",           { fg = p.green                           } },
    { "@lsp.type.module",         { fg = p.blue,       italic = true        } },
    { "@lsp.type.path",           { fg = p.green,      italic = true        } },
    { "@lsp.type.bitString",      { fg = p.peach                           } },

    -- Modifiers
    { "@lsp.mod.deprecated",      { strikethrough = true                   } },
    { "@lsp.mod.readonly",        { italic = true                          } },
    { "@lsp.mod.static",          { italic = true                          } },
    { "@lsp.mod.abstract",        { italic = true                          } },
    { "@lsp.mod.async",           { italic = true                          } },
    { "@lsp.mod.defaultLibrary",  { bold = true                            } },
    { "@lsp.mod.global",          { bold = true                            } },
    { "@lsp.mod.mutable",         { underline = true                       } },
    { "@lsp.mod.consuming",       { bold = true,       italic = true        } },
    { "@lsp.mod.unsafe",          { fg = p.yellow,     bold = true          } },
    { "@lsp.mod.virtual",         { italic = true                          } },
    { "@lsp.mod.final",           { bold = true                            } },
    { "@lsp.mod.public",          {}                                          },
    { "@lsp.mod.private",         { italic = true                          } },
    { "@lsp.mod.protected",       { italic = true                          } },
  }

  for _, entry in ipairs(lsp_hl) do
    hl(0, entry[1], entry[2])
  end
end

return M