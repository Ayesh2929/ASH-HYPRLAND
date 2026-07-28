-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/edgy.lua — Window Layout & Panel Management                 ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: folke/edgy.nvim                                                     ║
-- ║                                                                              ║
-- ║  Panel layout:                                                               ║
-- ║    LEFT   ← Neo-tree (explorer) + Aerial (outline)                          ║
-- ║    RIGHT  ← Aerial symbols + DAP watches/scopes/stacks + Neotest summary   ║
-- ║    BOTTOM ← Terminal + Trouble + QuickFix + LocList + Neotest output        ║
-- ║    TOP    ← (reserved — unused by default)                                  ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Snappy animated open/close (winblend transition)                       ║
-- ║    • Min/max size constraints per panel                                     ║
-- ║    • Icon-prefixed panel titles                                             ║
-- ║    • Smart focus management: close edgy wins with q                        ║
-- ║    • WinBar with icon + filename for each edgy window                      ║
-- ║    • Catppuccin palette-aware highlight groups                              ║
-- ║    • Telescope, Diffview, OverseerList integration                          ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "folke/edgy.nvim",
    event    = "VeryLazy",
    version  = "*",
    dependencies = {
      "nvim-neo-tree/neo-tree.nvim",
      "folke/trouble.nvim",
    },
  
    -- ── Keys ──────────────────────────────────────────────────────────────────
    keys = {
      {
        "<leader>we",
        function() require("edgy").toggle() end,
        desc = "  Toggle Edgy panels",
      },
      {
        "<leader>wE",
        function() require("edgy").select() end,
        desc = "  Select Edgy panel",
      },
      -- Quick panel toggles
      {
        "<leader>ee",
        function()
          require("neo-tree.command").execute({
            toggle = true,
            dir    = vim.loop.cwd(),
          })
        end,
        desc = "  Explorer (Neo-tree, cwd)",
      },
      {
        "<leader>eE",
        function()
          require("neo-tree.command").execute({
            toggle = true,
            dir    = vim.fn.expand("%:p:h"),
          })
        end,
        desc = "  Explorer (Neo-tree, file dir)",
      },
      {
        "<leader>eo",
        function()
          local ok, aerial = pcall(require, "aerial")
          if ok then aerial.toggle() end
        end,
        desc = "  Outline (Aerial)",
      },
      {
        "<leader>ex",
        function()
          require("trouble").toggle("diagnostics")
        end,
        desc = "  Trouble diagnostics",
      },
      {
        "<leader>eq",
        function()
          if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
            vim.cmd("cclose")
          else
            vim.cmd("copen")
          end
        end,
        desc = "  Toggle QuickFix",
      },
    },
  
    -- ── opts ──────────────────────────────────────────────────────────────────
    opts = function()
      local icons = Ash.icons
  
      -- ── Colour palette ────────────────────────────────────────────────────
      local p = {}
      pcall(function()
        p = require("catppuccin.palettes").get_palette() or {}
      end)
  
      local base    = p.base     or "#1e1e2e"
      local surface = p.surface0 or "#313244"
      local surface1 = p.surface1 or "#45475a"
      local overlay = p.overlay0 or "#6c7086"
      local text    = p.text     or "#cdd6f4"
      local blue    = p.blue     or "#89b4fa"
      local green   = p.green    or "#a6e3a1"
      local mauve   = p.mauve    or "#cba6f7"
      local red     = p.red      or "#f38ba8"
      local yellow  = p.yellow   or "#f9e2af"
      local teal    = p.teal     or "#94e2d5"
      local peach   = p.peach    or "#fab387"
  
      return {
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- LEFT panel — file explorer & outline
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        left = {
          -- ── Neo-tree: filesystem ─────────────────────────────────────
          {
            title      = icons.ui.Tree .. "  Explorer",
            ft         = "neo-tree",
            filter     = function(buf)
              return vim.b[buf].neo_tree_source == "filesystem"
            end,
            size       = { height = 0.5 },
            open       = function()
              require("neo-tree.command").execute({
                reveal = true,
                dir    = vim.loop.cwd(),
              })
            end,
            wo         = {
              winbar   = false,
              winhighlight = "Normal:EdgyLeft,WinSeparator:EdgyBorderLeft",
            },
            pinned     = true,
          },
  
          -- ── Neo-tree: buffers ─────────────────────────────────────────
          {
            title      = icons.ui.Files .. "  Buffers",
            ft         = "neo-tree",
            filter     = function(buf)
              return vim.b[buf].neo_tree_source == "buffers"
            end,
            size       = { height = 0.25 },
            wo         = {
              winbar   = false,
              winhighlight = "Normal:EdgyLeft,WinSeparator:EdgyBorderLeft",
            },
          },
  
          -- ── Neo-tree: git status ──────────────────────────────────────
          {
            title      = icons.git.branch .. "  Git Status",
            ft         = "neo-tree",
            filter     = function(buf)
              return vim.b[buf].neo_tree_source == "git_status"
            end,
            size       = { height = 0.25 },
            wo         = {
              winbar   = false,
              winhighlight = "Normal:EdgyLeft,WinSeparator:EdgyBorderLeft",
            },
          },
  
          -- ── Aerial: symbol outline (left side, compact) ───────────────
          {
            title      = icons.ui.List .. "  Outline",
            ft         = "aerial",
            pinned     = false,
            size       = { width = 28 },
            wo         = {
              winhighlight = "Normal:EdgyLeft,WinSeparator:EdgyBorderLeft",
            },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- RIGHT panel — outline, DAP, Neotest
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        right = {
          -- ── Aerial: symbol outline (right side, wide) ─────────────────
          {
            title      = icons.ui.List .. "  Symbols",
            ft         = "aerial",
            size       = { width = 0.15, height = 0.5 },
            wo         = {
              winhighlight = "Normal:EdgyRight,WinSeparator:EdgyBorderRight",
            },
          },
  
          -- ── Neotest summary ───────────────────────────────────────────
          {
            title      = icons.test.suite .. "  Test Explorer",
            ft         = "neotest-summary",
            size       = { width = 0.2, height = 0.5 },
            wo         = {
              winhighlight = "Normal:EdgyRight,WinSeparator:EdgyBorderRight",
            },
          },
  
          -- ── DAP: scopes ───────────────────────────────────────────────
          {
            title      = icons.dap.play .. "  Scopes",
            ft         = "dapui_scopes",
            size       = { height = 0.25 },
            wo         = {
              winhighlight = "Normal:EdgyRight,WinSeparator:EdgyBorderRight",
            },
          },
  
          -- ── DAP: watches ──────────────────────────────────────────────
          {
            title      = icons.ui.Eye .. "  Watches",
            ft         = "dapui_watches",
            size       = { height = 0.25 },
            wo         = {
              winhighlight = "Normal:EdgyRight,WinSeparator:EdgyBorderRight",
            },
          },
  
          -- ── DAP: stack frames ────────────────────────────────────────
          {
            title      = icons.dap.step_into .. "  Stacks",
            ft         = "dapui_stacks",
            size       = { height = 0.25 },
            wo         = {
              winhighlight = "Normal:EdgyRight,WinSeparator:EdgyBorderRight",
            },
          },
  
          -- ── DAP: breakpoints ─────────────────────────────────────────
          {
            title      = icons.dap.Breakpoint .. "  Breakpoints",
            ft         = "dapui_breakpoints",
            size       = { height = 0.15 },
            wo         = {
              winhighlight = "Normal:EdgyRight,WinSeparator:EdgyBorderRight",
            },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- BOTTOM panel — terminal, diagnostics, output
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        bottom = {
          -- ── Terminal ──────────────────────────────────────────────────
          {
            title      = icons.ui.Terminal .. "  Terminal",
            ft         = "terminal",
            size       = { height = 0.28 },
            open       = function()
              vim.cmd("botright 14split | terminal")
              vim.cmd("startinsert")
            end,
            wo         = {
              winhighlight = "Normal:EdgyBottom,WinSeparator:EdgyBorderBottom",
            },
          },
  
          -- ── Toggleterm ────────────────────────────────────────────────
          {
            title      = icons.ui.Terminal .. "  Shell",
            ft         = "toggleterm",
            size       = { height = 0.28 },
            wo         = {
              winhighlight = "Normal:EdgyBottom,WinSeparator:EdgyBorderBottom",
            },
            filter     = function(_buf, win)
              return vim.w[win].toggleterm_id == 1
            end,
          },
  
          -- ── Trouble: diagnostics ──────────────────────────────────────
          {
            title      = icons.diagnostics.Error .. "  Diagnostics",
            ft         = "trouble",
            filter     = function(_buf, win)
              return vim.w[win].trouble
                and vim.w[win].trouble.mode == "diagnostics"
            end,
            size       = { height = 0.20 },
            wo         = {
              winhighlight = "Normal:EdgyBottom,WinSeparator:EdgyBorderBottom",
            },
          },
  
          -- ── Trouble: symbols (LSP document outline) ───────────────────
          {
            title      = icons.ui.List .. "  Symbols",
            ft         = "trouble",
            filter     = function(_buf, win)
              return vim.w[win].trouble
                and vim.w[win].trouble.mode == "symbols"
            end,
            size       = { height = 0.20 },
            wo         = {
              winhighlight = "Normal:EdgyBottom,WinSeparator:EdgyBorderBottom",
            },
          },
  
          -- ── Trouble: LSP ──────────────────────────────────────────────
          {
            title      = icons.ui.Code .. "  LSP",
            ft         = "trouble",
            filter     = function(_buf, win)
              return vim.w[win].trouble
                and vim.w[win].trouble.mode == "lsp"
            end,
            size       = { height = 0.20 },
            wo         = {
              winhighlight = "Normal:EdgyBottom,WinSeparator:EdgyBorderBottom",
            },
          },
  
          -- ── QuickFix list ─────────────────────────────────────────────
          {
            title      = icons.ui.List .. "  QuickFix",
            ft         = "qf",
            size       = { height = 0.20 },
            wo         = {
              winhighlight = "Normal:EdgyBottom,WinSeparator:EdgyBorderBottom",
            },
          },
  
          -- ── Neotest output panel ──────────────────────────────────────
          {
            title      = icons.test.running .. "  Test Output",
            ft         = "neotest-output-panel",
            size       = { height = 0.25 },
            wo         = {
              winhighlight = "Normal:EdgyBottom,WinSeparator:EdgyBorderBottom",
            },
          },
  
          -- ── Neotest output (floating → pinned bottom) ─────────────────
          {
            title      = icons.test.file .. "  Test Log",
            ft         = "neotest-output",
            size       = { height = 0.20 },
            wo         = {
              winhighlight = "Normal:EdgyBottom,WinSeparator:EdgyBorderBottom",
            },
          },
  
          -- ── OverseerList (task runner) ────────────────────────────────
          {
            title      = icons.ui.Gear .. "  Tasks",
            ft         = "OverseerList",
            size       = { height = 0.20 },
            wo         = {
              winhighlight = "Normal:EdgyBottom,WinSeparator:EdgyBorderBottom",
            },
          },
  
          -- ── DAP REPL ──────────────────────────────────────────────────
          {
            title      = icons.dap.play .. "  DAP REPL",
            ft         = "dap-repl",
            size       = { height = 0.20 },
            wo         = {
              winhighlight = "Normal:EdgyBottom,WinSeparator:EdgyBorderBottom",
            },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Global settings
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        options = {
          left   = { size = 30 },
          right  = { size = 32 },
          bottom = { size = 14 },
          top    = { size = 10 },
        },
  
        animate = {
          enabled  = Ash.flags.enable_animations,
          fps      = 60,
          clamped  = 1,
          easing   = "out_quart",
          on_begin = function(win, _opts)
            -- Fade in edgy panels
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_set_option(win, "winblend", 30)
            end
          end,
          on_step  = function(win, _opts, state)
            if vim.api.nvim_win_is_valid(win) then
              local blend = math.floor(30 * (1 - state.progress))
              vim.api.nvim_win_set_option(win, "winblend", blend)
            end
          end,
          on_end   = function(win, _opts)
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_set_option(win, "winblend", 0)
            end
          end,
        },
  
        -- ── WinBar settings ───────────────────────────────────────────────
        wo = {
          -- Apply to all edgy windows
          winbar           = true,
          winfixwidth      = true,
          winfixheight     = false,
          winhighlight     = "WinBar:EdgyWinBar,Normal:EdgyNormal",
          spell            = false,
          signcolumn       = "no",
          foldcolumn       = "0",
          statuscolumn     = "",
        },
  
        -- ── Exit behaviour ────────────────────────────────────────────────
        exit_when_last   = false,
  
        -- ── Icons in WinBar ───────────────────────────────────────────────
        icons = {
          open  = icons.ui.ChevronDown,
          closed = icons.ui.ChevronRight,
        },
      }
    end,
  
    -- ── config ────────────────────────────────────────────────────────────────
    config = function(_, opts)
      -- Guard: skip if edgy is explicitly disabled
      if vim.env.ASH_NO_EDGY == "1" then return end
  
      require("edgy").setup(opts)
  
      -- ── Highlight groups ──────────────────────────────────────────────────
      local function apply_hl()
        local p = {}
        pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
        local base     = p.base      or "#1e1e2e"
        local crust    = p.crust     or "#11111b"
        local surface  = p.surface0  or "#313244"
        local surface1 = p.surface1  or "#45475a"
        local mantle   = p.mantle    or "#181825"
        local overlay  = p.overlay0  or "#6c7086"
        local text     = p.text      or "#cdd6f4"
        local blue     = p.blue      or "#89b4fa"
        local green    = p.green     or "#a6e3a1"
        local mauve    = p.mauve     or "#cba6f7"
        local red      = p.red       or "#f38ba8"
        local yellow   = p.yellow    or "#f9e2af"
        local teal     = p.teal      or "#94e2d5"
        local peach    = p.peach     or "#fab387"
  
        local hls = {
          -- ── Panel backgrounds ─────────────────────────────────────────
          EdgyNormal        = { bg = mantle,  fg = text                        },
          EdgyLeft          = { bg = mantle,  fg = text                        },
          EdgyRight         = { bg = mantle,  fg = text                        },
          EdgyBottom        = { bg = crust,   fg = text                        },
          -- ── WinBar ────────────────────────────────────────────────────
          EdgyWinBar        = { bg = surface, fg = overlay, bold = false        },
          EdgyWinBarActive  = { bg = surface1, fg = blue,   bold = true         },
          -- ── Borders / separators ──────────────────────────────────────
          EdgyBorderLeft    = { fg = surface1, bg = mantle                      },
          EdgyBorderRight   = { fg = surface1, bg = mantle                      },
          EdgyBorderBottom  = { fg = surface1, bg = crust                       },
          EdgyBorderTop     = { fg = surface1, bg = mantle                      },
          -- ── Title ─────────────────────────────────────────────────────
          EdgyTitle         = { fg = mauve,   bg = surface,  bold = true,
                                italic = true                                   },
          EdgyTitleActive   = { fg = blue,    bg = surface1, bold = true        },
          -- ── Icon ──────────────────────────────────────────────────────
          EdgyIconOpen      = { fg = green                                      },
          EdgyIconClosed    = { fg = overlay                                    },
        }
  
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
  
      -- ── Fix: close edgy windows with q ───────────────────────────────────
      vim.api.nvim_create_autocmd("FileType", {
        pattern  = {
          "neo-tree", "aerial", "trouble", "qf",
          "toggleterm", "dap-repl", "dapui_scopes",
          "dapui_watches", "dapui_stacks", "dapui_breakpoints",
          "neotest-summary", "neotest-output", "neotest-output-panel",
          "OverseerList",
        },
        callback = function(ev)
          vim.keymap.set("n", "q", function()
            local ok, edgy = pcall(require, "edgy")
            if ok then
              edgy.close()
            else
              vim.cmd("close")
            end
          end, { buffer = ev.buf, silent = true, desc = "Close edgy panel" })
        end,
      })
  
      -- ── User command: show edgy layout status ─────────────────────────────
      vim.api.nvim_create_user_command("EdgyStatus", function()
        local ok, edgy = pcall(require, "edgy")
        if not ok then
          vim.notify("edgy.nvim not loaded", vim.log.levels.WARN, { title = "ASH" })
          return
        end
        local info = {}
        for _, side in ipairs({ "left", "right", "bottom", "top" }) do
          local wins = edgy.get_wins(side)
          if wins and #wins > 0 then
            info[#info + 1] = string.format(
              "  %s: %d panel%s",
              side:upper(),
              #wins,
              #wins == 1 and "" or "s"
            )
          end
        end
        vim.notify(
          table.concat(info, "\n"),
          vim.log.levels.INFO,
          { title = "Edgy Layout Status" }
        )
      end, { desc = "Show edgy panel layout status" })
    end,
  }