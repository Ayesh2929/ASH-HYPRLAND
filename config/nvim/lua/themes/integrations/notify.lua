-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔔 NOTIFY INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                      ║
-- ║   nvim-notify · mini.notify · snacks.notify · all levels                      ║
-- ║   Border · title · body · icon · progress · timeout animations                 ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

---Apply nvim-notify and compatible notification highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  local float_bg = p.float_bg or p.surface0

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌐 BACKGROUND
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NotifyBackground",         { bg = float_bg              })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔴 ERROR
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NotifyERRORBorder",        { fg = p.red,     bg = float_bg })
  hl(0, "NotifyERRORIcon",          { fg = p.red                    })
  hl(0, "NotifyERRORTitle",         { fg = p.red,     bold = true    })
  hl(0, "NotifyERRORBody",          { fg = p.text,    bg = float_bg  })
  hl(0, "NotifyERROR",              { fg = p.red                    })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🟡 WARN
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NotifyWARNBorder",         { fg = p.yellow,  bg = float_bg })
  hl(0, "NotifyWARNIcon",           { fg = p.yellow                 })
  hl(0, "NotifyWARNTitle",          { fg = p.yellow,  bold = true    })
  hl(0, "NotifyWARNBody",           { fg = p.text,    bg = float_bg  })
  hl(0, "NotifyWARN",               { fg = p.yellow                 })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔵 INFO
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NotifyINFOBorder",         { fg = p.blue,    bg = float_bg })
  hl(0, "NotifyINFOIcon",           { fg = p.blue                   })
  hl(0, "NotifyINFOTitle",          { fg = p.blue,    bold = true    })
  hl(0, "NotifyINFOBody",           { fg = p.text,    bg = float_bg  })
  hl(0, "NotifyINFO",               { fg = p.blue                   })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔘 DEBUG
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NotifyDEBUGBorder",        { fg = p.overlay0, bg = float_bg })
  hl(0, "NotifyDEBUGIcon",          { fg = p.overlay0               })
  hl(0, "NotifyDEBUGTitle",         { fg = p.overlay0, bold = true   })
  hl(0, "NotifyDEBUGBody",          { fg = p.text,    bg = float_bg  })
  hl(0, "NotifyDEBUG",              { fg = p.overlay0               })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔮 TRACE
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NotifyTRACEBorder",        { fg = p.mauve,   bg = float_bg })
  hl(0, "NotifyTRACEIcon",          { fg = p.mauve                  })
  hl(0, "NotifyTRACETitle",         { fg = p.mauve,   bold = true    })
  hl(0, "NotifyTRACEBody",          { fg = p.text,    bg = float_bg  })
  hl(0, "NotifyTRACE",              { fg = p.mauve                  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ✅ OK / SUCCESS (extra level)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NotifyOKBorder",           { fg = p.green,   bg = float_bg })
  hl(0, "NotifyOKIcon",             { fg = p.green                  })
  hl(0, "NotifyOKTitle",            { fg = p.green,   bold = true    })
  hl(0, "NotifyOKBody",             { fg = p.text,    bg = float_bg  })
  hl(0, "NotifyOK",                 { fg = p.green                  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎨 MINI.NOTIFY compat
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "MiniNotifyBorder",         { link = "FloatBorder"           })
  hl(0, "MiniNotifyNormal",         { link = "NormalFloat"           })
  hl(0, "MiniNotifyTitle",          { fg = p.blue,    bold = true     })
  hl(0, "MiniNotifyTitleError",     { fg = p.red,     bold = true     })
  hl(0, "MiniNotifyTitleWarn",      { fg = p.yellow,  bold = true     })
  hl(0, "MiniNotifyTitleInfo",      { fg = p.blue,    bold = true     })
  hl(0, "MiniNotifyTitleDebug",     { fg = p.overlay0, bold = true    })
  hl(0, "MiniNotifyTitleTrace",     { fg = p.mauve,   bold = true     })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🍕 SNACKS.NOTIFY compat
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "SnacksNotifierBorderError",  { fg = p.red,     bg = float_bg })
  hl(0, "SnacksNotifierBorderWarn",   { fg = p.yellow,  bg = float_bg })
  hl(0, "SnacksNotifierBorderInfo",   { fg = p.blue,    bg = float_bg })
  hl(0, "SnacksNotifierBorderDebug",  { fg = p.overlay0, bg = float_bg })
  hl(0, "SnacksNotifierBorderTrace",  { fg = p.mauve,   bg = float_bg })
  hl(0, "SnacksNotifierIconError",    { fg = p.red                    })
  hl(0, "SnacksNotifierIconWarn",     { fg = p.yellow                 })
  hl(0, "SnacksNotifierIconInfo",     { fg = p.blue                   })
  hl(0, "SnacksNotifierIconDebug",    { fg = p.overlay0               })
  hl(0, "SnacksNotifierIconTrace",    { fg = p.mauve                  })
  hl(0, "SnacksNotifierTitleError",   { fg = p.red,     bold = true    })
  hl(0, "SnacksNotifierTitleWarn",    { fg = p.yellow,  bold = true    })
  hl(0, "SnacksNotifierTitleInfo",    { fg = p.blue,    bold = true    })
  hl(0, "SnacksNotifierTitleDebug",   { fg = p.overlay0, bold = true   })
  hl(0, "SnacksNotifierTitleTrace",   { fg = p.mauve,   bold = true    })
  hl(0, "SnacksNotifierError",        { fg = p.text,    bg = float_bg  })
  hl(0, "SnacksNotifierWarn",         { fg = p.text,    bg = float_bg  })
  hl(0, "SnacksNotifierInfo",         { fg = p.text,    bg = float_bg  })
  hl(0, "SnacksNotifierDebug",        { fg = p.text,    bg = float_bg  })
  hl(0, "SnacksNotifierTrace",        { fg = p.text,    bg = float_bg  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ⏳ FIDGET (LSP progress)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "FidgetTitle",              { fg = p.blue,    bold = true      })
  hl(0, "FidgetTask",               { fg = p.overlay0                  })
  hl(0, "FidgetDone",               { fg = p.green,   bold = true      })
  hl(0, "FidgetSpinner",            { fg = p.peach,   bold = true      })
  hl(0, "FidgetAccum",              { fg = p.overlay0, italic = true   })
  hl(0, "FidgetNormal",             { link = "NormalFloat"             })
  hl(0, "FidgetWindow",             { link = "NormalFloat"             })
  hl(0, "FidgetWindowBorder",       { link = "FloatBorder"             })
  hl(0, "FidgetCount",              { fg = p.teal,    bold = true      })
  hl(0, "FidgetProg",               { fg = p.mauve                     })
  hl(0, "FidgetNotifInfo",          { fg = p.blue,    bold = true      })
  hl(0, "FidgetNotifWarn",          { fg = p.yellow,  bold = true      })
  hl(0, "FidgetNotifError",         { fg = p.red,     bold = true      })
  hl(0, "FidgetNotifDebug",         { fg = p.overlay0                  })
  hl(0, "FidgetNotifTrace",         { fg = p.mauve                     })
end

return M