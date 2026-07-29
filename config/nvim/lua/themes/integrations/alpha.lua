-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🚀 ALPHA INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                       ║
-- ║   Dashboard / starter screens · header · buttons · footer · shortcuts          ║
-- ║   Alpha.nvim · dashboard.nvim · mini.starter · snacks.dashboard                ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

---Apply alpha / dashboard highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🏠 ALPHA.NVIM
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  -- ── ASCII art header ──────────────────────────────────────────────────────
  hl(0, "AlphaHeader",          { fg = p.blue,    bold = true               })
  hl(0, "AlphaHeaderLabel",     { fg = p.blue,    bold = true               })

  -- ── Gradient header (6 header colour levels) ────────────────────────────
  hl(0, "AlphaHeader1",         { fg = p.blue,    bold = true               })
  hl(0, "AlphaHeader2",         { fg = p.sapphire, bold = true              })
  hl(0, "AlphaHeader3",         { fg = p.sky,     bold = true               })
  hl(0, "AlphaHeader4",         { fg = p.teal,    bold = true               })
  hl(0, "AlphaHeader5",         { fg = p.green,   bold = true               })
  hl(0, "AlphaHeader6",         { fg = p.mauve,   bold = true               })

  -- ── Buttons ───────────────────────────────────────────────────────────────
  hl(0, "AlphaButtons",         { fg = p.teal                               })
  hl(0, "AlphaButtonsHighlight",{ fg = p.teal,    bold = true               })
  hl(0, "AlphaButtonShortcut",  { fg = p.yellow,  bold = true               })
  hl(0, "AlphaButtonPrefix",    { fg = p.blue,    bold = true               })
  hl(0, "AlphaButtonText",      { fg = p.text                               })
  hl(0, "AlphaButtonIcon",      { fg = p.blue                               })

  -- ── Footer / info ─────────────────────────────────────────────────────────
  hl(0, "AlphaFooter",          { fg = p.overlay0, italic = true             })
  hl(0, "AlphaFooterLabel",     { fg = p.overlay0, italic = true             })
  hl(0, "AlphaFiller",          { fg = p.surface1                            })

  -- ── Menu / section headings ────────────────────────────────────────────────
  hl(0, "AlphaBanner",          { fg = p.mauve,   bold = true               })
  hl(0, "AlphaGroup",           { fg = p.blue,    bold = true               })
  hl(0, "AlphaKeyLabel",        { fg = p.yellow,  bold = true               })
  hl(0, "AlphaLabel",           { fg = p.text                               })

  -- ── Stats / counters ──────────────────────────────────────────────────────
  hl(0, "AlphaStat",            { fg = p.teal,    italic = true             })
  hl(0, "AlphaStatLabel",       { fg = p.overlay0, italic = true            })

  -- ── Highlight selection ────────────────────────────────────────────────────
  hl(0, "AlphaSelected",        { fg = p.base,    bg = p.blue,  bold = true })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📊 DASHBOARD.NVIM
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DashboardHeader",      { fg = p.blue,    bold = true               })
  hl(0, "DashboardFooter",      { fg = p.overlay0, italic = true            })
  hl(0, "DashboardCenter",      { fg = p.teal                               })
  hl(0, "DashboardShortcut",    { fg = p.yellow,  bold = true               })
  hl(0, "DashboardIcon",        { fg = p.blue                               })
  hl(0, "DashboardDesc",        { fg = p.text                               })
  hl(0, "DashboardKey",         { fg = p.yellow,  bold = true               })
  hl(0, "DashboardCon",         { fg = p.teal                               })
  hl(0, "DashboardMruTitle",    { fg = p.blue,    bold = true               })
  hl(0, "DashboardMruIcon",     { fg = p.blue                               })
  hl(0, "DashboardNetctlTitle", { fg = p.blue,    bold = true               })
  hl(0, "DashboardFzfTitle",    { fg = p.blue,    bold = true               })
  hl(0, "DashboardProject",     { fg = p.teal                               })
  hl(0, "DashboardProjectTitle",{ fg = p.blue,    bold = true               })
  hl(0, "DashboardProjectTitleIcon", { fg = p.blue                          })
  hl(0, "DashboardProjectIcon", { fg = p.teal                               })
  hl(0, "DashboardFiles",       { fg = p.text                               })
  hl(0, "DashboardFilesNumber", { fg = p.peach                              })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌱 MINI.STARTER
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "MiniStarterCurrent",   { link = "CursorLine"                       })
  hl(0, "MiniStarterFooter",    { fg = p.overlay0, italic = true            })
  hl(0, "MiniStarterHeader",    { fg = p.blue,    bold = true               })
  hl(0, "MiniStarterInactive",  { fg = p.surface2                           })
  hl(0, "MiniStarterItem",      { fg = p.text                               })
  hl(0, "MiniStarterItemBullet",{ fg = p.surface1                           })
  hl(0, "MiniStarterItemPrefix",{ fg = p.yellow,  bold = true               })
  hl(0, "MiniStarterQuery",     { fg = p.blue,    bold = true               })
  hl(0, "MiniStarterSection",   { fg = p.blue,    bold = true               })
  hl(0, "MiniStarterSectionSep",{ fg = p.surface1                           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🍕 SNACKS.DASHBOARD (also handled in noice.lua, but extras here)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "SnacksDashboardNormal",    { fg = p.text,    bg = p.base            })
  hl(0, "SnacksDashboardBorder",    { link = "FloatBorder"                   })
  hl(0, "SnacksDashboardTitle",     { fg = p.blue,    bold = true            })
  hl(0, "SnacksDashboardHeader",    { fg = p.mauve,   bold = true            })
  hl(0, "SnacksDashboardFooter",    { fg = p.overlay0, italic = true         })
  hl(0, "SnacksDashboardKey",       { fg = p.yellow,  bold = true            })
  hl(0, "SnacksDashboardIcon",      { fg = p.blue                            })
  hl(0, "SnacksDashboardDesc",      { fg = p.text                            })
  hl(0, "SnacksDashboardDir",       { fg = p.overlay0, italic = true         })
  hl(0, "SnacksDashboardSection",   { fg = p.blue,    bold = true            })
  hl(0, "SnacksDashboardSpecial",   { fg = p.mauve,   bold = true            })
  hl(0, "SnacksDashboardTerminal",  { fg = p.text,    bg = p.base            })
  hl(0, "SnacksDashboardRecent",    { fg = p.text                            })
  hl(0, "SnacksDashboardProjects",  { fg = p.teal                            })
  hl(0, "SnacksDashboardSearch",    { fg = p.yellow                          })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎨 ASH DASHBOARD BANNER — colour-coded segments
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- These are used by the ASH custom ASCII banner
  hl(0, "AshDashboardLogo1",    { fg = p.blue,    bold = true               })
  hl(0, "AshDashboardLogo2",    { fg = p.sapphire, bold = true              })
  hl(0, "AshDashboardLogo3",    { fg = p.teal,    bold = true               })
  hl(0, "AshDashboardLogo4",    { fg = p.green,   bold = true               })
  hl(0, "AshDashboardVersion",  {
    fg     = p.overlay0,
    italic = true,
    bold   = false,
  })
  hl(0, "AshDashboardOmega",    {
    fg   = p.peach,
    bold = true,
  })
  hl(0, "AshDashboardStat",     { fg = p.teal,    italic = true             })
  hl(0, "AshDashboardStatSep",  { fg = p.surface1                           })
  hl(0, "AshDashboardPlugins",  { fg = p.mauve,   bold = true               })
  hl(0, "AshDashboardLoaded",   { fg = p.green,   bold = true               })
  hl(0, "AshDashboardStartup",  { fg = p.yellow,  italic = true             })
end

return M