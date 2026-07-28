-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       💬 NOICE INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                       ║
-- ║   Command line · popup · messages · confirmation · LSP progress               ║
-- ║   Markdown renderer · cmdline icons · scroll bar · ASH glass style            ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

---Apply Noice highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  local float_bg = p.float_bg or p.surface0

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🖥️  CMDLINE POPUP
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NoiceCmdlinePopup",        { fg = p.text,    bg = p.surface0           })
  hl(0, "NoiceCmdlinePopupBorder",  { fg = p.blue,    bg = p.surface0           })
  hl(0, "NoiceCmdlinePopupTitle",   { fg = p.base,    bg = p.blue,  bold = true })

  -- Cmdline icons per command type
  hl(0, "NoiceCmdlineIcon",         { fg = p.blue                               })
  hl(0, "NoiceCmdlineIconSearch",   { fg = p.yellow                             })
  hl(0, "NoiceCmdlineIconLua",      { fg = p.teal                               })
  hl(0, "NoiceCmdlineIconInput",    { fg = p.mauve                              })
  hl(0, "NoiceCmdlineIconFilter",   { fg = p.peach                              })
  hl(0, "NoiceCmdlineIconHelp",     { fg = p.green                              })
  hl(0, "NoiceCmdlineIconCmdline",  { fg = p.blue                               })

  -- Cmdline prompt text
  hl(0, "NoiceCmdlinePrompt",       { fg = p.blue,    bold = true               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ✅ CONFIRM DIALOG
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NoiceConfirm",             { fg = p.text,    bg = p.surface0           })
  hl(0, "NoiceConfirmBorder",       { fg = p.yellow,  bg = p.surface0           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📨 MESSAGES / POPUPMENU
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NoicePopupmenu",           { fg = p.text,    bg = float_bg             })
  hl(0, "NoicePopupmenuBorder",     { fg = p.border or p.surface1, bg = float_bg })
  hl(0, "NoicePopupmenuSelected",   { fg = p.base,    bg = p.blue               })
  hl(0, "NoicePopupmenuMatch",      { fg = p.yellow,  bold = true               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📜 SCROLLBAR
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NoiceScrollbar",           { bg = p.surface1                           })
  hl(0, "NoiceScrollbarThumb",      { bg = p.overlay0                           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔔 NOTIFICATION KINDS (embedded in noice)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NoiceError",               { fg = p.red,     bold = true               })
  hl(0, "NoiceWarn",                { fg = p.yellow                             })
  hl(0, "NoiceInfo",                { fg = p.blue                               })
  hl(0, "NoiceDebug",               { fg = p.overlay0                           })
  hl(0, "NoiceTrace",               { fg = p.mauve                              })
  hl(0, "NoiceSuccess",             { fg = p.green,   bold = true               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔬 LSP PROGRESS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NoiceLspProgressTitle",    { fg = p.text,    bold = true               })
  hl(0, "NoiceLspProgressClient",   { fg = p.blue,    italic = true             })
  hl(0, "NoiceLspProgressSpinner",  { fg = p.peach,   bold = true               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🖊️  VIRTUAL TEXT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NoiceVirtualText",         { fg = p.overlay0, italic = true            })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📝 FORMAT GROUPS (used in message rendering)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NoiceFormatTitle",         { fg = p.blue,    bold = true               })
  hl(0, "NoiceFormatEvent",         { fg = p.mauve,   italic = true             })
  hl(0, "NoiceFormatKind",          { fg = p.yellow                             })
  hl(0, "NoiceFormatDate",          { fg = p.overlay0, italic = true            })
  hl(0, "NoiceFormatLevelTrace",    { fg = p.mauve                              })
  hl(0, "NoiceFormatLevelDebug",    { fg = p.overlay0                           })
  hl(0, "NoiceFormatLevelInfo",     { fg = p.blue                               })
  hl(0, "NoiceFormatLevelWarn",     { fg = p.yellow                             })
  hl(0, "NoiceFormatLevelError",    { fg = p.red,     bold = true               })
  hl(0, "NoiceFormatLevelOff",      { fg = p.surface2                           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📖 MARKDOWN RENDERING (noice renders markdown in messages)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NoiceMarkdownCode",        { fg = p.teal,    bg = p.surface0           })
  hl(0, "NoiceMarkdownCodeBlock",   { bg = p.surface0                           })
  hl(0, "NoiceMarkdownHrule",       { fg = p.surface1                           })
  hl(0, "NoiceMarkdownH1",          { fg = p.blue,    bold = true               })
  hl(0, "NoiceMarkdownH2",          { fg = p.green,   bold = true               })
  hl(0, "NoiceMarkdownH3",          { fg = p.yellow,  bold = true               })
  hl(0, "NoiceMarkdownH4",          { fg = p.red,     bold = true               })
  hl(0, "NoiceMarkdownH5",          { fg = p.mauve,   bold = true               })
  hl(0, "NoiceMarkdownH6",          { fg = p.teal,    bold = true               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  MINI-CURSOR (search mode indicator)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NoiceMini",                { fg = p.text,    bg = p.surface0           })
  hl(0, "NoiceMiniWarning",         { fg = p.yellow,  bg = p.surface0           })
  hl(0, "NoiceMiniInfo",            { fg = p.blue,    bg = p.surface0           })
  hl(0, "NoiceMiniError",           { fg = p.red,     bg = p.surface0           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔭 TELESCOPE INTEGRATION (noice shows telescope-style menus)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NoiceCompletionListMatch",  { fg = p.yellow, bold = true               })
  hl(0, "NoiceCompletionItemMenu",   {
    fg     = p.overlay0,
    italic = true,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🍕 SNACKS compat
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  -- Snacks Input (used as replacement for vim.ui.input)
  hl(0, "SnacksInputNormal",        { fg = p.text,    bg = p.surface0           })
  hl(0, "SnacksInputBorder",        { fg = p.blue,    bg = p.surface0           })
  hl(0, "SnacksInputTitle",         { fg = p.base,    bg = p.blue,  bold = true })
  hl(0, "SnacksInputIcon",          { fg = p.blue                               })

  -- Snacks Picker (used as replacement for vim.ui.select)
  hl(0, "SnacksPickerNormal",       { fg = p.text,    bg = float_bg             })
  hl(0, "SnacksPickerBorder",       { fg = p.border or p.surface1, bg = float_bg })
  hl(0, "SnacksPickerTitle",        { fg = p.base,    bg = p.blue,  bold = true })
  hl(0, "SnacksPickerSearch",       { fg = p.text,    bg = p.surface0           })
  hl(0, "SnacksPickerSearchBorder", { fg = p.surface0, bg = p.surface0          })
  hl(0, "SnacksPickerPreview",      { link = "NormalFloat"                      })
  hl(0, "SnacksPickerPreviewBorder",{ link = "FloatBorder"                      })
  hl(0, "SnacksPickerSelection",    { fg = p.text,    bg = p.surface1           })
  hl(0, "SnacksPickerMatch",        { fg = p.yellow,  bold = true               })
  hl(0, "SnacksPickerDir",          { fg = p.overlay0, italic = true            })
  hl(0, "SnacksPickerFile",         { fg = p.text                               })
  hl(0, "SnacksPickerCount",        { fg = p.overlay0, italic = true            })
  hl(0, "SnacksPickerKeymapTitle",  { fg = p.base,    bg = p.blue,  bold = true })

  -- Snacks Dashboard
  hl(0, "SnacksDashboardNormal",    { link = "Normal"                           })
  hl(0, "SnacksDashboardBorder",    { link = "FloatBorder"                      })
  hl(0, "SnacksDashboardTitle",     { fg = p.blue,    bold = true               })
  hl(0, "SnacksDashboardHeader",    { fg = p.mauve,   bold = true               })
  hl(0, "SnacksDashboardFooter",    { fg = p.overlay0, italic = true            })
  hl(0, "SnacksDashboardKey",       { fg = p.yellow,  bold = true               })
  hl(0, "SnacksDashboardIcon",      { fg = p.blue                               })
  hl(0, "SnacksDashboardDesc",      { fg = p.text                               })
  hl(0, "SnacksDashboardDir",       { fg = p.overlay0, italic = true            })
  hl(0, "SnacksDashboardSection",   { fg = p.blue,    bold = true               })
  hl(0, "SnacksDashboardSpecial",   { fg = p.mauve                              })
  hl(0, "SnacksDashboardTerminal",  { fg = p.text,    bg = p.base               })

  -- Snacks Scroll / Float
  hl(0, "SnacksNormal",             { link = "NormalFloat"                      })
  hl(0, "SnacksBorder",             { link = "FloatBorder"                      })
  hl(0, "SnacksBackdrop",           { bg = p.base,    blend = 40                })
  hl(0, "SnacksZenBar",             { fg = p.surface1, bg = p.base              })
  hl(0, "SnacksScrollbar",          { bg = p.surface1                           })
  hl(0, "SnacksScrollbarThumb",     { bg = p.overlay0                           })

  -- Snacks Indent
  hl(0, "SnacksIndent",             { fg = p.surface1                           })
  hl(0, "SnacksIndentScope",        { fg = p.overlay0                           })
  hl(0, "SnacksIndentChunk",        { fg = p.blue                               })

  -- Snacks animate (word / line diff)
  hl(0, "SnacksAnimateCursor",      { reverse = true                            })
  hl(0, "SnacksAnimateFloat",       { link = "NormalFloat"                      })

  -- Dressing.nvim compat (vim.ui.input / vim.ui.select)
  hl(0, "DressingNormal",           { link = "NormalFloat"                      })
  hl(0, "DressingBorder",           { link = "FloatBorder"                      })
  hl(0, "DressingInputNormal",      { fg = p.text,    bg = p.surface0           })
  hl(0, "DressingInputBorder",      { fg = p.blue,    bg = p.surface0           })
  hl(0, "DressingSelectNormal",     { fg = p.text,    bg = float_bg             })
  hl(0, "DressingSelectBorder",     { fg = p.border or p.surface1, bg = float_bg })
  hl(0, "DressingTitle",            { fg = p.blue,    bold = true               })
  hl(0, "DressingPrompt",           { fg = p.blue,    bold = true               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🪟 NUI.NVIM compat (used by noice, avante, etc.)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NuiPopupNormal",           { link = "NormalFloat"                      })
  hl(0, "NuiPopupBorder",           { link = "FloatBorder"                      })
  hl(0, "NuiBorderText",            { fg = p.blue,    bold = true               })
end

return M