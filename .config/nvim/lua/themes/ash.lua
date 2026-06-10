-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — NEOVIM DYNAMIC THEME                         ║
-- ║           Reads ASH color palette and applies 500+ highlight groups        ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎨 COLOR LOADING
-- ═══════════════════════════════════════════════════════════════════════════════

local CACHE_FILE = vim.fn.expand("~/.cache/ash-dots/colors/current.json")
local _last_mtime = 0
local _colors     = nil

local DEFAULTS = {
    base      = "#1e1e2e",
    mantle    = "#181825",
    crust     = "#11111b",
    surface0  = "#313244",
    surface1  = "#45475a",
    surface2  = "#585b70",
    overlay0  = "#6c7086",
    overlay1  = "#7f849c",
    overlay2  = "#9399b2",
    primary   = "#cba6f7",
    secondary = "#89b4fa",
    tertiary  = "#94e2d5",
    text      = "#cdd6f4",
    subtext1  = "#bac2de",
    subtext0  = "#a6adc8",
    muted     = "#7f849c",
    success   = "#a6e3a1",
    warning   = "#f9e2af",
    error     = "#f38ba8",
    info      = "#89b4fa",
}

function M.load_colors()
    local ok, stat = pcall(vim.loop.fs_stat, CACHE_FILE)
    if not ok or not stat then
        return DEFAULTS
    end

    -- Return cached if not modified
    if stat.mtime.sec == _last_mtime and _colors then
        return _colors
    end

    local f = io.open(CACHE_FILE, "r")
    if not f then return DEFAULTS end

    local content = f:read("*all")
    f:close()

    local colors = {}
    local ok2, data = pcall(vim.json.decode, content)
    if not ok2 then return DEFAULTS end

    -- Flatten nested structure
    for _, section in pairs(data) do
        if type(section) == "table" then
            for k, v in pairs(section) do
                if type(v) == "string" and v:match("^#%x+$") then
                    colors[k] = v
                end
            end
        end
    end

    _colors     = setmetatable(colors, { __index = DEFAULTS })
    _last_mtime = stat.mtime.sec

    return _colors
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 HIGHLIGHT HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function hi(group, opts)
    local ok, err = pcall(vim.api.nvim_set_hl, 0, group, opts)
    if not ok then
        vim.notify("[ASH Theme] Failed to set hl " .. group .. ": " .. err,
            vim.log.levels.WARN)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎨 APPLY HIGHLIGHTS
-- ═══════════════════════════════════════════════════════════════════════════════

