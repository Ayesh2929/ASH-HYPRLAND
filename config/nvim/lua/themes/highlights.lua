-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ✨ ASH HIGHLIGHTS — EXTRA LAYER v5.0 OMEGA                               ║
-- ║   Applied ON TOP of any active colorscheme · plugin-specific overrides        ║
-- ║   ASH-branded groups · dynamic palette injection · zero flicker               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 PALETTE RESOLVER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function get_palette()
  -- 1. Try ASH theme engine
  local ok_ash, ash_theme = pcall(require, "themes.init")
  if ok_ash then
    local p = ash_theme.palette()
    if p and next(p) then return p end
  end

  -- 2. Try ash-dynamic module
  local ok_dyn, dyn = pcall(require, "themes.ash-dynamic")
  if ok_dyn then
    return dyn.get_palette()
  end

  -- 3. Try global (set by ash-dynamic.apply())
  if _G.AshDynamicPalette and next(_G.AshDynamicPalette) then
    return _G.AshDynamicPalette
  end

  -- 4. Fallback: extract from active colorscheme
  local function extract(group, attr)
    local ok, val = pcall(function()
      return vim.api.nvim_get_hl(0, { name = group, link = false })
    end)
    if ok and val and val[attr] then
      return string.format("#%06x", val[attr])
    end
    return nil
  end

  return {
    base     = extract("Normal",  "bg")  or "#1e1e2e",
    text     = extract("Normal",  "fg")  or "#cdd6f4",
    surface0 = extract("CursorLine","bg")or "#313244",
    blue     = extract("Function","fg")  or "#89b4fa",
    green    = extract("String",  "fg")  or "#a6e3a1",
    red      = extract("Error",   "fg")  or "#f38ba8",
    yellow   = extract("Type",    "fg")  or "#f9e2af",
    mauve    = extract("Keyword", "fg")  or "#cba6f7",
    teal     = extract("Special", "fg")  or "#94e2d5",
    peach    = extract("Constant","fg")  or "#fab387",
    overlay0 = extract("Comment", "fg")  or "#6c7086",
    surface1 = extract("VertSplit","fg") or "#45475a",
    overlay2 = extract("NonText", "fg")  or "#9399b2",
    border   = extract("FloatBorder","fg")or "#45475a",
    float_bg = extract("NormalFloat","bg")or "#1e1e2e",
  }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT APPLICATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---Apply all ASH extra highlights on top of the current colorscheme
