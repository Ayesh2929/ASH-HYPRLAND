-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🚨 TROUBLE.NVIM — ULTRA DIAGNOSTICS PANEL v5.0 OMEGA                     ║
-- ║   Unified diagnostics · LSP references · quickfix · location list               ║
-- ║   Todo integration · Telescope sink · animated icons · ASH theme-aware          ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 ICON DEFINITIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ICONS = {
    -- Diagnostic severity
    error         = " ",
    warning       = " ",
    information   = " ",
    hint          = "󰌵 ",
  
    -- Item kinds
    file          = "󰈙 ",
    folder        = "󰉋 ",
    module        = "󰅩 ",
  
    -- Navigation
    arrow_right   = " ",
    arrow_down    = " ",
    indent        = "  ",
    fold_open     = " ",
    fold_closed   = " ",
  
    -- Counts
    count_badge   = "󰠱 ",
  
    -- Severity source icons for signs column
    signs         = {
      error   = " ",
      warn    = " ",
      info    = " ",
      hint    = "󰌵 ",
    },
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎨 HIGHLIGHTS — ASH theme-synced
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- Panel chrome
    hl(0, "TroubleNormal",          { link = "NormalFloat"   })
    hl(0, "TroubleNormalNC",        { link = "NormalFloat"   })
    hl(0, "TroubleBorder",          { link = "FloatBorder"   })
  
    -- Header / counts
    hl(0, "TroubleCount",           { link = "TabLineSel"    })
    hl(0, "TroubleHeader",          { bold = true            })
  
    -- Severity colours
    hl(0, "TroubleError",           { link = "DiagnosticError"   })
    hl(0, "TroubleWarning",         { link = "DiagnosticWarn"    })
    hl(0, "TroubleInformation",     { link = "DiagnosticInfo"    })
    hl(0, "TroubleHint",            { link = "DiagnosticHint"    })
  
    -- File / location
    hl(0, "TroubleFile",            { link = "Directory"     })
    hl(0, "TroubleSource",          { link = "Comment"       })
    hl(0, "TroublePos",             { link = "LineNr"        })
    hl(0, "TroubleLocation",        { link = "LineNr"        })
    hl(0, "TroubleFoldIcon",        { link = "NonText"       })
    hl(0, "TroubleIndent",          { link = "NonText"       })
  
    -- Selected item
    hl(0, "TroubleSelected",        { link = "CursorLine"    })
    hl(0, "TroubleCode",            { link = "String"        })
  
    -- Sign column icons
    hl(0, "TroubleSignError",       { link = "DiagnosticSignError" })
    hl(0, "TroubleSignWarning",     { link = "DiagnosticSignWarn"  })
    hl(0, "TroubleSignInformation", { link = "DiagnosticSignInfo"  })
    hl(0, "TroubleSignHint",        { link = "DiagnosticSignHint"  })
  
    -- Text preview inside trouble panel
    hl(0, "TroubleText",            { link = "Normal"        })
    hl(0, "TroubleTextError",       { link = "DiagnosticError" })
    hl(0, "TroubleTextWarning",     { link = "DiagnosticWarn"  })
    hl(0, "TroubleTextInformation", { link = "DiagnosticInfo"  })
    hl(0, "TroubleTextHint",        { link = "DiagnosticHint"  })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🛠️  CUSTOM FILTERS — composable diagnostic filters
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Filter: only errors (severity == ERROR)
  local filter_errors_only = {
    severity = vim.diagnostic.severity.ERROR,
  }
  
  -- Filter: only current file
  local filter_buf_only = {
    buf = 0,
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🗺️  ACTION HELPERS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Smart toggle: open if closed, close if open, switch mode if different
  local function trouble_toggle(mode, opts)
    return function()
      local trouble = require("trouble")
      if trouble.is_open() then
        -- If same mode already open → close; else switch mode
        trouble.toggle(vim.tbl_extend("force", { mode = mode }, opts or {}))
      else
        trouble.open(vim.tbl_extend("force", { mode = mode }, opts or {}))
      end
    end
  end
  
  -- Jump to next trouble item and preview it
  local function trouble_next(severity)
    return function()
      local trouble = require("trouble")
      if trouble.is_open() then
        trouble.next({ skip_groups = true, jump = true })
      else
        -- Fall back to vim.diagnostic
        vim.diagnostic.goto_next({
          severity  = severity,
          float     = { border = "rounded", source = "always" },
        })
      end
    end
  end
  
  local function trouble_prev(severity)
    return function()
      local trouble = require("trouble")
      if trouble.is_open() then
        trouble.previous({ skip_groups = true, jump = true })
      else
        vim.diagnostic.goto_prev({
          severity  = severity,
          float     = { border = "rounded", source = "always" },
        })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "folke/trouble.nvim",
      cmd          = { "Trouble", "TroubleToggle", "TroubleClose", "TroubleRefresh" },
      event        = { "BufReadPre" },
      dependencies = {
        "nvim-tree/nvim-web-devicons",
        { "folke/todo-comments.nvim", optional = true },
      },
  
      -- ── Keys ──────────────────────────────────────────────────────────────────
      keys = {
        -- ── Workspace diagnostics ────────────────────────────────────────────
        {
          "<leader>xx",
          trouble_toggle("diagnostics"),
          desc = "🚨 Diagnostics (workspace)",
        },
        {
          "<leader>xX",
          trouble_toggle("diagnostics", { filter = filter_errors_only }),
          desc = "🚨 Errors only (workspace)",
        },
  
        -- ── Buffer diagnostics ────────────────────────────────────────────────
        {
          "<leader>xb",
          trouble_toggle("diagnostics", { filter = filter_buf_only }),
          desc = "🚨 Diagnostics (buffer)",
        },
        {
          "<leader>xB",
          trouble_toggle("diagnostics", {
            filter = { severity = vim.diagnostic.severity.ERROR, buf = 0 },
          }),
          desc = "🚨 Errors (buffer)",
        },
  
        -- ── LSP references / definitions ─────────────────────────────────────
        {
          "<leader>xr",
          trouble_toggle("lsp_references"),
          desc = "🚨 LSP References",
        },
        {
          "<leader>xd",
          trouble_toggle("lsp_definitions"),
          desc = "🚨 LSP Definitions",
        },
        {
          "<leader>xi",
          trouble_toggle("lsp_implementations"),
          desc = "🚨 LSP Implementations",
        },
        {
          "<leader>xt",
          trouble_toggle("lsp_type_definitions"),
          desc = "🚨 LSP Type Definitions",
        },
        {
          "<leader>xl",
          trouble_toggle("lsp"),
          desc = "🚨 LSP References/Definitions/…",
        },
  
        -- ── Quickfix / Loclist ────────────────────────────────────────────────
        {
          "<leader>xq",
          trouble_toggle("qflist"),
          desc = "🚨 Quickfix List",
        },
        {
          "<leader>xL",
          trouble_toggle("loclist"),
          desc = "🚨 Location List",
        },
  
        -- ── Todo comments ────────────────────────────────────────────────────
        {
          "<leader>xT",
          trouble_toggle("todo"),
          desc = "🚨 TODOs (workspace)",
        },
        {
          "<leader>xF",
          trouble_toggle("todo", {
            filter = { tag = { "TODO", "FIXME", "BUG" } },
          }),
          desc = "🚨 TODO / FIXME / BUG",
        },
  
        -- ── Navigation ────────────────────────────────────────────────────────
        {
          "]d",
          trouble_next(nil),
          desc = "🚨 Next diagnostic (trouble-aware)",
        },
        {
          "[d",
          trouble_prev(nil),
          desc = "🚨 Prev diagnostic (trouble-aware)",
        },
        {
          "]e",
          trouble_next(vim.diagnostic.severity.ERROR),
          desc = "🚨 Next error",
        },
        {
          "[e",
          trouble_prev(vim.diagnostic.severity.ERROR),
          desc = "🚨 Prev error",
        },
        {
          "]w",
          trouble_next(vim.diagnostic.severity.WARN),
          desc = "🚨 Next warning",
        },
        {
          "[w",
          trouble_prev(vim.diagnostic.severity.WARN),
          desc = "🚨 Prev warning",
        },
  
        -- ── Refresh / close ────────────────────────────────────────────────────
        {
          "<leader>xc",
          "<cmd>TroubleClose<cr>",
          desc = "🚨 Close Trouble",
        },
        {
          "<leader>xR",
          "<cmd>TroubleRefresh<cr>",
          desc = "🚨 Refresh Trouble",
        },
      },
  
      -- ── Options ─────────────────────────────────────────────────────────────
      opts = {
        -- ── Window appearance ──────────────────────────────────────────────────
        position          = "bottom",    -- "bottom" | "top" | "left" | "right"
        height            = 14,          -- for bottom/top positions
        width             = 50,          -- for left/right positions
        padding           = true,        -- add extra padding around items
  
        -- ── Window style ──────────────────────────────────────────────────────
        win_config = {
          border   = "rounded",
          zindex   = 200,
        },
  
        -- ── Icons ─────────────────────────────────────────────────────────────
        icons = {
          indent = {
            top         = "│ ",
            middle      = "├╴",
            last        = "└╴",
            fold_open   = ICONS.fold_open,
            fold_closed = ICONS.fold_closed,
            ws          = "  ",
          },
          folder_closed   = ICONS.folder .. " ",
          folder_open     = "󰝰 ",
          kinds           = {
            Array         = "󱡠 ",
            Boolean       = "󰨙 ",
            Class         = "󰌗 ",
            Constant      = "󰏿 ",
            Constructor   = " ",
            Enum          = " ",
            EnumMember    = " ",
            Event         = " ",
            Field         = " ",
            File          = "󰈙 ",
            Function      = "󰊕 ",
            Interface     = " ",
            Key           = "󰌋 ",
            Method        = "󰆧 ",
            Module        = "󰅩 ",
            Namespace     = "󰅩 ",
            Null          = "󰟢 ",
            Number        = " ",
            Object        = "󰅩 ",
            Operator      = "󰆕 ",
            Package       = "󰹻 ",
            Property      = "󰖷 ",
            String        = "󱌯 ",
            Struct        = "󱡠 ",
            TypeParameter = "󰊄 ",
            Variable      = "󰀫 ",
          },
        },
  
        -- ── Signs ─────────────────────────────────────────────────────────────
        signs = {
          error       = ICONS.signs.error,
          warning     = ICONS.signs.warn,
          information = ICONS.signs.info,
          hint        = ICONS.signs.hint,
          other       = "  ",
        },
  
        -- ── Behaviour ─────────────────────────────────────────────────────────
        -- Close trouble automatically when no items remain
        auto_close          = true,
  
        -- Auto-preview the selected item in the buffer
        auto_preview        = true,
  
        -- Jump to single item automatically
        auto_jump           = { "lsp_definitions" },
  
        -- Open trouble with focus on it
        focus               = true,
  
        -- Restore previous position when re-opening
        restore             = true,
  
        -- Use follow_cursor to auto-scroll trouble to current buffer position
        follow_cursor       = true,
  
        -- Indent guides
        indent_lines        = true,
  
        -- Merge files (group items under their source file)
        group               = true,
  
        -- Display as a split (false = floating window)
        use_diagnostic_signs= true,
  
        -- Animate panel open/close
        win_opts            = { winblend = 0 },
  
        -- ── Modes configuration ────────────────────────────────────────────────
        modes = {
          -- ── Diagnostics (workspace) ─────────────────────────────────────────
          diagnostics = {
            mode  = "diagnostics",
            title = "🚨 Workspace Diagnostics",
            preview = {
              type   = "split",
              relative = "win",
              position = "right",
              size     = 0.4,
            },
            sort = {
              { key = "severity",  order = "asc"  },
              { key = "filename",  order = "asc"  },
              { key = "lnum",      order = "asc"  },
              { key = "col",       order = "asc"  },
            },
          },
  
          -- ── LSP references ──────────────────────────────────────────────────
          lsp_references = {
            params = {
              include_declaration = false,
            },
            title  = "  LSP References",
            preview = {
              type     = "split",
              relative = "win",
              position = "right",
              size     = 0.45,
            },
          },
  
          -- ── LSP (all: defs + refs + impls + type_defs) ──────────────────────
          lsp = {
            title     = "  LSP Overview",
            win = { size = { width = 50 } },
          },
  
          -- ── Quickfix ────────────────────────────────────────────────────────
          qflist = {
            title = "  Quickfix List",
            preview = {
              type     = "split",
              relative = "win",
              position = "right",
              size     = 0.5,
            },
          },
  
          -- ── Loclist ─────────────────────────────────────────────────────────
          loclist = {
            title = "  Location List",
          },
  
          -- ── Todo comments ────────────────────────────────────────────────────
          todo = {
            events = { "BufEnter" },
            title  = "  TODO Comments",
            filter = {
              any = {
                { tag = { "TODO", "FIXME", "HACK", "WARN", "NOTE",
                           "PERF", "TEST", "DOCS", "ASH" } },
              },
            },
            sort = {
              { key = "severity", order = "asc" },
              { key = "filename", order = "asc" },
              { key = "lnum",     order = "asc" },
            },
            preview = {
              type     = "split",
              relative = "win",
              position = "right",
              size     = 0.4,
            },
          },
  
          -- ── Custom: cascading errors + warnings ─────────────────────────────
          cascade = {
            mode  = "diagnostics",
            title = "🌊 Cascading Issues",
            filter = function(items)
              local severity = vim.diagnostic.severity
              local errors   = vim.tbl_filter(
                function(i) return i.severity == severity.ERROR   end, items)
              if #errors > 0 then return errors end
              return vim.tbl_filter(
                function(i) return i.severity == severity.WARN    end, items)
            end,
          },
        },
  
        -- ── Inner window keymaps ─────────────────────────────────────────────
        keys = {
          -- Navigation
          ["?"]         = "help",
          ["r"]         = "refresh",
          ["R"]         = "toggle_refresh",
          ["q"]         = "close",
          ["<esc>"]     = "close",
          ["<cr>"]      = "jump",
          ["<c-s>"]     = "jump_split",
          ["<c-v>"]     = "jump_vsplit",
          ["<c-t>"]     = "jump_tab",
          ["o"]         = "jump",
          ["<tab>"]     = "fold_toggle",
          ["<s-tab>"]   = "fold_toggle_recursive",
          ["za"]        = "fold_toggle",
          ["zA"]        = "fold_toggle_recursive",
          ["zc"]        = "fold_close",
          ["zC"]        = "fold_close_recursive",
          ["zo"]        = "fold_open",
          ["zO"]        = "fold_open_recursive",
          ["zR"]        = "fold_open_all",
          ["zM"]        = "fold_close_all",
          ["j"]         = "next",
          ["k"]         = "prev",
          ["]]"]        = "next",
          ["[["]        = "prev",
          ["p"]         = "preview",
          ["P"]         = "toggle_preview",
          -- Filtering
          ["f"]         = {
            action = function(view)
              vim.ui.input({ prompt = "Filter: " }, function(input)
                if input then view:filter({ text = input }) end
              end)
            end,
            desc = "filter",
          },
          ["F"]         = "reset_filter",
          -- Grouping
          ["G"]         = "toggle_group",
          -- Severity cycling
          ["s"]         = {
            action = function(view)
              local cfg = view.config
              local next_sev = {
                [vim.diagnostic.severity.ERROR]  = vim.diagnostic.severity.WARN,
                [vim.diagnostic.severity.WARN]   = vim.diagnostic.severity.INFO,
                [vim.diagnostic.severity.INFO]   = vim.diagnostic.severity.HINT,
                [vim.diagnostic.severity.HINT]   = nil,
              }
              local target_sev = next_sev[sev]
              if sev == nil then
                target_sev = vim.diagnostic.severity.ERROR
              end
              cfg.filter = { severity = target_sev }
              view:refresh()
            end,
            desc = "cycle severity filter",
          },
          -- Copy item path to clipboard
          ["y"]         = {
            action = function(view)
              local item = view:get_item()
              if item and item.filename then
                vim.fn.setreg("+", item.filename)
                vim.notify("📋 Copied: " .. item.filename, vim.log.levels.INFO,
                  { title = "Trouble" })
              end
            end,
            desc = "copy path",
          },
        },
      },
  
      -- ── Config ─────────────────────────────────────────────────────────────
      config = function(_, opts)
        require("trouble").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshTrouble", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            -- If trouble is open, refresh to repaint icons with new colours
            if require("trouble").is_open() then
              vim.defer_fn(function()
                pcall(vim.cmd, "TroubleRefresh")
              end, 150)
            end
          end,
        })
  
        -- Intercept native quickfix / loclist with Trouble
        local function redirect_to_trouble(ev)
          if #vim.fn.getqflist() > 0 then
            vim.defer_fn(function()
              vim.cmd("cclose")
              require("trouble").open({ mode = "qflist", focus = false })
            end, 0)
          end
        end
  
        vim.api.nvim_create_autocmd("QuickFixCmdPost", {
          group    = aug,
          pattern  = "[^l]*",
          callback = redirect_to_trouble,
        })
  
        if vim.g.ash_debug then
          vim.notify("🚨 Trouble.nvim loaded", vim.log.levels.DEBUG, { title = "ASH Trouble" })
        end
      end,
    },
  }