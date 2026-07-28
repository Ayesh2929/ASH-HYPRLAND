-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🌳 TREESITTER INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                  ║
-- ║   Full @capture group mapping · semantic token overrides · 40+ languages       ║
-- ║   Markup · injections · special cases · palette-aware dynamic colours          ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

---Apply Treesitter highlight groups using the given palette
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📝 COMMENTS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@comment",                    { fg = p.overlay0,  italic = true               })
  hl(0, "@comment.documentation",      { fg = p.overlay1,  italic = true               })
  hl(0, "@comment.error",              { fg = p.red,       bold = true,   italic = true })
  hl(0, "@comment.warning",            { fg = p.yellow,    bold = true,   italic = true })
  hl(0, "@comment.todo",               { fg = p.blue,      bold = true,   italic = true })
  hl(0, "@comment.note",               { fg = p.teal,      bold = true,   italic = true })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔤 LITERALS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@string",                     { fg = p.green                                  })
  hl(0, "@string.documentation",       { fg = p.teal,      italic = true               })
  hl(0, "@string.regexp",              { fg = p.pink,      bold = false                })
  hl(0, "@string.escape",              { fg = p.mauve,     bold = true                 })
  hl(0, "@string.special",             { fg = p.pink                                   })
  hl(0, "@string.special.symbol",      { fg = p.green                                  })
  hl(0, "@string.special.path",        { fg = p.green,     italic = true               })
  hl(0, "@string.special.url",         { fg = p.blue,      underline = true            })
  hl(0, "@character",                  { fg = p.teal                                   })
  hl(0, "@character.special",          { fg = p.pink,      bold = true                 })
  hl(0, "@number",                     { fg = p.peach                                  })
  hl(0, "@number.float",               { fg = p.peach                                  })
  hl(0, "@boolean",                    { fg = p.peach,     bold = true                 })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔣 PUNCTUATION
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@punctuation.bracket",        { fg = p.overlay2                               })
  hl(0, "@punctuation.delimiter",      { fg = p.overlay1                               })
  hl(0, "@punctuation.special",        { fg = p.sky,       bold = true                 })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔑 KEYWORDS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@keyword",                    { fg = p.mauve,     bold = true                 })
  hl(0, "@keyword.coroutine",          { fg = p.mauve,     bold = true,  italic = true })
  hl(0, "@keyword.debug",              { fg = p.red,       bold = true                 })
  hl(0, "@keyword.directive",          { fg = p.mauve                                  })
  hl(0, "@keyword.directive.define",   { fg = p.mauve,     bold = true                 })
  hl(0, "@keyword.exception",          { fg = p.red,       bold = true                 })
  hl(0, "@keyword.function",           { fg = p.mauve,     bold = true                 })
  hl(0, "@keyword.import",             { fg = p.mauve                                  })
  hl(0, "@keyword.modifier",           { fg = p.yellow                                 })
  hl(0, "@keyword.operator",           { fg = p.sky,       bold = true                 })
  hl(0, "@keyword.repeat",             { fg = p.mauve,     bold = true                 })
  hl(0, "@keyword.return",             { fg = p.mauve,     bold = true,  italic = true })
  hl(0, "@keyword.storage",            { fg = p.yellow                                 })
  hl(0, "@keyword.type",               { fg = p.yellow,    bold = true                 })
  hl(0, "@keyword.conditional",        { fg = p.mauve,     bold = true                 })
  hl(0, "@keyword.conditional.ternary",{ fg = p.sky,       bold = true                 })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ⚙️  FUNCTIONS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@function",                   { fg = p.blue                                   })
  hl(0, "@function.builtin",           { fg = p.blue,      bold = true                 })
  hl(0, "@function.call",              { fg = p.blue                                   })
  hl(0, "@function.macro",             { fg = p.mauve,     bold = true                 })
  hl(0, "@function.method",            { fg = p.blue                                   })
  hl(0, "@function.method.call",       { fg = p.sapphire                               })
  hl(0, "@constructor",                { fg = p.sapphire                               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 VARIABLES & PARAMETERS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@variable",                   { fg = p.text                                   })
  hl(0, "@variable.builtin",           { fg = p.red,       bold = true                 })
  hl(0, "@variable.member",            { fg = p.text                                   })
  hl(0, "@variable.parameter",         { fg = p.text,      italic = true               })
  hl(0, "@variable.parameter.builtin", { fg = p.red,       italic = true               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🏷️  TYPES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@type",                       { fg = p.yellow                                 })
  hl(0, "@type.builtin",               { fg = p.yellow,    bold = true                 })
  hl(0, "@type.definition",            { fg = p.yellow                                 })
  hl(0, "@type.qualifier",             { fg = p.mauve                                  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔢 CONSTANTS & ATTRIBUTES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@constant",                   { fg = p.peach                                  })
  hl(0, "@constant.builtin",           { fg = p.peach,     bold = true                 })
  hl(0, "@constant.macro",             { fg = p.mauve,     bold = true                 })
  hl(0, "@attribute",                  { fg = p.yellow                                 })
  hl(0, "@attribute.builtin",          { fg = p.yellow,    bold = true                 })
  hl(0, "@property",                   { fg = p.text                                   })
  hl(0, "@field",                      { fg = p.text                                   })
  hl(0, "@label",                      { fg = p.blue                                   })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🗂️  MODULES & NAMESPACES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@module",                     { fg = p.blue,      italic = true               })
  hl(0, "@module.builtin",             { fg = p.red,       bold = true                 })
  hl(0, "@namespace",                  { fg = p.blue,      italic = true               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔀 OPERATORS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@operator",                   { fg = p.sky                                    })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📖 MARKUP (Markdown / RST / Org etc.)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@markup.heading",             { fg = p.blue,      bold = true                 })
  hl(0, "@markup.heading.1",           { fg = p.blue,      bold = true                 })
  hl(0, "@markup.heading.2",           { fg = p.green,     bold = true                 })
  hl(0, "@markup.heading.3",           { fg = p.yellow,    bold = true                 })
  hl(0, "@markup.heading.4",           { fg = p.red,       bold = true                 })
  hl(0, "@markup.heading.5",           { fg = p.mauve,     bold = true                 })
  hl(0, "@markup.heading.6",           { fg = p.teal,      bold = true                 })
  hl(0, "@markup.heading.1.marker",    { fg = p.blue,      bold = true                 })
  hl(0, "@markup.heading.2.marker",    { fg = p.green,     bold = true                 })
  hl(0, "@markup.heading.3.marker",    { fg = p.yellow,    bold = true                 })
  hl(0, "@markup.heading.4.marker",    { fg = p.red,       bold = true                 })
  hl(0, "@markup.heading.5.marker",    { fg = p.mauve,     bold = true                 })
  hl(0, "@markup.heading.6.marker",    { fg = p.teal,      bold = true                 })
  hl(0, "@markup.bold",                { bold = true                                   })
  hl(0, "@markup.italic",              { italic = true                                 })
  hl(0, "@markup.underline",           { underline = true                              })
  hl(0, "@markup.strikethrough",       { strikethrough = true                          })
  hl(0, "@markup.raw",                 { fg = p.teal                                   })
  hl(0, "@markup.raw.block",           { fg = p.teal,      bg = p.surface0             })
  hl(0, "@markup.raw.markdown_inline", { fg = p.teal,      bg = p.surface0             })
  hl(0, "@markup.link",                { fg = p.blue,      underline = true            })
  hl(0, "@markup.link.label",          { fg = p.blue,      bold = true                 })
  hl(0, "@markup.link.url",            { fg = p.blue,      underline = true            })
  hl(0, "@markup.list",                { fg = p.blue,      bold = true                 })
  hl(0, "@markup.list.checked",        { fg = p.green,     bold = true                 })
  hl(0, "@markup.list.unchecked",      { fg = p.overlay0                               })
  hl(0, "@markup.quote",               { fg = p.overlay0,  italic = true               })
  hl(0, "@markup.math",                { fg = p.green                                  })
  hl(0, "@markup.environment",         { fg = p.mauve                                  })
  hl(0, "@markup.environment.name",    { fg = p.blue                                   })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🏷️  HTML / JSX TAGS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@tag",                        { fg = p.blue,      bold = true                 })
  hl(0, "@tag.attribute",              { fg = p.text,      italic = true               })
  hl(0, "@tag.delimiter",              { fg = p.overlay1                               })
  hl(0, "@tag.builtin",                { fg = p.blue,      bold = true                 })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ⚠️  SPECIAL / DIAGNOSTIC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "@error",                      { fg = p.red,       bold = true                 })
  hl(0, "@warning",                    { fg = p.yellow,    bold = true                 })
  hl(0, "@none",                       { fg = p.text                                   })
  hl(0, "@conceal",                    { fg = p.overlay0                               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌐 LANGUAGE-SPECIFIC OVERRIDES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  -- ── Rust ──────────────────────────────────────────────────────────────────
  hl(0, "@lsp.type.lifetime.rust",           { fg = p.blue,  italic = true             })
  hl(0, "@lsp.type.selfKeyword.rust",        { fg = p.yellow, bold = true              })
  hl(0, "@lsp.typemod.variable.mutable.rust",{ underline = true                        })
  hl(0, "@lsp.typemod.variable.unsafe.rust", { fg = p.yellow, bold = true              })
  hl(0, "@lsp.typemod.function.unsafe.rust", { fg = p.yellow, bold = true              })
  hl(0, "@lsp.type.builtinType.rust",        { fg = p.sky                              })
  hl(0, "@lsp.type.enumMember.rust",         { fg = p.sky                              })
  hl(0, "@lsp.type.constParameter.rust",     { fg = p.peach, bold = true              })

  -- ── Python ────────────────────────────────────────────────────────────────
  hl(0, "@attribute.python",                 { fg = p.mauve, italic = true             })
  hl(0, "@lsp.type.selfParameter.python",    { fg = p.yellow, bold = true              })
  hl(0, "@lsp.type.clsParameter.python",     { fg = p.peach,  bold = true              })

  -- ── Lua ──────────────────────────────────────────────────────────────────
  hl(0, "@constructor.lua",                  { fg = p.sapphire                         })
  hl(0, "@lsp.type.self.lua",                { fg = p.yellow, bold = true              })

  -- ── TypeScript / JavaScript ───────────────────────────────────────────────
  hl(0, "@lsp.typemod.function.async.typescript", { fg = p.blue, italic = true        })
  hl(0, "@lsp.typemod.function.async.javascript", { fg = p.blue, italic = true        })
  hl(0, "@lsp.typemod.variable.readonly.typescript", { italic = true                  })
  hl(0, "@lsp.type.decorator.typescript",    { fg = p.mauve, italic = true             })
  hl(0, "@lsp.type.decorator.javascript",    { fg = p.mauve, italic = true             })

  -- ── Go ────────────────────────────────────────────────────────────────────
  hl(0, "@lsp.typemod.function.async.go",    { fg = p.blue, italic = true              })
  hl(0, "@type.builtin.go",                  { fg = p.sky                              })

  -- ── C/C++ ─────────────────────────────────────────────────────────────────
  hl(0, "@lsp.type.macro.cpp",               { fg = p.mauve, bold = true              })
  hl(0, "@lsp.type.namespace.cpp",           { fg = p.blue,  italic = true             })
  hl(0, "@lsp.type.concept.cpp",             { fg = p.teal,  italic = true, bold = true })

  -- ── Haskell ───────────────────────────────────────────────────────────────
  hl(0, "@lsp.type.typeConstructor.haskell", { fg = p.yellow, bold = true             })
  hl(0, "@lsp.type.dataConstructor.haskell", { fg = p.sky                             })
  hl(0, "@lsp.type.typeVariable.haskell",    { fg = p.teal, italic = true             })

  -- ── Nix ───────────────────────────────────────────────────────────────────
  hl(0, "@string.special.path.nix",          { fg = p.green, italic = true            })
  hl(0, "@punctuation.special.nix",          { fg = p.mauve, bold = true              })

  -- ── Fish ──────────────────────────────────────────────────────────────────
  hl(0, "@function.call.fish",                { fg = p.blue                            })
  hl(0, "@variable.special.fish",             { fg = p.mauve                           })

  -- ── Hyprland ─────────────────────────────────────────────────────────────
  hl(0, "@keyword.hypr",                      { fg = p.blue, bold = true               })
  hl(0, "@property.hypr",                     { fg = p.text                            })
  hl(0, "@string.hypr",                       { fg = p.green                           })
  hl(0, "@number.hypr",                       { fg = p.peach                           })
  hl(0, "@boolean.hypr",                      { fg = p.peach, bold = true              })
  hl(0, "@comment.hypr",                      { fg = p.overlay0, italic = true         })
  hl(0, "@type.hypr",                         { fg = p.yellow, bold = true             })
  hl(0, "@punctuation.special.hypr",          { fg = p.mauve, bold = true              })

  -- ── CSS / SCSS ────────────────────────────────────────────────────────────
  hl(0, "@property.css",                      { fg = p.blue                            })
  hl(0, "@string.plain.css",                  { fg = p.green                           })
  hl(0, "@number.css",                        { fg = p.peach                           })
  hl(0, "@type.css",                          { fg = p.mauve                           })
  hl(0, "@attribute.css",                     { fg = p.yellow                          })

  -- ── LaTeX ────────────────────────────────────────────────────────────────
  hl(0, "@function.latex",                    { fg = p.blue                            })
  hl(0, "@keyword.latex",                     { fg = p.mauve, bold = true              })
  hl(0, "@markup.math.latex",                 { fg = p.green                           })

  -- ── YAML ─────────────────────────────────────────────────────────────────
  hl(0, "@property.yaml",                     { fg = p.blue, bold = true               })
  hl(0, "@string.yaml",                       { fg = p.green                           })

  -- ── TOML ─────────────────────────────────────────────────────────────────
  hl(0, "@property.toml",                     { fg = p.blue, bold = true               })
  hl(0, "@type.toml",                         { fg = p.yellow, bold = true             })
  hl(0, "@type.array.toml",                   { fg = p.peach, bold = true              })

  -- ── SQL ──────────────────────────────────────────────────────────────────
  hl(0, "@keyword.sql",                       { fg = p.blue, bold = true               })
  hl(0, "@function.builtin.sql",              { fg = p.blue, bold = true               })
  hl(0, "@type.sql",                          { fg = p.yellow                          })

  -- ── Diff ─────────────────────────────────────────────────────────────────
  hl(0, "@text.diff.add",                     { link = "DiffAdd"                       })
  hl(0, "@text.diff.delete",                  { link = "DiffDelete"                    })
end

return M