function M.apply()
  local p  = get_palette()
  local hl = vim.api.nvim_set_hl

  if not p or not p.base then return end

  -- ── ASH branding groups ───────────────────────────────────────────────────
  hl(0, "AshAccent",      { bold = true,   fg = p.blue    })
  hl(0, "AshSuccess",     { bold = true,   fg = p.green   })
  hl(0, "AshError",       { bold = true,   fg = p.red     })
  hl(0, "AshWarning",     { bold = true,   fg = p.yellow  })
  hl(0, "AshInfo",        { bold = true,   fg = p.blue    })
  hl(0, "AshHint",        { bold = true,   fg = p.teal    })
  hl(0, "AshMuted",       { italic = true, fg = p.overlay0 })
  hl(0, "AshBrand",       { bold = true,   fg = p.mauve   })
  hl(0, "AshOmega",       { bold = true,   fg = p.peach   })

  -- ── Float window consistency ──────────────────────────────────────────────
  hl(0, "NormalFloat",    { fg = p.text,   bg = p.float_bg })
  hl(0, "FloatBorder",    { fg = p.border, bg = p.float_bg })
  hl(0, "FloatTitle",     { fg = p.blue,   bold = true     })
  hl(0, "FloatFooter",    { fg = p.overlay0                 })

  -- ── Cursor refinements ────────────────────────────────────────────────────
  hl(0, "CursorLineNr",   { fg = p.yellow, bold = true     })
  hl(0, "LineNr",         { fg = p.surface1                 })

  -- ── Special UI: selection that feels premium ──────────────────────────────
  hl(0, "Visual",         {
    bg   = (p.blue:sub(1,7) .. "30"):gsub("30", ""),   -- fallback
  })
  -- Safer visual override using mix
  pcall(function()
    local ok, dyn = pcall(require, "themes.ash-dynamic")
    if ok then
      local tinted = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Normal")), "bg#")
      if tinted == "" then tinted = p.base end
    end
  end)

  -- ── Indent guides ─────────────────────────────────────────────────────────
  hl(0, "IblIndent",       { fg = p.surface1                })
  hl(0, "IblScope",        { fg = p.overlay0                })

  -- ── Matching parens ───────────────────────────────────────────────────────
  hl(0, "MatchParen",      {
    bold      = true,
    underline = true,
    fg        = p.peach,
    sp        = p.peach,
  })

  -- ── Statusline polish ─────────────────────────────────────────────────────
  -- Make sure statusline doesn't look jarring against float borders
  hl(0, "StatusLine",      {
    fg  = p.text,
    bg  = p.surface0,
  })
  hl(0, "StatusLineNC",    {
    fg  = p.overlay0,
    bg  = p.surface0,
  })

  -- ── WinBar polish ─────────────────────────────────────────────────────────
  hl(0, "WinBar",          { fg = p.text,    bg = p.base   })
  hl(0, "WinBarNC",        { fg = p.overlay0, bg = p.base  })
  hl(0, "WinSeparator",    { fg = p.surface1                })

  -- ── Popup menu ───────────────────────────────────────────────────────────
  hl(0, "Pmenu",           { fg = p.text,    bg = p.float_bg })
  hl(0, "PmenuSel",        { fg = p.base,    bg = p.blue     })
  hl(0, "PmenuSbar",       { bg = p.surface1                 })
  hl(0, "PmenuThumb",      { bg = p.overlay0                 })

  -- ── Command line ──────────────────────────────────────────────────────────
  hl(0, "ModeMsg",         { fg = p.blue,    bold = true     })
  hl(0, "MsgArea",         { fg = p.text                     })

  -- ── Tabline consistency ───────────────────────────────────────────────────
  hl(0, "TabLine",         { fg = p.overlay0, bg = p.surface0 })
  hl(0, "TabLineSel",      { fg = p.base, bg = p.blue, bold = true })
  hl(0, "TabLineFill",     { bg = p.surface0                  })

  -- ── Search refinements ────────────────────────────────────────────────────
  hl(0, "Search",          { fg = p.base, bg = p.yellow       })
  hl(0, "IncSearch",       { fg = p.base, bg = p.peach        })
  hl(0, "CurSearch",       { fg = p.base, bg = p.red          })

  -- ── Spell check ───────────────────────────────────────────────────────────
  hl(0, "SpellBad",        { undercurl = true, sp = p.red     })
  hl(0, "SpellCap",        { undercurl = true, sp = p.yellow  })
  hl(0, "SpellRare",       { undercurl = true, sp = p.teal    })
  hl(0, "SpellLocal",      { undercurl = true, sp = p.blue    })

  -- ── Inlay hints ───────────────────────────────────────────────────────────
  hl(0, "LspInlayHint",    {
    italic = true,
    fg     = p.overlay0,
    bg     = p.surface0,
  })

  -- ── Copilot / AI suggestion ───────────────────────────────────────────────
  hl(0, "CopilotSuggestion", { italic = true, fg = p.overlay0 })
  hl(0, "CodeiumSuggestion", { italic = true, fg = p.overlay0 })

  -- ── nvim-notify ───────────────────────────────────────────────────────────
  hl(0, "NotifyBackground", { bg = p.float_bg                })

  -- ── snacks.nvim ───────────────────────────────────────────────────────────
  hl(0, "SnacksNormal",     { link = "NormalFloat"           })
  hl(0, "SnacksBorder",     { link = "FloatBorder"           })
  hl(0, "SnacksInputNormal",{ fg = p.text, bg = p.surface0   })
  hl(0, "SnacksInputBorder",{ fg = p.border, bg = p.surface0 })
  hl(0, "SnacksDashboardTitle",{ bold = true, fg = p.blue    })
  hl(0, "SnacksDashboardHeader",{ fg = p.mauve               })
  hl(0, "SnacksDashboardFooter",{ fg = p.overlay0, italic = true })
  hl(0, "SnacksDashboardKey",  { bold = true, fg = p.yellow  })
  hl(0, "SnacksDashboardIcon", { fg = p.blue                 })
  hl(0, "SnacksDashboardDesc", { fg = p.text                 })

  -- ── Alpha dashboard ───────────────────────────────────────────────────────
  hl(0, "AlphaHeader",      { fg = p.blue                    })
  hl(0, "AlphaShortcut",    { fg = p.yellow, bold = true     })
  hl(0, "AlphaButtons",     { fg = p.teal                    })
  hl(0, "AlphaFooter",      { fg = p.overlay0, italic = true })

  -- ── Gitsigns ──────────────────────────────────────────────────────────────
  hl(0, "GitSignsAdd",      { fg = p.green                   })
  hl(0, "GitSignsChange",   { fg = p.yellow                  })
  hl(0, "GitSignsDelete",   { fg = p.red                     })
  hl(0, "GitSignsCurrentLineBlame", { fg = p.overlay0, italic = true })

  -- ── Surround ─────────────────────────────────────────────────────────────
  hl(0, "NvimSurroundHighlight", { link = "IncSearch"        })

  -- ── Illuminate ────────────────────────────────────────────────────────────
  hl(0, "IlluminatedWordText",   { bg = p.surface1            })
  hl(0, "IlluminatedWordRead",   { bg = p.surface1            })
  hl(0, "IlluminatedWordWrite",  { bg = p.surface1            })

  -- ── Context ───────────────────────────────────────────────────────────────
  hl(0, "TreesitterContext",     { link = "NormalFloat"       })
  hl(0, "TreesitterContextBottom",{ underline = true, sp = p.blue })

  -- ── Neogit ────────────────────────────────────────────────────────────────
  hl(0, "NeogitBranch",     { bold = true, fg = p.blue       })
  hl(0, "NeogitRemote",     { bold = true, fg = p.mauve      })
  hl(0, "NeogitHunkHeader", { bold = true, link = "IncSearch" })

  -- ── Avante ────────────────────────────────────────────────────────────────
  hl(0, "AvanteTitle",      { bold = true, fg = p.mauve      })
  hl(0, "AvanteUser",       { bold = true, fg = p.blue       })
  hl(0, "AvanteAI",         { bold = true, fg = p.mauve      })

  -- ── CodeCompanion ─────────────────────────────────────────────────────────
  hl(0, "CodeCompanionChatHeader", { bold = true, fg = p.blue })
  hl(0, "CodeCompanionStreaming",  { bold = true, italic = true, fg = p.mauve })

  -- ── Hyprland config ───────────────────────────────────────────────────────
  hl(0, "@keyword.hypr",   { bold = true, fg = p.blue        })
  hl(0, "@property.hypr",  { fg = p.text                     })
  hl(0, "@string.hypr",    { fg = p.green                    })

  -- ── Norg (Neorg) ──────────────────────────────────────────────────────────
  hl(0, "@neorg.headings.1.title", { bold = true, fg = p.blue   })
  hl(0, "@neorg.headings.2.title", { bold = true, fg = p.green  })
  hl(0, "@neorg.headings.3.title", { bold = true, fg = p.yellow })
  hl(0, "@neorg.todo_items.done.1",{ bold = true, fg = p.green  })
  hl(0, "@neorg.todo_items.pending.1",{ bold = true, fg = p.yellow })

  -- ── Extra: ensure NonText and SpecialKey are subtle ────────────────────────
  hl(0, "NonText",         { fg = p.surface1                  })
  hl(0, "SpecialKey",      { fg = p.surface2                  })
  hl(0, "Whitespace",      { fg = p.surface1                  })
  hl(0, "EndOfBuffer",     { fg = p.surface0                  })
  hl(0, "Conceal",         { fg = p.overlay0                  })

  -- ── Folding ───────────────────────────────────────────────────────────────
  hl(0, "Folded",          { fg = p.overlay1, bg = p.surface0, italic = true })
  hl(0, "FoldColumn",      { fg = p.overlay0, bg = p.base                    })

  -- ── Diff (extra) ─────────────────────────────────────────────────────────
  hl(0, "Added",           { fg = p.green                     })
  hl(0, "Changed",         { fg = p.yellow                    })
  hl(0, "Removed",         { fg = p.red                       })
end

---Setup autocmd to re-apply highlights after every colorscheme change
function M.setup()
  local aug = vim.api.nvim_create_augroup("AshHighlightsLayer", { clear = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group    = aug,
    callback = function()
      -- Defer slightly to run after the colorscheme's own highlights
      vim.defer_fn(M.apply, 0)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group   = aug,
    pattern = "AshThemeChanged",
    callback = function()
      vim.defer_fn(M.apply, 50)
    end,
  })

  -- Apply immediately
  M.apply()
end

return M