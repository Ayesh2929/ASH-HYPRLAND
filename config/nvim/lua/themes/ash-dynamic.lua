-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔥 ASH-DYNAMIC — LIVE PALETTE INJECTION THEME v5.0 OMEGA                 ║
-- ║   Reads active ASH palette · injects into Neovim highlights at runtime        ║
-- ║   Treesitter · LSP · plugin overrides · gradient generation · auto-contrast   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 COLOUR MATH UTILITIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Parse "#rrggbb" → { r, g, b } (0–255)
local function hex_to_rgb(hex)
  if not hex or type(hex) ~= "string" then return { 128, 128, 128 } end
  hex = hex:gsub("^#", "")
  if #hex ~= 6 then return { 128, 128, 128 } end
  return {
    tonumber(hex:sub(1, 2), 16),
    tonumber(hex:sub(3, 4), 16),
    tonumber(hex:sub(5, 6), 16),
  }
end

-- { r, g, b } → "#rrggbb"
local function rgb_to_hex(r, g, b)
  return string.format("#%02x%02x%02x",
    math.max(0, math.min(255, math.floor(r + 0.5))),
    math.max(0, math.min(255, math.floor(g + 0.5))),
    math.max(0, math.min(255, math.floor(b + 0.5)))
  )
end

-- Mix two hex colours by ratio (0=first, 1=second)
local function mix(hex1, hex2, t)
  local c1 = hex_to_rgb(hex1)
  local c2 = hex_to_rgb(hex2)
  t = math.max(0, math.min(1, t))
  return rgb_to_hex(
    c1[1] + (c2[1] - c1[1]) * t,
    c1[2] + (c2[2] - c1[2]) * t,
    c1[3] + (c2[3] - c1[3]) * t
  )
end

-- Darken/lighten by percentage (-1.0 to 1.0)
local function shade(hex, amount)
  local c = hex_to_rgb(hex)
  local factor = 1 + amount
  return rgb_to_hex(c[1] * factor, c[2] * factor, c[3] * factor)
end

-- WCAG luminance for contrast check
local function luminance(hex)
  local c = hex_to_rgb(hex)
  local rgb = {}
  for i, v in ipairs(c) do
    v = v / 255
    rgb[i] = v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
  end
  return 0.2126 * rgb[1] + 0.7152 * rgb[2] + 0.0722 * rgb[3]
end

-- Contrast ratio between two colours (WCAG)
local function contrast(hex1, hex2)
  local l1 = luminance(hex1)
  local l2 = luminance(hex2)
  local lighter = math.max(l1, l2)
  local darker  = math.min(l1, l2)
  return (lighter + 0.05) / (darker + 0.05)
end

-- Ensure readable text on background (min 4.5:1 for WCAG AA)
local function ensure_contrast(fg, bg, min_ratio)
  min_ratio = min_ratio or 4.5
  local ratio = contrast(fg, bg)
  if ratio >= min_ratio then return fg end
  -- Try lightening or darkening fg
  local is_dark_bg = luminance(bg) < 0.3
  for step = 0.05, 0.5, 0.05 do
    local adjusted = is_dark_bg and shade(fg, step) or shade(fg, -step)
    if contrast(adjusted, bg) >= min_ratio then
      return adjusted
    end
  end
  return is_dark_bg and "#ffffff" or "#000000"
end

