-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — POST-LOAD HIGHLIGHT OVERRIDES               ║
-- ║           Applied after all plugins load to fix color conflicts            ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

local function hi(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

-- Load ASH colors
local ok, ash = pcall(require, "themes.ash")
local c = {}
if ok then
    c = ash.load_colors()
else
    c = {
        base     = "#1e1e2e",
        surface0 = "#313244",
        primary  = "#cba6f7",
        secondary= "#89b4fa",
        text     = "#cdd6f4",
        error    = "#f38ba8",
        success  = "#a6e3a1",
        warning  = "#f9e2af",
    }
end

-- ── Cursor Line Number ─────────────────────────────────────────────────────────
hi("CursorLineNr",    { fg = c.primary, bold = true })
hi("CursorLineFold",  { fg = c.primary })
hi("CursorLineSign",  { bg = c.base })

-- ── Float Windows ──────────────────────────────────────────────────────────────
hi("NormalFloat",     { fg = c.text,    bg = c.base })
hi("FloatBorder",     { fg = c.surface0 })
hi("FloatTitle",      { fg = c.primary, bold = true })

-- ── Telescope overrides ────────────────────────────────────────────────────────
hi("TelescopePromptPrefix", { fg = c.primary, bold = true })
hi("TelescopeResultsDiffAdd",    { fg = c.success })
hi("TelescopeResultsDiffChange", { fg = c.warning })
hi("TelescopeResultsDiffDelete", { fg = c.error })

-- ── CMP Ghost text ────────────────────────────────────────────────────────────
hi("CmpGhostText", { fg = "#6c7086", italic = true })

-- ── Indent scope ──────────────────────────────────────────────────────────────
hi("MiniIndentscopeSymbol",       { fg = c.primary })
hi("MiniIndentscopeSymbolOff",    { fg = c.error })

-- ── Markdown rendering ────────────────────────────────────────────────────────
hi("RenderMarkdownH1",   { fg = c.primary,   bold = true })
hi("RenderMarkdownH2",   { fg = c.secondary, bold = true })
hi("RenderMarkdownH3",   { fg = c.tertiary,  bold = true })
hi("RenderMarkdownH1Bg", { bg = "#cba6f715" })
hi("RenderMarkdownH2Bg", { bg = "#89b4fa15" })
hi("RenderMarkdownH3Bg", { bg = "#94e2d515" })
hi("RenderMarkdownCode", { bg = "#313244" })
hi("RenderMarkdownCodeInline", { fg = c.primary, bg = "#31324466" })
hi("RenderMarkdownBullet",     { fg = c.primary })
hi("RenderMarkdownChecked",    { fg = c.success })
hi("RenderMarkdownUnchecked",  { fg = c.text })
hi("RenderMarkdownTodo",       { fg = c.warning })
hi("RenderMarkdownTableHead",  { fg = c.primary, bold = true })
hi("RenderMarkdownTableRow",   { fg = c.text })
hi("RenderMarkdownQuote",      { fg = c.secondary, italic = true })
hi("RenderMarkdownLink",       { fg = c.secondary, underline = true })
hi("RenderMarkdownDash",       { fg = c.surface0 })

-- ── Yanky flash highlight ─────────────────────────────────────────────────────
hi("YankyPut",         { link = "IncSearch" })
hi("YankyYanked",      { link = "IncSearch" })

-- ── Search overrides ──────────────────────────────────────────────────────────
hi("IncSearch",        { fg = c.base, bg = c.warning, bold = true })
hi("Search",           { fg = c.base, bg = c.secondary })
hi("CurSearch",        { fg = c.base, bg = c.primary, bold = true })

-- ── URL highlight ─────────────────────────────────────────────────────────────
hi("Url", { fg = c.secondary, underline = true })

-- ── Neotest ───────────────────────────────────────────────────────────────────
hi("NeotestPassed",    { fg = c.success })
hi("NeotestFailed",    { fg = c.error })
hi("NeotestSkipped",   { fg = c.warning })
hi("NeotestRunning",   { fg = c.info })
hi("NeotestBorder",    { fg = c.surface0 })
hi("NeotestNamespace", { fg = c.secondary, bold = true })

-- ── DAP UI ────────────────────────────────────────────────────────────────────
hi("DapUIVariable",    { fg = c.text })
hi("DapUIType",        { fg = c.secondary })
hi("DapUIValue",       { fg = c.success })
hi("DapUIModifiedValue", { fg = c.warning, bold = true })
hi("DapUIDecoration",  { fg = c.primary })
hi("DapUIThread",      { fg = c.success })
hi("DapUIStoppedThread",{ fg = c.primary })
hi("DapUIFrameName",   { fg = c.text })
hi("DapUISource",      { fg = c.secondary })
hi("DapUILineNumber",  { fg = c.primary })
hi("DapUIFloatBorder", { fg = c.surface0 })
hi("DapUIWatchesEmpty",{ fg = c.error })
hi("DapUIWatchesValue",{ fg = c.success })
hi("DapUIWatchesError",{ fg = c.error })
hi("DapUIBreakpointsPath", { fg = c.secondary })
hi("DapUIBreakpointsInfo", { fg = c.success })
hi("DapUIBreakpointsCurrentLine", { fg = c.success, bold = true })

-- ── Notify overrides ──────────────────────────────────────────────────────────
hi("NotifyBackground", { bg = c.base })