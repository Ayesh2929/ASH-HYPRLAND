-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🗺️  WHICH-KEY INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                  ║
-- ║   Popup window · key groups · descriptions · separators · icons               ║
-- ║   Normal / visual / operator modes · float styling · ASH glass UI             ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

---Apply which-key highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🪟 FLOAT WINDOW
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "WhichKeyFloat",            {
    fg   = p.text,
    bg   = p.float_bg or p.surface0,
  })
  hl(0, "WhichKeyBorder",          {
    fg   = p.border  or p.surface1,
    bg   = p.float_bg or p.surface0,
  })
  hl(0, "WhichKeyTitle",           {
    fg   = p.blue,
    bold = true,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔑 KEY BINDINGS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- The key itself (e.g. "<leader>f")
  hl(0, "WhichKey",                {
    fg   = p.teal,
    bold = true,
  })
  -- Operator mode key
  hl(0, "WhichKeyOperator",        {
    fg   = p.peach,
    bold = true,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📁 GROUP LABELS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- Group prefix label (e.g. "+Find")
  hl(0, "WhichKeyGroup",           {
    fg     = p.blue,
    bold   = true,
    italic = false,
  })
  -- Group icon if using nerd fonts
  hl(0, "WhichKeyIcon",            {
    fg   = p.blue,
    bold = true,
  })
  -- Nested group
  hl(0, "WhichKeyNorm",            {
    fg   = p.overlay0,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📝 DESCRIPTION TEXT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "WhichKeyDesc",            {
    fg   = p.text,
  })
  -- Description for a group (greyed)
  hl(0, "WhichKeyGroupDesc",       {
    fg     = p.subtext0,
    italic = true,
  })
  -- Description for a key that has no mapping set
  hl(0, "WhichKeyMute",            {
    fg   = p.overlay0,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ➕ SEPARATOR
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "WhichKeySeparator",       {
    fg   = p.surface2,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 💡 VALUE COLUMN (shows current value for toggles)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "WhichKeyValue",           {
    fg     = p.overlay1,
    italic = true,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎨 ICON COLOURS BY CATEGORY — which-key v3 icon system
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- which-key v3 uses WhichKeyIconAzure, WhichKeyIconBlue, etc.
  hl(0, "WhichKeyIconAzure",       { fg = "#7aa2f7" })
  hl(0, "WhichKeyIconBlue",        { fg = p.blue    })
  hl(0, "WhichKeyIconCyan",        { fg = p.teal    })
  hl(0, "WhichKeyIconGreen",       { fg = p.green   })
  hl(0, "WhichKeyIconGrey",        { fg = p.overlay0 })
  hl(0, "WhichKeyIconOrange",      { fg = p.peach   })
  hl(0, "WhichKeyIconPurple",      { fg = p.mauve   })
  hl(0, "WhichKeyIconRed",         { fg = p.red     })
  hl(0, "WhichKeyIconYellow",      { fg = p.yellow  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🖊️  HIGHLIGHTED KEYS (current trigger sequence)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "WhichKeyBracketed",       {
    fg   = p.yellow,
    bold = true,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📋 CLUE (mini.clue compat)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "MiniClueBorder",              { link = "WhichKeyBorder"    })
  hl(0, "MiniClueDescGroup",           { fg = p.blue,   bold = true  })
  hl(0, "MiniClueDescSingle",          { fg = p.text                })
  hl(0, "MiniClueNextKey",             { fg = p.teal,   bold = true  })
  hl(0, "MiniClueNextKeyWithPostkeys", { fg = p.yellow, bold = true  })
  hl(0, "MiniClueSeparator",           { fg = p.surface2             })
  hl(0, "MiniClueTitle",               { fg = p.blue,   bold = true  })
end

return M