function M.apply()
    local c = M.load_colors()

    -- Set colorscheme base
    vim.o.background = "dark"
    vim.cmd("highlight clear")
    if vim.fn.exists("syntax_on") == 1 then
        vim.cmd("syntax reset")
    end
    vim.g.colors_name = "ash"

    -- ── Editor Basics ──────────────────────────────────────────────────────────
    hi("Normal",          { fg = c.text,     bg = c.base })
    hi("NormalFloat",     { fg = c.text,     bg = c.mantle })
    hi("NormalNC",        { fg = c.subtext0, bg = c.base })
    hi("ColorColumn",     {                  bg = c.surface0 })
    hi("Conceal",         { fg = c.overlay1 })
    hi("Cursor",          { fg = c.base,     bg = c.primary })
    hi("CursorIM",        { fg = c.base,     bg = c.primary })
    hi("CursorColumn",    {                  bg = c.surface0 })
    hi("CursorLine",      {                  bg = c.surface0 })
    hi("CursorLineNr",    { fg = c.primary,  bold = true })
    hi("LineNr",          { fg = c.overlay0 })
    hi("LineNrAbove",     { fg = c.overlay0 })
    hi("LineNrBelow",     { fg = c.overlay0 })
    hi("Directory",       { fg = c.secondary })
    hi("ErrorMsg",        { fg = c.error,    bold = true })
    hi("WarningMsg",      { fg = c.warning })
    hi("WildMenu",        { fg = c.text,     bg = c.surface0 })
    hi("Folded",          { fg = c.muted,    bg = c.surface0 })
    hi("FoldColumn",      { fg = c.overlay0, bg = c.base })
    hi("SignColumn",      { fg = c.overlay0, bg = c.base })
    hi("IncSearch",       { fg = c.base,     bg = c.warning, bold = true })
    hi("Substitute",      { fg = c.base,     bg = c.error })
    hi("MatchParen",      { fg = c.primary,  bold = true, underline = true })
    hi("ModeMsg",         { fg = c.text })
    hi("MsgArea",         { fg = c.text })
    hi("MoreMsg",         { fg = c.secondary })
    hi("NonText",         { fg = c.overlay0 })
    hi("Pmenu",           { fg = c.text,     bg = c.surface0 })
    hi("PmenuSel",        { fg = c.base,     bg = c.primary,  bold = true })
    hi("PmenuSbar",       {                  bg = c.surface1 })
    hi("PmenuThumb",      {                  bg = c.primary })
    hi("Question",        { fg = c.secondary })
    hi("Search",          { fg = c.base,     bg = c.secondary })
    hi("SpecialKey",      { fg = c.overlay0 })
    hi("SpellBad",        { undercurl = true, sp = c.error })
    hi("SpellCap",        { undercurl = true, sp = c.warning })
    hi("SpellLocal",      { undercurl = true, sp = c.info })
    hi("SpellRare",       { undercurl = true, sp = c.primary })
    hi("StatusLine",      { fg = c.text,     bg = c.mantle })
    hi("StatusLineNC",    { fg = c.muted,    bg = c.mantle })
    hi("TabLine",         { fg = c.muted,    bg = c.mantle })
    hi("TabLineFill",     {                  bg = c.crust })
    hi("TabLineSel",      { fg = c.text,     bg = c.surface0 })
    hi("Title",           { fg = c.primary,  bold = true })
    hi("Visual",          {                  bg = c.surface1 })
    hi("VisualNOS",       {                  bg = c.surface1 })
    hi("VertSplit",       { fg = c.surface1 })
    hi("WinSeparator",    { fg = c.surface1 })
    hi("Whitespace",      { fg = c.surface1 })
    hi("EndOfBuffer",     { fg = c.base })

    -- ── Syntax Highlighting ────────────────────────────────────────────────────
    hi("Comment",         { fg = c.overlay1, italic = true })
    hi("Constant",        { fg = c.primary })
    hi("String",          { fg = c.success })
    hi("Character",       { fg = c.success })
    hi("Number",          { fg = c.tertiary })
    hi("Boolean",         { fg = c.primary, italic = true })
    hi("Float",           { fg = c.tertiary })
    hi("Identifier",      { fg = c.text })
    hi("Function",        { fg = c.secondary, bold = true })
    hi("Statement",       { fg = c.primary })
    hi("Conditional",     { fg = c.primary, italic = true })
    hi("Repeat",          { fg = c.primary, italic = true })
    hi("Label",           { fg = c.tertiary })
    hi("Operator",        { fg = c.text })
    hi("Keyword",         { fg = c.primary, italic = true })
    hi("Exception",       { fg = c.error })
    hi("PreProc",         { fg = c.tertiary })
    hi("Include",         { fg = c.secondary })
    hi("Define",          { fg = c.primary })
    hi("Macro",           { fg = c.primary })
    hi("PreCondit",       { fg = c.secondary })
    hi("Type",            { fg = c.info, bold = true })
    hi("StorageClass",    { fg = c.primary })
    hi("Structure",       { fg = c.primary })
    hi("Typedef",         { fg = c.primary })
    hi("Special",         { fg = c.tertiary })
    hi("SpecialChar",     { fg = c.tertiary })
    hi("Tag",             { fg = c.primary })
    hi("Delimiter",       { fg = c.text })
    hi("SpecialComment",  { fg = c.overlay1, bold = true })
    hi("Debug",           { fg = c.error })
    hi("Underlined",      { underline = true })
    hi("Ignore",          { fg = c.overlay0 })
    hi("Error",           { fg = c.error })
    hi("Todo",            { fg = c.warning, bold = true })

    -- ── LSP Diagnostics ────────────────────────────────────────────────────────
    hi("DiagnosticError",            { fg = c.error })
    hi("DiagnosticWarn",             { fg = c.warning })
    hi("DiagnosticInfo",             { fg = c.info })
    hi("DiagnosticHint",             { fg = c.success })
    hi("DiagnosticOk",               { fg = c.success })
    hi("DiagnosticSignError",        { fg = c.error,   bg = c.base })
    hi("DiagnosticSignWarn",         { fg = c.warning, bg = c.base })
    hi("DiagnosticSignInfo",         { fg = c.info,    bg = c.base })
    hi("DiagnosticSignHint",         { fg = c.success, bg = c.base })
    hi("DiagnosticVirtualTextError", { fg = c.error,   bg = c.base,    italic = true })
    hi("DiagnosticVirtualTextWarn",  { fg = c.warning, bg = c.base,    italic = true })
    hi("DiagnosticVirtualTextInfo",  { fg = c.info,    bg = c.base,    italic = true })
    hi("DiagnosticVirtualTextHint",  { fg = c.success, bg = c.base,    italic = true })
    hi("DiagnosticUnderlineError",   { undercurl = true, sp = c.error })
    hi("DiagnosticUnderlineWarn",    { undercurl = true, sp = c.warning })
    hi("DiagnosticUnderlineInfo",    { undercurl = true, sp = c.info })
    hi("DiagnosticUnderlineHint",    { undercurl = true, sp = c.success })

    -- ── LSP ────────────────────────────────────────────────────────────────────
    hi("LspReferenceText",           { bg = c.surface1 })
    hi("LspReferenceRead",           { bg = c.surface1 })
    hi("LspReferenceWrite",          { bg = c.surface1 })
    hi("LspCodeLens",                { fg = c.overlay1, italic = true })
    hi("LspInlayHint",               { fg = c.overlay1, bg = c.surface0, italic = true })
    hi("LspSignatureActiveParameter",{ fg = c.primary,  bold = true, underline = true })

    -- ── Git Signs ──────────────────────────────────────────────────────────────
    hi("GitSignsAdd",                { fg = c.success, bg = c.base })
    hi("GitSignsChange",             { fg = c.info,    bg = c.base })
    hi("GitSignsDelete",             { fg = c.error,   bg = c.base })
    hi("GitSignsAddNr",              { fg = c.success })
    hi("GitSignsChangeNr",           { fg = c.info })
    hi("GitSignsDeleteNr",           { fg = c.error })

    -- ── Telescope ─────────────────────────────────────────────────────────────
    hi("TelescopeNormal",            { fg = c.text,    bg = c.base })
    hi("TelescopeBorder",            { fg = c.surface1,bg = c.base })
    hi("TelescopePromptNormal",      { fg = c.text,    bg = c.surface0 })
    hi("TelescopePromptBorder",      { fg = c.primary, bg = c.surface0 })
    hi("TelescopePromptTitle",       { fg = c.base,    bg = c.primary, bold = true })
    hi("TelescopePreviewTitle",      { fg = c.base,    bg = c.secondary, bold = true })
    hi("TelescopeResultsTitle",      { fg = c.base,    bg = c.tertiary, bold = true })
    hi("TelescopeSelection",         { fg = c.text,    bg = c.surface0 })
    hi("TelescopeSelectionCaret",    { fg = c.primary })
    hi("TelescopeMatching",          { fg = c.primary, bold = true })

    -- ── NvimTree ──────────────────────────────────────────────────────────────
    hi("NvimTreeNormal",             { fg = c.text,    bg = c.mantle })
    hi("NvimTreeFolderIcon",         { fg = c.secondary })
    hi("NvimTreeFolderName",         { fg = c.text })
    hi("NvimTreeOpenedFolderName",   { fg = c.primary, bold = true })
    hi("NvimTreeRootFolder",         { fg = c.primary, bold = true })
    hi("NvimTreeGitDirty",           { fg = c.warning })
    hi("NvimTreeGitNew",             { fg = c.success })
    hi("NvimTreeGitDeleted",         { fg = c.error })
    hi("NvimTreeSpecialFile",        { fg = c.primary, underline = true })
    hi("NvimTreeIndentMarker",       { fg = c.surface1 })
    hi("NvimTreeExecFile",           { fg = c.success, bold = true })

    -- ── Bufferline ────────────────────────────────────────────────────────────
    hi("BufferlineTabClose",         { fg = c.error })
    hi("BufferLineFill",             {                  bg = c.crust })
    hi("BufferLineBackground",       { fg = c.muted,    bg = c.mantle })
    hi("BufferLineBufferSelected",   { fg = c.text,     bold = true })
    hi("BufferLineModifiedSelected", { fg = c.warning })

    -- ── Which-Key ─────────────────────────────────────────────────────────────
    hi("WhichKey",                   { fg = c.primary })
    hi("WhichKeyGroup",              { fg = c.secondary })
    hi("WhichKeyDesc",               { fg = c.text })
    hi("WhichKeySeparator",          { fg = c.overlay0 })
    hi("WhichKeyFloat",              {                  bg = c.mantle })
    hi("WhichKeyBorder",             { fg = c.surface1 })

    -- ── Notify ────────────────────────────────────────────────────────────────
    hi("NotifyERRORBorder",          { fg = c.error })
    hi("NotifyWARNBorder",           { fg = c.warning })
    hi("NotifyINFOBorder",           { fg = c.info })
    hi("NotifyDEBUGBorder",          { fg = c.overlay1 })
    hi("NotifyTRACEBorder",          { fg = c.primary })
    hi("NotifyERRORIcon",            { fg = c.error })
    hi("NotifyWARNIcon",             { fg = c.warning })
    hi("NotifyINFOIcon",             { fg = c.info })
    hi("NotifyERRORTitle",           { fg = c.error,    bold = true })
    hi("NotifyWARNTitle",            { fg = c.warning,  bold = true })
    hi("NotifyINFOTitle",            { fg = c.info,     bold = true })

    -- ── Treesitter ────────────────────────────────────────────────────────────
    hi("@comment",                   { fg = c.overlay1, italic = true })
    hi("@comment.documentation",     { fg = c.overlay2, italic = true })
    hi("@keyword",                   { fg = c.primary,  italic = true })
    hi("@keyword.function",          { fg = c.primary,  italic = true })
    hi("@keyword.operator",          { fg = c.primary })
    hi("@keyword.return",            { fg = c.primary,  italic = true })
    hi("@keyword.import",            { fg = c.secondary })
    hi("@function",                  { fg = c.secondary,bold = true })
    hi("@function.builtin",          { fg = c.tertiary, italic = true })
    hi("@function.method",           { fg = c.secondary })
    hi("@function.call",             { fg = c.secondary })
    hi("@variable",                  { fg = c.text })
    hi("@variable.builtin",          { fg = c.error,    italic = true })
    hi("@variable.parameter",        { fg = c.subtext1, italic = true })
    hi("@variable.member",           { fg = c.text })
    hi("@string",                    { fg = c.success })
    hi("@string.escape",             { fg = c.tertiary })
    hi("@string.special",            { fg = c.tertiary })
    hi("@string.regex",              { fg = c.tertiary })
    hi("@number",                    { fg = c.tertiary })
    hi("@number.float",              { fg = c.tertiary })
    hi("@boolean",                   { fg = c.primary,  italic = true })
    hi("@constant",                  { fg = c.primary })
    hi("@constant.builtin",          { fg = c.primary,  italic = true })
    hi("@type",                      { fg = c.info,     bold = true })
    hi("@type.builtin",              { fg = c.info,     italic = true })
    hi("@type.definition",           { fg = c.info,     bold = true })
    hi("@attribute",                 { fg = c.tertiary })
    hi("@property",                  { fg = c.text })
    hi("@operator",                  { fg = c.text })
    hi("@punctuation",               { fg = c.subtext0 })
    hi("@punctuation.bracket",       { fg = c.subtext0 })
    hi("@punctuation.delimiter",     { fg = c.subtext0 })
    hi("@punctuation.special",       { fg = c.tertiary })
    hi("@tag",                       { fg = c.primary })
    hi("@tag.attribute",             { fg = c.text,     italic = true })
    hi("@tag.delimiter",             { fg = c.subtext0 })
    hi("@namespace",                 { fg = c.info })
    hi("@module",                    { fg = c.info })
    hi("@constructor",               { fg = c.info,     bold = true })
    hi("@field",                     { fg = c.text })
    hi("@label",                     { fg = c.tertiary })
    hi("@error",                     { fg = c.error })

    -- ── Completion ────────────────────────────────────────────────────────────
    hi("CmpNormal",                  { fg = c.text,     bg = c.mantle })
    hi("CmpBorder",                  { fg = c.surface1, bg = c.mantle })
    hi("CmpDocNormal",               { fg = c.text,     bg = c.mantle })
    hi("CmpDocBorder",               { fg = c.surface1, bg = c.mantle })
    hi("CmpSel",                     { fg = c.base,     bg = c.primary })
    hi("CmpGhostText",               { fg = c.overlay0, italic = true })
    hi("CmpItemAbbrMatch",           { fg = c.primary,  bold = true })
    hi("CmpItemAbbrMatchFuzzy",      { fg = c.primary })
    hi("CmpItemKindFunction",        { fg = c.secondary })
    hi("CmpItemKindVariable",        { fg = c.text })
    hi("CmpItemKindKeyword",         { fg = c.primary })
    hi("CmpItemKindClass",           { fg = c.info })
    hi("CmpItemKindModule",          { fg = c.info })
    hi("CmpItemKindText",            { fg = c.text })
    hi("CmpItemKindSnippet",         { fg = c.warning })

    -- ── DAP ───────────────────────────────────────────────────────────────────
    hi("DapBreakpoint",              { fg = c.error })
    hi("DapBreakpointCondition",     { fg = c.warning })
    hi("DapLogPoint",                { fg = c.info })
    hi("DapStopped",                 { fg = c.success,  bg = c.surface0 })
    hi("DapStoppedLine",             {                  bg = c.surface0 })

    -- ── Alpha Dashboard ────────────────────────────────────────────────────────
    hi("AlphaHeader",                { fg = c.primary })
    hi("AlphaButtons",               { fg = c.secondary })
    hi("AlphaShortcut",              { fg = c.tertiary })
    hi("AlphaFooter",                { fg = c.overlay1, italic = true })

    -- ── Indent Blankline ──────────────────────────────────────────────────────
    hi("IblIndent",                  { fg = c.surface1 })
    hi("IblScope",                   { fg = c.overlay0 })

    -- ── Noice ─────────────────────────────────────────────────────────────────
    hi("NoicePopup",                 { fg = c.text,     bg = c.mantle })
    hi("NoicePopupBorder",           { fg = c.surface1, bg = c.mantle })
    hi("NoiceCmdlinePopup",          { fg = c.text,     bg = c.surface0 })
    hi("NoiceCmdlinePopupBorder",    { fg = c.primary,  bg = c.surface0 })
    hi("NoiceCmdlinePopupTitle",     { fg = c.primary,  bold = true })
    hi("NoiceCmdlineIcon",           { fg = c.primary })
    hi("NoiceConfirmBorder",         { fg = c.secondary })
    hi("NoiceMini",                  { fg = c.text,     bg = c.surface0 })
    hi("NoiceFormatProgressDone",    { fg = c.primary,  bg = c.primary })

    -- ── FloatBorder ───────────────────────────────────────────────────────────
    hi("FloatBorder",                { fg = c.surface1, bg = c.mantle })
    hi("FloatTitle",                 { fg = c.primary,  bold = true })
    hi("FloatShadow",                {                  bg = c.crust })

    -- ── Scrollbar ─────────────────────────────────────────────────────────────
    hi("ScrollbarHandle",            {                  bg = c.surface1 })
    hi("ScrollbarThumb",             {                  bg = c.primary })

    -- Notify ASH theme applied
    vim.notify(
        "ASH Theme applied — " .. vim.fn.strftime("%H:%M:%S"),
        vim.log.levels.DEBUG,
        { title = "ASH Theme Engine" }
    )
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔄 AUTO-RELOAD CHECK
-- ═══════════════════════════════════════════════════════════════════════════════

function M.needs_update()
    local ok, stat = pcall(vim.loop.fs_stat, CACHE_FILE)
    if not ok or not stat then return false end
    return stat.mtime.sec ~= _last_mtime
end

return M