-- Generate subtle background tint
local function tinted_bg(colour, base, amount)
  return mix(base, colour, amount or 0.08)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗂️  DEFAULT PALETTE — Catppuccin Mocha baseline
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local DEFAULT_PALETTE = {
  -- ── Bases ─────────────────────────────────────────────────────────────────
  base       = "#1e1e2e",
  mantle     = "#181825",
  crust      = "#11111b",

  -- ── Surfaces ──────────────────────────────────────────────────────────────
  surface0   = "#313244",
  surface1   = "#45475a",
  surface2   = "#585b70",

  -- ── Overlays ──────────────────────────────────────────────────────────────
  overlay0   = "#6c7086",
  overlay1   = "#7f849c",
  overlay2   = "#9399b2",

  -- ── Text ──────────────────────────────────────────────────────────────────
  text       = "#cdd6f4",
  subtext0   = "#a6adc8",
  subtext1   = "#bac2de",

  -- ── Accents ───────────────────────────────────────────────────────────────
  lavender   = "#b4befe",
  blue       = "#89b4fa",
  sapphire   = "#74c7ec",
  sky        = "#89dceb",
  teal       = "#94e2d5",
  green      = "#a6e3a1",
  yellow     = "#f9e2af",
  peach      = "#fab387",
  maroon     = "#eba0ac",
  red        = "#f38ba8",
  mauve      = "#cba6f7",
  pink       = "#f5c2e7",
  flamingo   = "#f2cdcd",
  rosewater  = "#f5e0dc",

  -- ── Aliases for cross-theme compatibility ─────────────────────────────────
  accent     = "#89b4fa",    -- primary accent
  error      = "#f38ba8",    -- error colour
  warning    = "#f9e2af",    -- warning colour
  info       = "#89b4fa",    -- info colour
  hint       = "#94e2d5",    -- hint colour
  orange     = "#fab387",    -- orange alias
  cyan       = "#94e2d5",    -- cyan alias
  purple     = "#cba6f7",    -- purple alias
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 PALETTE LOADER — read active ASH palette from CLI / file
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local _cached_palette = nil
local _cache_time     = 0
local CACHE_TTL       = 30  -- seconds

local function load_palette()
  local now = os.time()
  if _cached_palette and (now - _cache_time) < CACHE_TTL then
    return _cached_palette
  end

  local palette = vim.deepcopy(DEFAULT_PALETTE)

  -- ── Try ASH CLI ──────────────────────────────────────────────────────────
  if vim.fn.executable("ash") == 1 then
    local result = vim.fn.trim(
      vim.fn.system("ash theme colors --format=json 2>/dev/null")
    )
    if vim.v.shell_error == 0 and result ~= "" then
      local ok, data = pcall(vim.fn.json_decode, result)
      if ok and type(data) == "table" then
        palette = vim.tbl_extend("force", palette, data)
      end
    end
  end

  -- ── Try ASH palette file ──────────────────────────────────────────────────
  local palette_files = {
    vim.fn.expand("~/.config/ash/themes/dynamic/colors.json"),
    vim.fn.expand("~/.config/ash/current-palette.json"),
    vim.fn.stdpath("data") .. "/ash_palette.json",
  }

  for _, path in ipairs(palette_files) do
    if vim.fn.filereadable(path) == 1 then
      local f = io.open(path, "r")
      if f then
        local content = f:read("*a")
        f:close()
        local ok, data = pcall(vim.fn.json_decode, content)
        if ok and type(data) == "table" then
          palette = vim.tbl_extend("force", palette, data)
          break
        end
      end
    end
  end

  -- ── Compute derived colours ───────────────────────────────────────────────
  local b = palette.base or DEFAULT_PALETTE.base

  palette.none               = "NONE"
  palette.bg                 = b
  palette.fg                 = palette.text
  palette.selection          = tinted_bg(palette.blue, b, 0.15)
  palette.comment            = palette.overlay0
  palette.visual             = tinted_bg(palette.mauve, b, 0.12)
  palette.search             = tinted_bg(palette.yellow, b, 0.25)
  palette.match              = tinted_bg(palette.yellow, b, 0.20)
  palette.diff_add           = tinted_bg(palette.green, b, 0.15)
  palette.diff_delete        = tinted_bg(palette.red, b, 0.15)
  palette.diff_change        = tinted_bg(palette.yellow, b, 0.12)
  palette.diff_text          = tinted_bg(palette.yellow, b, 0.20)
  palette.error_bg           = tinted_bg(palette.red, b, 0.10)
  palette.warning_bg         = tinted_bg(palette.yellow, b, 0.10)
  palette.info_bg            = tinted_bg(palette.blue, b, 0.10)
  palette.hint_bg            = tinted_bg(palette.teal, b, 0.10)
  palette.cursorline         = shade(b, 0.12)
  palette.statusline         = shade(b, -0.05)
  palette.border             = palette.surface1
  palette.float_bg           = shade(b, 0.06)
  palette.indent_guide       = tinted_bg(palette.surface1, b, 0.4)

  -- Ensure accent text is readable
  palette.accent_fg = ensure_contrast(palette.blue, b)

  _cached_palette = palette
  _cache_time     = now

  return palette
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🖌️  HIGHLIGHT APPLICATION ENGINE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function apply_highlights(p)
  local hl = vim.api.nvim_set_hl

  -- ── Editor core ───────────────────────────────────────────────────────────
  hl(0, "Normal",            { fg = p.text,      bg = p.base      })
  hl(0, "NormalNC",          { fg = p.subtext0,  bg = p.base      })
  hl(0, "NormalFloat",       { fg = p.text,      bg = p.float_bg  })
  hl(0, "FloatBorder",       { fg = p.border,    bg = p.float_bg  })
  hl(0, "FloatTitle",        { fg = p.blue, bold = true           })
  hl(0, "FloatFooter",       { fg = p.overlay0                    })

  hl(0, "Cursor",            { reverse = true                     })
  hl(0, "CursorLine",        { bg = p.cursorline                  })
  hl(0, "CursorColumn",      { bg = p.cursorline                  })
  hl(0, "CursorLineNr",      { fg = p.yellow,    bold = true      })
  hl(0, "LineNr",            { fg = p.surface2                    })
  hl(0, "LineNrAbove",       { fg = p.surface1                    })
  hl(0, "LineNrBelow",       { fg = p.surface1                    })

  hl(0, "SignColumn",        { fg = p.surface2,  bg = p.base      })
  hl(0, "FoldColumn",        { fg = p.overlay0,  bg = p.base      })
  hl(0, "Folded",            { fg = p.overlay1,  bg = p.surface0, italic = true })

  hl(0, "ColorColumn",       { bg = p.surface0                    })
  hl(0, "Conceal",           { fg = p.overlay0                    })

  hl(0, "VertSplit",         { fg = p.surface1                    })
  hl(0, "WinSeparator",      { fg = p.surface1                    })
  hl(0, "EndOfBuffer",       { fg = p.surface0                    })
  hl(0, "NonText",           { fg = p.surface1                    })
  hl(0, "Whitespace",        { fg = p.surface1                    })
  hl(0, "SpecialKey",        { fg = p.surface2                    })

  -- ── Selection ─────────────────────────────────────────────────────────────
  hl(0, "Visual",            { bg = p.visual                      })
  hl(0, "VisualNOS",         { bg = p.visual,    underline = true  })

  -- ── Search ────────────────────────────────────────────────────────────────
  hl(0, "Search",            { fg = p.base, bg = p.yellow         })
  hl(0, "IncSearch",         { fg = p.base, bg = p.orange         })
  hl(0, "CurSearch",         { fg = p.base, bg = p.red            })
  hl(0, "Substitute",        { fg = p.base, bg = p.green          })

  -- ── Messages ──────────────────────────────────────────────────────────────
  hl(0, "MsgArea",           { fg = p.text                        })
  hl(0, "MsgSeparator",      { fg = p.surface1                    })
  hl(0, "MoreMsg",           { fg = p.blue,      bold = true      })
  hl(0, "ErrorMsg",          { fg = p.red,       bold = true      })
  hl(0, "WarningMsg",        { fg = p.yellow,    bold = true      })
  hl(0, "Question",          { fg = p.blue                        })

  -- ── Statusline ────────────────────────────────────────────────────────────
  hl(0, "StatusLine",        { fg = p.text,      bg = p.statusline  })
  hl(0, "StatusLineNC",      { fg = p.subtext0,  bg = p.statusline  })
  hl(0, "WinBar",            { fg = p.text,      bg = p.base        })
  hl(0, "WinBarNC",          { fg = p.subtext0,  bg = p.base        })

  -- ── Tabline ────────────────────────────────────────────────────────────────
  hl(0, "TabLine",           { fg = p.subtext0,  bg = p.statusline  })
  hl(0, "TabLineSel",        { fg = p.text,      bg = p.blue, bold = true })
  hl(0, "TabLineFill",       { bg = p.statusline                    })

  -- ── Popup menu (completion) ────────────────────────────────────────────────
  hl(0, "Pmenu",             { fg = p.text,      bg = p.float_bg  })
  hl(0, "PmenuSel",          { fg = p.base,      bg = p.blue      })
  hl(0, "PmenuSbar",         { bg = p.surface1                    })
  hl(0, "PmenuThumb",        { bg = p.overlay0                    })
  hl(0, "PmenuKind",         { fg = p.teal,      bg = p.float_bg  })
  hl(0, "PmenuKindSel",      { fg = p.base,      bg = p.blue      })
  hl(0, "PmenuExtra",        { fg = p.overlay0,  bg = p.float_bg  })
  hl(0, "PmenuExtraSel",     { fg = p.base,      bg = p.blue      })

  -- ── Diff ─────────────────────────────────────────────────────────────────
  hl(0, "DiffAdd",           { bg = p.diff_add                    })
  hl(0, "DiffChange",        { bg = p.diff_change                 })
  hl(0, "DiffDelete",        { bg = p.diff_delete                 })
  hl(0, "DiffText",          { bg = p.diff_text                   })
  hl(0, "Added",             { fg = p.green                       })
  hl(0, "Changed",           { fg = p.yellow                      })
  hl(0, "Removed",           { fg = p.red                         })

  -- ── Spell ─────────────────────────────────────────────────────────────────
  hl(0, "SpellBad",          { undercurl = true, sp = p.red       })
  hl(0, "SpellCap",          { undercurl = true, sp = p.yellow    })
  hl(0, "SpellRare",         { undercurl = true, sp = p.teal      })
  hl(0, "SpellLocal",        { undercurl = true, sp = p.blue      })

  -- ── Syntax: base groups ────────────────────────────────────────────────────
  hl(0, "Comment",           { fg = p.overlay0,  italic = true    })
  hl(0, "Constant",          { fg = p.peach                       })
  hl(0, "String",            { fg = p.green                       })
  hl(0, "Character",         { fg = p.teal                        })
  hl(0, "Number",            { fg = p.peach                       })
  hl(0, "Float",             { fg = p.peach                       })
  hl(0, "Boolean",           { fg = p.peach,     bold = true      })

  hl(0, "Identifier",        { fg = p.text                        })
  hl(0, "Function",          { fg = p.blue                        })

  hl(0, "Statement",         { fg = p.mauve                       })
  hl(0, "Conditional",       { fg = p.mauve,     bold = true      })
  hl(0, "Repeat",            { fg = p.mauve,     bold = true      })
  hl(0, "Label",             { fg = p.blue                        })
  hl(0, "Operator",          { fg = p.sky                         })
  hl(0, "Keyword",           { fg = p.mauve,     bold = true      })
  hl(0, "Exception",         { fg = p.red,       bold = true      })

  hl(0, "PreProc",           { fg = p.pink                        })
  hl(0, "Include",           { fg = p.mauve                       })
  hl(0, "Define",            { fg = p.mauve                       })
  hl(0, "Macro",             { fg = p.mauve                       })
  hl(0, "PreCondit",         { fg = p.mauve                       })

  hl(0, "Type",              { fg = p.yellow                      })
  hl(0, "StorageClass",      { fg = p.yellow                      })
  hl(0, "Structure",         { fg = p.yellow                      })
  hl(0, "Typedef",           { fg = p.yellow                      })

  hl(0, "Special",           { fg = p.pink                        })
  hl(0, "SpecialChar",       { fg = p.pink                        })
  hl(0, "Tag",               { fg = p.blue                        })
  hl(0, "Delimiter",         { fg = p.overlay2                    })
  hl(0, "SpecialComment",    { fg = p.overlay1,  italic = true    })
  hl(0, "Debug",             { fg = p.peach                       })

  hl(0, "Underlined",        { underline = true                   })
  hl(0, "Bold",              { bold = true                        })
  hl(0, "Italic",            { italic = true                      })
  hl(0, "Strikethrough",     { strikethrough = true               })
  hl(0, "Error",             { fg = p.red,       bold = true      })
  hl(0, "Todo",              { fg = p.base, bg = p.yellow, bold = true })
  hl(0, "Ignore",            { fg = p.overlay0                    })

  -- ── Treesitter ─────────────────────────────────────────────────────────────
  hl(0, "@comment",                    { link = "Comment"   })
  hl(0, "@comment.documentation",      { fg = p.overlay1,   italic = true })
  hl(0, "@error",                      { link = "Error"     })
  hl(0, "@none",                       { fg = p.text        })
  hl(0, "@punctuation.bracket",        { fg = p.overlay2    })
  hl(0, "@punctuation.delimiter",      { fg = p.overlay1    })
  hl(0, "@punctuation.special",        { fg = p.sky         })
  hl(0, "@constant",                   { fg = p.peach       })
  hl(0, "@constant.builtin",           { fg = p.peach, bold = true })
  hl(0, "@constant.macro",             { fg = p.mauve       })
  hl(0, "@define",                     { fg = p.mauve       })
  hl(0, "@macro",                      { fg = p.mauve       })
  hl(0, "@string",                     { fg = p.green       })
  hl(0, "@string.documentation",       { fg = p.teal        })
  hl(0, "@string.regexp",              { fg = p.pink        })
  hl(0, "@string.escape",              { fg = p.pink,  bold = true })
  hl(0, "@string.special",             { fg = p.pink        })
  hl(0, "@character",                  { fg = p.teal        })
  hl(0, "@character.special",          { fg = p.pink        })
  hl(0, "@number",                     { fg = p.peach       })
  hl(0, "@number.float",               { fg = p.peach       })
  hl(0, "@boolean",                    { fg = p.peach, bold = true })
  hl(0, "@function",                   { fg = p.blue        })
  hl(0, "@function.builtin",           { fg = p.blue, bold = true })
  hl(0, "@function.call",              { fg = p.blue        })
  hl(0, "@function.macro",             { fg = p.mauve       })
  hl(0, "@function.method",            { fg = p.blue        })
  hl(0, "@function.method.call",       { fg = p.blue        })
  hl(0, "@constructor",                { fg = p.sapphire    })
  hl(0, "@parameter",                  { fg = p.text, italic = true })
  hl(0, "@keyword",                    { fg = p.mauve, bold = true })
  hl(0, "@keyword.coroutine",          { fg = p.mauve, italic = true })
  hl(0, "@keyword.debug",              { fg = p.red         })
  hl(0, "@keyword.directive",          { fg = p.mauve       })
  hl(0, "@keyword.exception",          { fg = p.red, bold = true })
  hl(0, "@keyword.function",           { fg = p.mauve, bold = true })
  hl(0, "@keyword.import",             { fg = p.mauve       })
  hl(0, "@keyword.operator",           { fg = p.sky, bold = true })
  hl(0, "@keyword.repeat",             { fg = p.mauve, bold = true })
  hl(0, "@keyword.return",             { fg = p.mauve, bold = true })
  hl(0, "@keyword.storage",            { fg = p.yellow      })
  hl(0, "@keyword.type",               { fg = p.yellow      })
  hl(0, "@conditional",                { fg = p.mauve, bold = true })
  hl(0, "@repeat",                     { fg = p.mauve, bold = true })
  hl(0, "@return",                     { fg = p.mauve       })
  hl(0, "@operator",                   { fg = p.sky         })
  hl(0, "@attribute",                  { fg = p.yellow      })
  hl(0, "@field",                      { fg = p.text        })
  hl(0, "@property",                   { fg = p.text        })
  hl(0, "@variable",                   { fg = p.text        })
  hl(0, "@variable.builtin",           { fg = p.red, bold = true })
  hl(0, "@variable.member",            { fg = p.text        })
  hl(0, "@variable.parameter",         { fg = p.text, italic = true })
  hl(0, "@variable.parameter.builtin", { fg = p.red, italic = true })
  hl(0, "@type",                       { fg = p.yellow      })
  hl(0, "@type.builtin",               { fg = p.yellow, bold = true })
  hl(0, "@type.definition",            { fg = p.yellow      })
  hl(0, "@type.qualifier",             { fg = p.mauve       })
  hl(0, "@namespace",                  { fg = p.blue, italic = true })
  hl(0, "@module",                     { fg = p.blue, italic = true })
  hl(0, "@module.builtin",             { fg = p.red, bold = true })
  hl(0, "@tag",                        { fg = p.blue        })
  hl(0, "@tag.attribute",              { fg = p.text        })
  hl(0, "@tag.delimiter",              { fg = p.overlay1    })
  hl(0, "@label",                      { fg = p.blue        })
  hl(0, "@exception",                  { fg = p.red, bold = true })
  hl(0, "@include",                    { fg = p.mauve       })
  hl(0, "@preproc",                    { fg = p.mauve       })
  hl(0, "@storageclass",               { fg = p.yellow      })

  -- ── Markup ────────────────────────────────────────────────────────────────
  hl(0, "@markup.heading",             { fg = p.blue, bold = true })
  hl(0, "@markup.heading.1",           { fg = p.blue, bold = true })
  hl(0, "@markup.heading.2",           { fg = p.green, bold = true })
  hl(0, "@markup.heading.3",           { fg = p.yellow, bold = true })
  hl(0, "@markup.heading.4",           { fg = p.red, bold = true })
  hl(0, "@markup.heading.5",           { fg = p.mauve, bold = true })
  hl(0, "@markup.heading.6",           { fg = p.teal, bold = true })
  hl(0, "@markup.bold",                { bold = true                })
  hl(0, "@markup.italic",              { italic = true              })
  hl(0, "@markup.underline",           { underline = true           })
  hl(0, "@markup.strikethrough",       { strikethrough = true       })
  hl(0, "@markup.raw",                 { fg = p.teal                })
  hl(0, "@markup.raw.markdown_inline", { fg = p.teal, bg = p.surface0 })
  hl(0, "@markup.link",                { fg = p.blue, underline = true })
  hl(0, "@markup.link.label",          { fg = p.blue                })
  hl(0, "@markup.link.url",            { fg = p.blue, underline = true })
  hl(0, "@markup.list",                { fg = p.blue                })
  hl(0, "@markup.list.checked",        { fg = p.green               })
  hl(0, "@markup.list.unchecked",      { fg = p.overlay0            })
  hl(0, "@markup.quote",               { fg = p.overlay0, italic = true })
  hl(0, "@markup.math",                { fg = p.green               })

  -- ── LSP semantic tokens ────────────────────────────────────────────────────
  hl(0, "@lsp.type.class",             { fg = p.yellow              })
  hl(0, "@lsp.type.comment",           { fg = p.overlay0, italic = true })
  hl(0, "@lsp.type.decorator",         { fg = p.peach               })
  hl(0, "@lsp.type.enum",              { fg = p.yellow              })
  hl(0, "@lsp.type.enumMember",        { fg = p.teal                })
  hl(0, "@lsp.type.event",             { fg = p.red                 })
  hl(0, "@lsp.type.function",          { fg = p.blue                })
  hl(0, "@lsp.type.interface",         { fg = p.teal, italic = true })
  hl(0, "@lsp.type.keyword",           { fg = p.mauve, bold = true  })
  hl(0, "@lsp.type.macro",             { fg = p.mauve               })
  hl(0, "@lsp.type.method",            { fg = p.blue                })
  hl(0, "@lsp.type.modifier",          { fg = p.yellow              })
  hl(0, "@lsp.type.namespace",         { fg = p.blue, italic = true })
  hl(0, "@lsp.type.number",            { fg = p.peach               })
  hl(0, "@lsp.type.operator",          { fg = p.sky                 })
  hl(0, "@lsp.type.parameter",         { fg = p.text, italic = true })
  hl(0, "@lsp.type.property",          { fg = p.text                })
  hl(0, "@lsp.type.struct",            { fg = p.yellow              })
  hl(0, "@lsp.type.type",              { fg = p.yellow              })
  hl(0, "@lsp.type.typeParameter",     { fg = p.teal, italic = true })
  hl(0, "@lsp.type.variable",          { fg = p.text                })
  hl(0, "@lsp.mod.deprecated",         { strikethrough = true       })
  hl(0, "@lsp.mod.readonly",           { italic = true              })
  hl(0, "@lsp.mod.static",             { italic = true              })
  hl(0, "@lsp.mod.abstract",           { italic = true              })
  hl(0, "@lsp.mod.async",              { italic = true              })

  -- ── Diagnostics ────────────────────────────────────────────────────────────
  hl(0, "DiagnosticError",             { fg = p.red                 })
  hl(0, "DiagnosticWarn",              { fg = p.yellow              })
  hl(0, "DiagnosticInfo",              { fg = p.blue                })
  hl(0, "DiagnosticHint",              { fg = p.teal                })
  hl(0, "DiagnosticOk",               { fg = p.green               })
  hl(0, "DiagnosticUnderlineError",    { undercurl = true, sp = p.red    })
  hl(0, "DiagnosticUnderlineWarn",     { undercurl = true, sp = p.yellow })
  hl(0, "DiagnosticUnderlineInfo",     { undercurl = true, sp = p.blue   })
  hl(0, "DiagnosticUnderlineHint",     { undercurl = true, sp = p.teal   })
  hl(0, "DiagnosticVirtualTextError",  { fg = p.red,    bg = p.error_bg, italic = true })
  hl(0, "DiagnosticVirtualTextWarn",   { fg = p.yellow, bg = p.warning_bg, italic = true })
  hl(0, "DiagnosticVirtualTextInfo",   { fg = p.blue,   bg = p.info_bg, italic = true })
  hl(0, "DiagnosticVirtualTextHint",   { fg = p.teal,   bg = p.hint_bg, italic = true })
  hl(0, "DiagnosticSignError",         { fg = p.red,    bold = true })
  hl(0, "DiagnosticSignWarn",          { fg = p.yellow, bold = true })
  hl(0, "DiagnosticSignInfo",          { fg = p.blue,   bold = true })
  hl(0, "DiagnosticSignHint",          { fg = p.teal,   bold = true })
  hl(0, "DiagnosticFloatingError",     { fg = p.red                 })
  hl(0, "DiagnosticFloatingWarn",      { fg = p.yellow              })
  hl(0, "DiagnosticFloatingInfo",      { fg = p.blue                })
  hl(0, "DiagnosticFloatingHint",      { fg = p.teal                })

  -- ── LSP references ────────────────────────────────────────────────────────
  hl(0, "LspReferenceText",            { bg = p.surface1            })
  hl(0, "LspReferenceRead",            { bg = p.diff_add            })
  hl(0, "LspReferenceWrite",           { bg = p.diff_delete         })
  hl(0, "LspInlayHint",               { fg = p.overlay0, italic = true, bg = p.cursorline })
  hl(0, "LspCodeLens",                { fg = p.overlay0, italic = true })
  hl(0, "LspSignatureActiveParameter", { bold = true, underline = true, sp = p.blue })

  -- ── Git signs ─────────────────────────────────────────────────────────────
  hl(0, "GitSignsAdd",                 { fg = p.green               })
  hl(0, "GitSignsChange",              { fg = p.yellow              })
  hl(0, "GitSignsDelete",              { fg = p.red                 })
  hl(0, "GitSignsAddNr",               { link = "GitSignsAdd"       })
  hl(0, "GitSignsChangeNr",            { link = "GitSignsChange"    })
  hl(0, "GitSignsDeleteNr",            { link = "GitSignsDelete"    })
  hl(0, "GitSignsAddLn",               { bg = p.diff_add            })
  hl(0, "GitSignsChangeLn",            { bg = p.diff_change         })
  hl(0, "GitSignsDeleteLn",            { bg = p.diff_delete         })
  hl(0, "GitSignsCurrentLineBlame",    { fg = p.overlay0, italic = true })

  -- ── Quickfix / Location list ───────────────────────────────────────────────
  hl(0, "QuickFixLine",                { bg = p.selection           })
  hl(0, "qfLineNr",                    { fg = p.yellow              })
  hl(0, "qfFileName",                  { fg = p.blue                })
  hl(0, "qfSeparator",                 { fg = p.overlay0            })

  -- ── Telescope ────────────────────────────────────────────────────────────
  hl(0, "TelescopeNormal",             { link = "NormalFloat"       })
  hl(0, "TelescopePromptNormal",       { fg = p.text, bg = p.surface0 })
  hl(0, "TelescopePromptBorder",       { fg = p.surface0, bg = p.surface0 })
  hl(0, "TelescopePromptTitle",        { fg = p.base, bg = p.blue, bold = true })
  hl(0, "TelescopeResultsNormal",      { fg = p.text, bg = p.float_bg })
  hl(0, "TelescopeResultsBorder",      { fg = p.float_bg, bg = p.float_bg })
  hl(0, "TelescopeResultsTitle",       { fg = p.float_bg, bg = p.float_bg })
  hl(0, "TelescopePreviewNormal",      { link = "NormalFloat"       })
  hl(0, "TelescopePreviewBorder",      { fg = p.float_bg, bg = p.float_bg })
  hl(0, "TelescopePreviewTitle",       { fg = p.base, bg = p.green, bold = true })
  hl(0, "TelescopeSelection",          { fg = p.text, bg = p.surface1 })
  hl(0, "TelescopeSelectionCaret",     { fg = p.blue                })
  hl(0, "TelescopeMultiSelection",     { fg = p.mauve               })
  hl(0, "TelescopeMatching",           { fg = p.yellow, bold = true })
  hl(0, "TelescopePromptPrefix",       { fg = p.blue                })

  -- ── Which-key ─────────────────────────────────────────────────────────────
  hl(0, "WhichKey",                    { fg = p.teal                })
  hl(0, "WhichKeyGroup",               { fg = p.blue                })
  hl(0, "WhichKeyDesc",                { fg = p.text                })
  hl(0, "WhichKeySeparator",           { fg = p.overlay0            })
  hl(0, "WhichKeyFloat",               { bg = p.float_bg            })
  hl(0, "WhichKeyBorder",              { fg = p.border, bg = p.float_bg })
  hl(0, "WhichKeyValue",               { fg = p.overlay1            })

  -- ── nvim-cmp ──────────────────────────────────────────────────────────────
  hl(0, "CmpNormal",                   { link = "NormalFloat"       })
  hl(0, "CmpBorder",                   { link = "FloatBorder"       })
  hl(0, "CmpItemAbbr",                 { fg = p.text                })
  hl(0, "CmpItemAbbrDeprecated",       { fg = p.overlay0, strikethrough = true })
  hl(0, "CmpItemAbbrMatch",            { fg = p.blue, bold = true   })
  hl(0, "CmpItemAbbrMatchFuzzy",       { fg = p.blue, bold = true, italic = true })
  hl(0, "CmpItemMenu",                 { fg = p.overlay0, italic = true })
  hl(0, "CmpGhostText",                { fg = p.overlay0, italic = true })

  -- ── Indent blankline ────────────────────────────────────────────────────────
  hl(0, "IblIndent",                   { fg = p.indent_guide        })
  hl(0, "IblScope",                    { fg = p.overlay0            })
  hl(0, "IblChar",                     { fg = p.indent_guide        })
  hl(0, "IblScopeChar",                { fg = p.blue                })

  -- ── Notify ────────────────────────────────────────────────────────────────
  hl(0, "NotifyBackground",            { bg = p.float_bg            })
  hl(0, "NotifyERRORBorder",           { fg = p.red                 })
  hl(0, "NotifyWARNBorder",            { fg = p.yellow              })
  hl(0, "NotifyINFOBorder",            { fg = p.blue                })
  hl(0, "NotifyDEBUGBorder",           { fg = p.overlay0            })
  hl(0, "NotifyTRACEBorder",           { fg = p.mauve               })
  hl(0, "NotifyERRORIcon",             { fg = p.red                 })
  hl(0, "NotifyWARNIcon",              { fg = p.yellow              })
  hl(0, "NotifyINFOIcon",              { fg = p.blue                })
  hl(0, "NotifyDEBUGIcon",             { fg = p.overlay0            })
  hl(0, "NotifyTRACEIcon",             { fg = p.mauve               })
  hl(0, "NotifyERRORTitle",            { fg = p.red, bold = true    })
  hl(0, "NotifyWARNTitle",             { fg = p.yellow, bold = true })
  hl(0, "NotifyINFOTitle",             { fg = p.blue, bold = true   })
  hl(0, "NotifyDEBUGTitle",            { fg = p.overlay0, bold = true })
  hl(0, "NotifyTRACETitle",            { fg = p.mauve, bold = true  })
  hl(0, "NotifyERRORBody",             { link = "NormalFloat"       })
  hl(0, "NotifyWARNBody",              { link = "NormalFloat"       })
  hl(0, "NotifyINFOBody",              { link = "NormalFloat"       })
  hl(0, "NotifyDEBUGBody",             { link = "NormalFloat"       })
  hl(0, "NotifyTRACEBody",             { link = "NormalFloat"       })

  -- ── Noice ─────────────────────────────────────────────────────────────────
  hl(0, "NoiceVirtualText",            { fg = p.overlay0, italic = true })
  hl(0, "NoiceCmdlinePopup",           { link = "NormalFloat"       })
  hl(0, "NoiceCmdlinePopupBorder",     { link = "FloatBorder"       })
  hl(0, "NoiceCmdlineIcon",            { fg = p.blue                })
  hl(0, "NoiceConfirmBorder",          { fg = p.blue                })
  hl(0, "NoiceFormatTitle",            { fg = p.blue, bold = true   })

  -- ── Trouble ───────────────────────────────────────────────────────────────
  hl(0, "TroubleNormal",               { link = "NormalFloat"       })
  hl(0, "TroubleCount",                { fg = p.yellow, bold = true })
  hl(0, "TroubleFile",                 { fg = p.blue                })
  hl(0, "TroubleSource",               { fg = p.overlay0            })
  hl(0, "TroublePos",                  { fg = p.overlay0            })
  hl(0, "TroubleError",                { fg = p.red                 })
  hl(0, "TroubleWarning",              { fg = p.yellow              })
  hl(0, "TroubleInformation",          { fg = p.blue                })
  hl(0, "TroubleHint",                 { fg = p.teal                })
  hl(0, "TroubleSelected",             { link = "CursorLine"        })
  hl(0, "TroubleFoldIcon",             { fg = p.overlay0            })

  -- ── Todo-comments ─────────────────────────────────────────────────────────
  hl(0, "TodoFgTODO",                  { fg = p.blue                })
  hl(0, "TodoFgFIXME",                 { fg = p.red                 })
  hl(0, "TodoFgHACK",                  { fg = p.yellow              })
  hl(0, "TodoFgNOTE",                  { fg = p.teal                })
  hl(0, "TodoFgPERF",                  { fg = p.mauve               })
  hl(0, "TodoFgWARN",                  { fg = p.yellow              })
  hl(0, "TodoBgTODO",                  { fg = p.base, bg = p.blue,   bold = true })
  hl(0, "TodoBgFIXME",                 { fg = p.base, bg = p.red,    bold = true })
  hl(0, "TodoBgHACK",                  { fg = p.base, bg = p.yellow, bold = true })
  hl(0, "TodoBgNOTE",                  { fg = p.base, bg = p.teal,   bold = true })
  hl(0, "TodoBgPERF",                  { fg = p.base, bg = p.mauve,  bold = true })
  hl(0, "TodoBgWARN",                  { fg = p.base, bg = p.yellow, bold = true })

  -- ── Flash.nvim ────────────────────────────────────────────────────────────
  hl(0, "FlashLabel",                  { bold = true, fg = p.base, bg = p.red   })
  hl(0, "FlashMatch",                  { fg = p.text, bg = p.surface1            })
  hl(0, "FlashCurrent",                { bold = true, fg = p.text, bg = p.blue  })
  hl(0, "FlashBackdrop",               { fg = p.overlay0                         })

  -- ── Lazy.nvim ─────────────────────────────────────────────────────────────
  hl(0, "LazyNormal",                  { link = "NormalFloat"        })
  hl(0, "LazyBorder",                  { link = "FloatBorder"        })
  hl(0, "LazyCommit",                  { fg = p.green                })
  hl(0, "LazyDimmed",                  { fg = p.overlay0             })
  hl(0, "LazyProp",                    { fg = p.overlay0             })
  hl(0, "LazyValue",                   { fg = p.teal                 })
  hl(0, "LazyTaskOutput",              { fg = p.text                 })
  hl(0, "LazyTaskError",               { fg = p.red                  })
  hl(0, "LazyProgressDone",            { bold = true, fg = p.green   })
  hl(0, "LazyProgressTodo",            { bold = true, fg = p.overlay0 })
  hl(0, "LazyReasonPlugin",            { fg = p.mauve                })
  hl(0, "LazyReasonEvent",             { fg = p.yellow               })
  hl(0, "LazyReasonKeys",              { fg = p.teal                 })
  hl(0, "LazyReasonSource",            { fg = p.blue                 })
  hl(0, "LazyReasonImport",            { fg = p.text                 })
  hl(0, "LazyReasonCmd",               { fg = p.peach                })
  hl(0, "LazyReasonFt",                { fg = p.teal                 })
  hl(0, "LazyReasonStart",             { fg = p.text                 })
  hl(0, "LazyH1",                      { fg = p.base, bg = p.blue, bold = true })
  hl(0, "LazyH2",                      { fg = p.blue, bold = true    })
  hl(0, "LazyButton",                  { fg = p.text, bg = p.surface0 })
  hl(0, "LazyButtonActive",            { fg = p.base, bg = p.blue, bold = true })
  hl(0, "LazyDimmedButton",            { fg = p.overlay0, bg = p.surface0 })
  hl(0, "LazySpecial",                 { fg = p.blue                 })
  hl(0, "LazyLocal",                   { fg = p.green                })

  -- ── Mason ─────────────────────────────────────────────────────────────────
  hl(0, "MasonNormal",                 { link = "NormalFloat"        })
  hl(0, "MasonHighlight",              { fg = p.blue, bold = true    })
  hl(0, "MasonHighlightBlock",         { fg = p.base, bg = p.blue    })
  hl(0, "MasonPackageInstalled",       { fg = p.green, bold = true   })
  hl(0, "MasonPackageUninstalled",     { fg = p.red                  })
  hl(0, "MasonPackagePending",         { fg = p.yellow               })
  hl(0, "MasonMuted",                  { fg = p.overlay0             })
  hl(0, "MasonError",                  { fg = p.red, bold = true     })

  -- ── DAP UI ────────────────────────────────────────────────────────────────
  hl(0, "DapBreakpoint",               { fg = p.red, bold = true     })
  hl(0, "DapBreakpointCondition",      { fg = p.yellow, bold = true  })
  hl(0, "DapLogPoint",                 { fg = p.blue, bold = true    })
  hl(0, "DapStopped",                  { fg = p.green, bold = true   })
  hl(0, "DapBreakpointRejected",       { fg = p.overlay0             })

  -- ── Render-markdown ────────────────────────────────────────────────────────
  hl(0, "RenderMarkdownH1",            { bold = true, fg = p.blue    })
  hl(0, "RenderMarkdownH2",            { bold = true, fg = p.green   })
  hl(0, "RenderMarkdownH3",            { bold = true, fg = p.yellow  })
  hl(0, "RenderMarkdownH4",            { bold = true, fg = p.red     })
  hl(0, "RenderMarkdownH5",            { bold = true, fg = p.mauve   })
  hl(0, "RenderMarkdownH6",            { bold = true, fg = p.teal    })
  hl(0, "RenderMarkdownCode",          { bg = p.surface0             })
  hl(0, "RenderMarkdownCodeInline",    { fg = p.teal, bg = p.surface0 })
  hl(0, "RenderMarkdownBullet",        { fg = p.blue, bold = true    })
  hl(0, "RenderMarkdownChecked",       { fg = p.green, bold = true   })
  hl(0, "RenderMarkdownUnchecked",     { fg = p.overlay0             })
  hl(0, "RenderMarkdownTableHead",     { fg = p.blue, bold = true    })
  hl(0, "RenderMarkdownLink",          { fg = p.blue, underline = true })

  -- ── Terminal ───────────────────────────────────────────────────────────────
  vim.g.terminal_color_0  = p.surface1   -- black
  vim.g.terminal_color_1  = p.red        -- red
  vim.g.terminal_color_2  = p.green      -- green
  vim.g.terminal_color_3  = p.yellow     -- yellow
  vim.g.terminal_color_4  = p.blue       -- blue
  vim.g.terminal_color_5  = p.pink       -- magenta
  vim.g.terminal_color_6  = p.teal       -- cyan
  vim.g.terminal_color_7  = p.subtext1   -- white
  vim.g.terminal_color_8  = p.surface2   -- bright black
  vim.g.terminal_color_9  = p.red        -- bright red
  vim.g.terminal_color_10 = p.green      -- bright green
  vim.g.terminal_color_11 = p.yellow     -- bright yellow
  vim.g.terminal_color_12 = p.blue       -- bright blue
  vim.g.terminal_color_13 = p.mauve      -- bright magenta
  vim.g.terminal_color_14 = p.sky        -- bright cyan
  vim.g.terminal_color_15 = p.text       -- bright white
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🌐 PUBLIC API
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---Get the current resolved palette
---@return table
function M.get_palette()
  return load_palette()
end

---Apply the ash-dynamic theme (loads palette + sets all highlights)
function M.apply()
  vim.opt.termguicolors = true
  vim.opt.background    = "dark"

  local p = load_palette()
  apply_highlights(p)

  -- Export palette globally for other modules
  _G.AshDynamicPalette = p

  return p
end

---Invalidate palette cache (called when ASH theme changes)
function M.invalidate()
  _cached_palette  = nil
  _cache_time      = 0
end

---Hot-reload: re-apply highlights with fresh palette
function M.reload()
  M.invalidate()
  M.apply()
end

-- Make it a proper Neovim colorscheme
M.setup = function()
  vim.cmd.highlight("clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd.syntax("reset")
  end
  vim.g.colors_name = "ash-dynamic"
  M.apply()
end

return M