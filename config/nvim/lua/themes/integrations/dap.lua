-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐛 DAP INTEGRATION — ASH THEME ENGINE v5.0 OMEGA                         ║
-- ║   Breakpoints · stopped · logpoints · rejected · DAP UI panel                 ║
-- ║   Virtual text · step indicators · all sign types · ASH premium colours       ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- Premium Nerd Font v3 DAP icons
local DAP_SIGNS = {
  DapBreakpoint          = { text = " ",  hl = "DapBreakpoint",          priority = 11 },
  DapBreakpointCondition = { text = " ",  hl = "DapBreakpointCondition", priority = 11 },
  DapBreakpointRejected  = { text = " ",  hl = "DapBreakpointRejected",  priority = 11 },
  DapLogPoint            = { text = "󰐍 ", hl = "DapLogPoint",            priority = 11 },
  DapStopped             = {
    text   = "󰁕 ",
    hl     = "DapStopped",
    linehl = "DapStoppedLine",
    numhl  = "DapStopped",
    priority = 20,
  },
}

local function register_signs()
  for name, cfg in pairs(DAP_SIGNS) do
    vim.fn.sign_define(name, {
      text     = cfg.text,
      texthl   = cfg.hl,
      linehl   = cfg.linehl or "",
      numhl    = cfg.numhl  or "",
      priority = cfg.priority,
    })
  end
end

---Apply DAP highlight groups
---@param p table ASH palette
function M.apply(p)
  local hl = vim.api.nvim_set_hl

  register_signs()

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📌 SIGN COLUMN INDICATORS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DapBreakpoint",            { fg = p.red,    bold = true              })
  hl(0, "DapBreakpointCondition",   { fg = p.yellow, bold = true              })
  hl(0, "DapBreakpointRejected",    { fg = p.overlay0                         })
  hl(0, "DapLogPoint",              { fg = p.blue,   bold = true              })
  hl(0, "DapStopped",               {
    fg   = p.green,
    bold = true,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📄 LINE HIGHLIGHTS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DapStoppedLine",           {
    bg   = p.diff_add or p.surface0,
  })
  hl(0, "DapBreakpointLine",        {
    bg   = p.error_bg or p.surface0,
  })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🪟 DAP-UI PANEL
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DapUiNormal",              { link = "NormalFloat"                    })
  hl(0, "DapUiNormalNC",            { link = "NormalFloat"                    })
  hl(0, "DapUiBorder",              { link = "FloatBorder"                    })
  hl(0, "DapUiFloatBorder",         { link = "FloatBorder"                    })
  hl(0, "DapUiFloatNormal",         { link = "NormalFloat"                    })
  hl(0, "DapUiWinSelect",           { fg = p.blue,   bold = true              })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📊 VARIABLE / SCOPE DISPLAY
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DapUiScope",               { fg = p.mauve,  bold = true              })
  hl(0, "DapUiType",                { fg = p.teal,   italic = true            })
  hl(0, "DapUiVariable",            { fg = p.text                             })
  hl(0, "DapUiValue",               { fg = p.green                            })
  hl(0, "DapUiModifiedValue",       { fg = p.yellow, bold = true              })
  hl(0, "DapUiDecoration",          { fg = p.overlay0                         })
  hl(0, "DapUiIndentGuide",         { fg = p.surface2                         })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🧵 THREADS & FRAMES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DapUiThread",              { fg = p.blue                             })
  hl(0, "DapUiFrameName",           { fg = p.text                             })
  hl(0, "DapUiCurrentFrame",        { fg = p.green,  bold = true              })
  hl(0, "DapUiSource",              { fg = p.overlay0, italic = true          })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔴 BREAKPOINTS IN PANEL
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DapUiBreakpointLine",      { fg = p.red                              })
  hl(0, "DapUiBreakpointVerified",  { fg = p.red,    bold = true              })
  hl(0, "DapUiBreakpointEnabled",   { fg = p.red                              })
  hl(0, "DapUiBreakpointDisabled",  { fg = p.overlay0                         })
  hl(0, "DapUiBreakpointLogMessage",{ fg = p.blue                             })
  hl(0, "DapUiBreakpointCondition", { fg = p.yellow                           })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  CONTROL BUTTONS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DapUiPlayPause",           { fg = p.green,  bold = true              })
  hl(0, "DapUiPlayPauseNC",         { fg = p.green                            })
  hl(0, "DapUiRestart",             { fg = p.blue,   bold = true              })
  hl(0, "DapUiRestartNC",           { fg = p.blue                             })
  hl(0, "DapUiStop",                { fg = p.red,    bold = true              })
  hl(0, "DapUiStopNC",              { fg = p.red                              })
  hl(0, "DapUiDisconnect",          { fg = p.yellow, bold = true              })
  hl(0, "DapUiDisconnectNC",        { fg = p.yellow                           })
  hl(0, "DapUiStepOver",            { fg = p.mauve,  bold = true              })
  hl(0, "DapUiStepOverNC",          { fg = p.mauve                            })
  hl(0, "DapUiStepInto",            { fg = p.teal,   bold = true              })
  hl(0, "DapUiStepIntoNC",          { fg = p.teal                             })
  hl(0, "DapUiStepOut",             { fg = p.overlay0, bold = true            })
  hl(0, "DapUiStepOutNC",           { fg = p.overlay0                         })
  hl(0, "DapUiStepBack",            { fg = p.text,   bold = true              })
  hl(0, "DapUiStepBackNC",          { fg = p.text                             })
  hl(0, "DapUiRunLast",             { fg = p.peach,  bold = true              })
  hl(0, "DapUiRunLastNC",           { fg = p.peach                            })
  hl(0, "DapUiToggleBreakpoint",    { fg = p.red,    bold = true              })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 👁️  VIRTUAL TEXT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "NvimDapVirtualText",       { fg = p.overlay0, italic = true          })
  hl(0, "NvimDapVirtualTextChanged",{ fg = p.yellow,   bold = true, italic = true })
  hl(0, "NvimDapVirtualTextError",  { fg = p.red,      italic = true          })
  hl(0, "NvimDapVirtualTextInfo",   { fg = p.blue,     italic = true          })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 👁️  WATCHES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DapUiWatchesEmpty",        { fg = p.overlay0, italic = true          })
  hl(0, "DapUiWatchesError",        { fg = p.red                              })
  hl(0, "DapUiWatchesValue",        { fg = p.green                            })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 💬 CONSOLE / REPL
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DapUiConsoleNormal",       { link = "NormalFloat"                    })
  hl(0, "DapUiConsoleInput",        { fg = p.text                             })
  hl(0, "DapUiConsoleOutput",       { fg = p.green                            })
  hl(0, "DapUiConsoleError",        { fg = p.red                              })
  hl(0, "DapReplNormal",            { link = "NormalFloat"                    })
  hl(0, "DapReplBorder",            { link = "FloatBorder"                    })

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📊 STATUS INDICATORS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hl(0, "DapStatusRunning",         { fg = p.green,  bold = true              })
  hl(0, "DapStatusStopped",         { fg = p.yellow, bold = true              })
  hl(0, "DapStatusPaused",          { fg = p.blue,   bold = true              })
  hl(0, "DapStatusError",           { fg = p.red,    bold = true              })
  hl(0, "DapStatusExited",          { fg = p.overlay0                         })
end

return M