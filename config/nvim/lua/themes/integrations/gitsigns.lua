-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       󰊢 GITSIGNS INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                    ║
-- ║   Sign column · line highlights · inline word diff · blame · staged            ║
-- ║   All sign variants · number column · preview · ASH palette-synced            ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

---Apply Gitsigns highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📌 SIGN COLUMN — gutter icons
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "GitSignsAdd",              { fg = p.green,   bold = false })
  hl(0, "GitSignsChange",           { fg = p.yellow,  bold = false })
  hl(0, "GitSignsDelete",           { fg = p.red,     bold = false })
  hl(0, "GitSignsTopdelete",        { fg = p.red,     bold = false })
  hl(0, "GitSignsChangedelete",     { fg = p.yellow,  bold = false })
  hl(0, "GitSignsUntracked",        { fg = p.blue                  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔢 NUMBER COLUMN — numhl variants
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "GitSignsAddNr",            { fg = p.green,   bold = true  })
  hl(0, "GitSignsChangeNr",         { fg = p.yellow,  bold = true  })
  hl(0, "GitSignsDeleteNr",         { fg = p.red,     bold = true  })
  hl(0, "GitSignsTopdeleteNr",      { fg = p.red,     bold = true  })
  hl(0, "GitSignsChangedeleteNr",   { fg = p.yellow,  bold = true  })
  hl(0, "GitSignsUntrackedNr",      { fg = p.blue,    bold = true  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📄 LINE HIGHLIGHT — linehl variants (bg for entire line)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "GitSignsAddLn",            { bg = p.diff_add    or p.surface0 })
  hl(0, "GitSignsChangeLn",         { bg = p.diff_change or p.surface0 })
  hl(0, "GitSignsDeleteLn",         { bg = p.diff_delete or p.surface0 })
  hl(0, "GitSignsTopdeleteVirtLnum",{ bg = p.diff_delete or p.surface0 })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📝 STAGED VARIANTS — show staged (indexed) state differently
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "GitSignsStagedAdd",        { fg = p.green,  italic = true })
  hl(0, "GitSignsStagedChange",     { fg = p.yellow, italic = true })
  hl(0, "GitSignsStagedDelete",     { fg = p.red,    italic = true })
  hl(0, "GitSignsStagedTopdelete",  { fg = p.red,    italic = true })
  hl(0, "GitSignsStagedChangedelete",{ fg = p.yellow,italic = true })

  hl(0, "GitSignsStagedAddNr",      { fg = p.green,  bold = true, italic = true })
  hl(0, "GitSignsStagedChangeNr",   { fg = p.yellow, bold = true, italic = true })
  hl(0, "GitSignsStagedDeleteNr",   { fg = p.red,    bold = true, italic = true })

  hl(0, "GitSignsStagedAddLn",      { bg = p.diff_add    or p.surface0 })
  hl(0, "GitSignsStagedChangeLn",   { bg = p.diff_change or p.surface0 })
  hl(0, "GitSignsStagedDeleteLn",   { bg = p.diff_delete or p.surface0 })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 💬 INLINE WORD DIFF — character-level highlights
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "GitSignsAddInline",        {
    fg   = p.base,
    bg   = p.green,
    bold = true,
  })
  hl(0, "GitSignsChangeInline",     {
    fg   = p.base,
    bg   = p.yellow,
    bold = true,
  })
  hl(0, "GitSignsDeleteInline",     {
    fg   = p.base,
    bg   = p.red,
    bold = true,
  })
  hl(0, "GitSignsAddVirtLnum",      { fg = p.green,   bold = true  })
  hl(0, "GitSignsDeleteVirtLnum",   { fg = p.red,     bold = true  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔍 PREVIEW WINDOW
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "GitSignsAddPreview",       { link = "DiffAdd"                           })
  hl(0, "GitSignsDeletePreview",    { link = "DiffDelete"                        })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 👁️  CURRENT LINE BLAME — inline git blame virtual text
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "GitSignsCurrentLineBlame", {
    fg     = p.overlay0,
    italic = true,
  })
  hl(0, "GitSignsCurrentLineBlameNC", {
    fg     = p.surface2,
    italic = true,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔀 DIFF VIEWS (Diffview.nvim compat)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DiffAdd",                  { bg = p.diff_add    or p.surface0            })
  hl(0, "DiffChange",               { bg = p.diff_change or p.surface0            })
  hl(0, "DiffDelete",               { bg = p.diff_delete or p.surface0            })
  hl(0, "DiffText",                 { bg = p.diff_text   or p.surface0            })
  hl(0, "Added",                    { fg = p.green                                })
  hl(0, "Changed",                  { fg = p.yellow                               })
  hl(0, "Removed",                  { fg = p.red                                  })

  -- Diffview
  hl(0, "DiffviewStatusAdded",      { fg = p.green                                })
  hl(0, "DiffviewStatusModified",   { fg = p.yellow                               })
  hl(0, "DiffviewStatusDeleted",    { fg = p.red                                  })
  hl(0, "DiffviewStatusRenamed",    { fg = p.teal                                 })
  hl(0, "DiffviewStatusUntracked",  { fg = p.overlay0                             })
  hl(0, "DiffviewStatusIgnored",    { fg = p.overlay0                             })
  hl(0, "DiffviewStatusConflict",   { fg = p.red,     bold = true                 })
  hl(0, "DiffviewFilePanelTitle",   { fg = p.blue,    bold = true                 })
  hl(0, "DiffviewFilePanelRootPath",{ fg = p.overlay0, italic = true              })
  hl(0, "DiffviewFilePanelCounter", { fg = p.peach,   bold = true                 })
  hl(0, "DiffviewFilePanelInsertions", { fg = p.green                             })
  hl(0, "DiffviewFilePanelDeletions", { fg = p.red                                })
  hl(0, "DiffviewReference",        { fg = p.teal                                 })
  hl(0, "DiffviewPrimary",          { fg = p.blue                                 })
  hl(0, "DiffviewSecondary",        { fg = p.teal                                 })
  hl(0, "DiffviewNormal",           { link = "NormalFloat"                        })
  hl(0, "DiffviewCursorLine",       { link = "CursorLine"                         })
  hl(0, "DiffviewWinSeparator",     { link = "WinSeparator"                       })
  hl(0, "DiffviewHash",             { fg = p.overlay0, italic = true              })
  hl(0, "DiffviewSignColumn",       { link = "SignColumn"                         })

  -- Neogit
  hl(0, "NeogitBranch",             { fg = p.blue,    bold = true                 })
  hl(0, "NeogitBranchHead",         { fg = p.green,   bold = true, underline = true })
  hl(0, "NeogitRemote",             { fg = p.mauve,   bold = true                 })
  hl(0, "NeogitDiffAdd",            { link = "DiffAdd"                            })
  hl(0, "NeogitDiffDelete",         { link = "DiffDelete"                         })
  hl(0, "NeogitDiffContext",        { link = "Normal"                             })
  hl(0, "NeogitHunkHeader",         { fg = p.base, bg = p.blue, bold = true       })
  hl(0, "NeogitHunkHeaderHighlight",{ fg = p.base, bg = p.sapphire, bold = true   })
  hl(0, "NeogitChangeAdded",        { fg = p.green,   italic = true               })
  hl(0, "NeogitChangeModified",     { fg = p.yellow,  italic = true               })
  hl(0, "NeogitChangeDeleted",      { fg = p.red,     italic = true               })
  hl(0, "NeogitChangeRenamed",      { fg = p.teal,    italic = true               })
  hl(0, "NeogitChangeUntracked",    { fg = p.overlay0, italic = true              })
  hl(0, "NeogitChangeUnmerged",     { fg = p.red,     bold = true                 })
  hl(0, "NeogitStagedChanges",      { fg = p.green,   bold = true                 })
  hl(0, "NeogitUnstagedChanges",    { fg = p.yellow,  bold = true                 })
  hl(0, "NeogitUnpulledFrom",       { fg = p.blue,    bold = true                 })
  hl(0, "NeogitUnmergedInto",       { fg = p.mauve,   bold = true                 })
  hl(0, "NeogitTag",                { fg = p.yellow,  bold = true                 })
  hl(0, "NeogitHash",               { fg = p.overlay0, italic = true              })
  hl(0, "NeogitGraphBlue",          { fg = p.blue                                 })
  hl(0, "NeogitGraphGreen",         { fg = p.green                                })
  hl(0, "NeogitGraphRed",           { fg = p.red                                  })
  hl(0, "NeogitGraphYellow",        { fg = p.yellow                               })
  hl(0, "NeogitGraphMagenta",       { fg = p.mauve                                })
  hl(0, "NeogitGraphCyan",          { fg = p.teal                                 })
  hl(0, "NeogitGraphWhite",         { fg = p.text                                 })
  hl(0, "NeogitGraphGray",          { fg = p.overlay0                             })
end

return M