-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🖥️  DAP-UI — ULTRA DEBUG INTERFACE v5.0 OMEGA                            ║
-- ║   Split-panel debugging UI · scopes · watches · stacks · console · REPL       ║
-- ║   animated open/close · resizable · ASH theme-synced glassmorphism             ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — ASH glassmorphism debug UI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Panel chrome ──────────────────────────────────────────────────────────
    hl(0, "DapUiNormal",              { link = "NormalFloat"              })
    hl(0, "DapUiNormalNC",            { link = "NormalFloat"              })
    hl(0, "DapUiBorder",              { link = "FloatBorder"              })
    hl(0, "DapUiFloatBorder",         { link = "FloatBorder"              })
    hl(0, "DapUiFloatNormal",         { link = "NormalFloat"              })
  
    -- ── Section headers ───────────────────────────────────────────────────────
    hl(0, "DapUiHeader",              { bold = true, fg = "#7aa2f7"       })
  
    -- ── Variable / value display ──────────────────────────────────────────────
    hl(0, "DapUiDecoration",          { fg = "#9399b2"                    })
    hl(0, "DapUiIndentGuide",         { fg = "#313244"                    })
    hl(0, "DapUiScope",               { bold = true, fg = "#bb9af7"       })
    hl(0, "DapUiType",                { italic = true, fg = "#94e2d5"     })
    hl(0, "DapUiVariable",            { fg = "#cdd6f4"                    })
    hl(0, "DapUiValue",               { fg = "#a6e3a1"                    })
    hl(0, "DapUiModifiedValue",       { bold = true, fg = "#f9e2af"       })
  
    -- ── Stack frames ──────────────────────────────────────────────────────────
    hl(0, "DapUiThread",              { fg = "#7aa2f7"                    })
    hl(0, "DapUiFrameName",           { fg = "#cdd6f4"                    })
    hl(0, "DapUiCurrentFrame",        { bold = true, fg = "#9ece6a"       })
    hl(0, "DapUiSource",              { italic = true, fg = "#9399b2"     })
  
    -- ── Breakpoints list ─────────────────────────────────────────────────────
    hl(0, "DapUiBreakpointLine",      { fg = "#f38ba8"                    })
    hl(0, "DapUiBreakpointVerified",  { bold = true, fg = "#f38ba8"       })
    hl(0, "DapUiBreakpointEnabled",   { fg = "#f38ba8"                    })
    hl(0, "DapUiBreakpointDisabled",  { fg = "#9399b2"                    })
    hl(0, "DapUiBreakpointLogMessage",{ fg = "#89b4fa"                    })
    hl(0, "DapUiBreakpointCondition", { fg = "#f9e2af"                    })
  
    -- ── Buttons / controls ───────────────────────────────────────────────────
    hl(0, "DapUiPlayPauseNC",         { fg = "#9ece6a"                    })
    hl(0, "DapUiRestartNC",           { fg = "#89b4fa"                    })
    hl(0, "DapUiStopNC",              { fg = "#f38ba8"                    })
    hl(0, "DapUiDisconnectNC",        { fg = "#f9e2af"                    })
    hl(0, "DapUiStepOverNC",          { fg = "#cba6f7"                    })
    hl(0, "DapUiStepIntoNC",          { fg = "#94e2d5"                    })
    hl(0, "DapUiStepBackNC",          { fg = "#cdd6f4"                    })
    hl(0, "DapUiStepOutNC",           { fg = "#9399b2"                    })
  
    -- Active button variants (cursor is on them)
    hl(0, "DapUiPlayPause",           { bold = true, fg = "#9ece6a"       })
    hl(0, "DapUiRestart",             { bold = true, fg = "#89b4fa"       })
    hl(0, "DapUiStop",                { bold = true, fg = "#f38ba8"       })
    hl(0, "DapUiDisconnect",          { bold = true, fg = "#f9e2af"       })
    hl(0, "DapUiStepOver",            { bold = true, fg = "#cba6f7"       })
    hl(0, "DapUiStepInto",            { bold = true, fg = "#94e2d5"       })
    hl(0, "DapUiStepBack",            { bold = true, fg = "#cdd6f4"       })
    hl(0, "DapUiStepOut",             { bold = true, fg = "#9399b2"       })
  
    -- ── Console / REPL ───────────────────────────────────────────────────────
    hl(0, "DapUiConsoleInput",        { bg = "#1e2030", fg = "#cdd6f4"    })
    hl(0, "DapUiConsoleOutput",       { fg = "#a6e3a1"                    })
    hl(0, "DapUiConsoleError",        { fg = "#f38ba8"                    })
  
    -- ── Watches ───────────────────────────────────────────────────────────────
    hl(0, "DapUiWatchesEmpty",        { italic = true, fg = "#9399b2"     })
    hl(0, "DapUiWatchesError",        { fg = "#f38ba8"                    })
    hl(0, "DapUiWatchesValue",        { fg = "#a6e3a1"                    })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue    then hl(0, "DapUiHeader",        { bold = true, fg = p.blue   }) end
      if p.mauve   then hl(0, "DapUiScope",         { bold = true, fg = p.mauve  }) end
      if p.teal    then hl(0, "DapUiType",          { italic = true, fg = p.teal }) end
      if p.text    then hl(0, "DapUiVariable",      { fg = p.text                }) end
      if p.green   then
        hl(0, "DapUiValue",            { fg = p.green })
        hl(0, "DapUiCurrentFrame",     { bold = true, fg = p.green })
        hl(0, "DapUiPlayPause",        { bold = true, fg = p.green })
        hl(0, "DapUiPlayPauseNC",      { fg = p.green })
      end
      if p.yellow  then
        hl(0, "DapUiModifiedValue",    { bold = true, fg = p.yellow })
        hl(0, "DapUiBreakpointCondition", { fg = p.yellow })
      end
      if p.red     then
        hl(0, "DapUiBreakpointVerified", { bold = true, fg = p.red })
        hl(0, "DapUiStop",               { bold = true, fg = p.red })
      end
      if p.blue    then
        hl(0, "DapUiThread",           { fg = p.blue })
        hl(0, "DapUiBreakpointLogMessage", { fg = p.blue })
      end
      local dim = p.overlay0 or "#9399b2"
      hl(0, "DapUiDecoration",  { fg = dim })
      hl(0, "DapUiSource",      { italic = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART TOGGLE
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local _dapui_open = false
  
  local function toggle_dapui()
    local ok, dapui = pcall(require, "dapui")
    if not ok then return end
  
    if _dapui_open then
      dapui.close()
      _dapui_open = false
      vim.notify(
        "🖥️  DAP UI closed",
        vim.log.levels.INFO,
        { title = "DAP UI", timeout = 1000 }
      )
    else
      dapui.open()
      _dapui_open = true
      vim.notify(
        "🖥️  DAP UI opened",
        vim.log.levels.INFO,
        { title = "DAP UI", timeout = 1000 }
      )
    end
  end
  
  local function toggle_dapui_layout(idx)
    return function()
      local ok, dapui = pcall(require, "dapui")
      if ok then dapui.toggle({ layout = idx }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "rcarriga/nvim-dap-ui",
      dependencies = {
        "mfussenegger/nvim-dap",
        "nvim-neotest/nvim-nio",
      },
      event = "VeryLazy",
  
      keys = {
        {
          "<leader>du",
          toggle_dapui,
          desc   = "🖥️  DAP UI: Toggle",
          silent = true,
        },
        {
          "<leader>d1",
          toggle_dapui_layout(1),
          desc   = "🖥️  DAP UI: Toggle sidebar",
          silent = true,
        },
        {
          "<leader>d2",
          toggle_dapui_layout(2),
          desc   = "🖥️  DAP UI: Toggle bottom panel",
          silent = true,
        },
        {
          "<leader>de",
          function()
            local ok, dapui = pcall(require, "dapui")
            if ok then
              -- Eval expression under cursor or selection
              dapui.eval(nil, { enter = true })
            end
          end,
          mode   = { "n", "v" },
          desc   = "🖥️  DAP UI: Evaluate",
          silent = true,
        },
        {
          "<leader>dE",
          function()
            vim.ui.input({ prompt = "🖥️  Evaluate: " }, function(expr)
              if expr and expr ~= "" then
                local ok, dapui = pcall(require, "dapui")
                if ok then dapui.eval(expr, { enter = true }) end
              end
            end)
          end,
          desc   = "🖥️  DAP UI: Evaluate (input)",
          silent = true,
        },
      },
  
      opts = {
        -- ── Icons ──────────────────────────────────────────────────────────────
        icons = {
          expanded         = "󰅀",
          collapsed        = "󰅂",
          current_frame    = "󰁕",
        },
  
        -- ── Control button icons ───────────────────────────────────────────────
        controls = {
          enabled      = true,
          element      = "repl",
          icons        = {
            pause           = " ",
            play            = " ",
            step_into       = " ",
            step_over       = " ",
            step_out        = " ",
            step_back       = " ",
            run_last        = "↺ ",
            terminate       = "󰓛 ",
            disconnect      = "󰏪 ",
          },
        },
  
        -- ── Layout ─────────────────────────────────────────────────────────────
        layouts = {
          -- ── Layout 1: Left sidebar ──────────────────────────────────────────
          {
            elements = {
              -- Scopes + Watches stacked vertically (top)
              { id = "scopes",      size = 0.35 },
              { id = "watches",     size = 0.20 },
              { id = "breakpoints", size = 0.20 },
              { id = "stacks",      size = 0.25 },
            },
            position = "left",
            size     = 40,
          },
          -- ── Layout 2: Bottom panel ──────────────────────────────────────────
          {
            elements = {
              { id = "repl",    size = 0.6 },
              { id = "console", size = 0.4 },
            },
            position = "bottom",
            size     = 12,
          },
        },
  
        -- ── Floating eval window ───────────────────────────────────────────────
        floating = {
          max_height   = 0.9,
          max_width    = 0.7,
          border       = "rounded",
          mappings     = {
            close      = { "q", "<Esc>" },
          },
        },
  
        -- ── Element options ────────────────────────────────────────────────────
        element_mappings = {
          scopes = {
            open          = "<CR>",
            edit          = "e",
            expand        = "o",
            repl          = "r",
          },
          stacks = {
            open          = "<CR>",
            expand        = "o",
          },
          watches = {
            open          = "<CR>",
            edit          = "e",
            expand        = "o",
            remove        = "d",
            repl          = "r",
          },
          breakpoints = {
            open          = "<CR>",
            toggle        = "o",
            delete        = "d",
          },
        },
  
        -- ── Render options ─────────────────────────────────────────────────────
        render = {
          -- Number of lines in variable previews
          max_type_length = 40,
          max_value_lines = 5,
          -- Indent guides
          indent          = 2,
        },
  
        -- ── Expand lines ──────────────────────────────────────────────────────
        expand_lines = vim.fn.has("nvim-0.7") == 1,
  
        -- ── Force focus on UI open ────────────────────────────────────────────
        force_buffers = true,
  
        -- ── Mappings inside any DAP-UI buffer ────────────────────────────────
        mappings = {
          -- Use a table to apply multiple mappings
          expand         = { "<CR>", "<2-LeftMouse>" },
          open           = "o",
          remove         = "d",
          edit           = "e",
          repl           = "r",
          toggle         = "t",
        },
      },
  
      config = function(_, opts)
        local dapui = require("dapui")
        dapui.setup(opts)
  
        setup_highlights()
  
        -- ── Disable interfering plugins inside dapui buffers ─────────────────
        local aug = vim.api.nvim_create_augroup("AshDapUi", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = {
            "dapui_scopes", "dapui_breakpoints", "dapui_stacks",
            "dapui_watches", "dapui_console", "dap-repl",
          },
          callback = function(ev)
            vim.b[ev.buf].miniindentscope_disable = true
            vim.b[ev.buf].minianimate_disable     = true
            vim.opt_local.number         = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn     = "no"
            vim.opt_local.wrap           = false
            vim.opt_local.spell          = false
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify(
              "🖥️  DAP UI highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH DAP UI", timeout = 1200 }
            )
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "🖥️  DAP UI loaded — 2 layouts configured",
            vim.log.levels.DEBUG,
            { title = "ASH DAP UI" }
          )
        end
      end,
    },
  }