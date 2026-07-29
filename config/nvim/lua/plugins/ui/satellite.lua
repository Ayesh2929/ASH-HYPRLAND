-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/satellite.lua — Minimap / Scrollbar Decorations             ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: lewis6991/satellite.nvim                                            ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Decorative right-hand scrollbar with semantic overlays                 ║
-- ║    • Search results minimap (all matches in current buffer)                 ║
-- ║    • Git hunks (added/changed/deleted) on scrollbar                        ║
-- ║    • Diagnostic positions (E/W/I/H) at their line positions                ║
-- ║    • Mark positions                                                         ║
-- ║    • QuickFix / Location list entry indicators                             ║
-- ║    • Gitsigns integration (real-time hunk positions)                        ║
-- ║    • Catppuccin palette-aware colouring                                     ║
-- ║    • Excluded filetypes / buf types                                         ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "lewis6991/satellite.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cond  = function()
      -- Satellite needs a sign column — skip in minimal sessions
      return not vim.env.CI
    end,
    keys  = {
      {
        "<leader>uv",
        function()
          local ok, sat = pcall(require, "satellite")
          if not ok then return end
          -- satellite doesn't expose a direct toggle; we toggle via enable/disable
          if vim.g.satellite_enabled == false then
            sat.enable()
            vim.g.satellite_enabled = true
            vim.notify(" Satellite scrollbar enabled",  vim.log.levels.INFO, { title = "ASH" })
          else
            sat.disable()
            vim.g.satellite_enabled = false
            vim.notify("󰅖 Satellite scrollbar disabled", vim.log.levels.INFO, { title = "ASH" })
          end
        end,
        desc = "  Toggle satellite scrollbar",
      },
    },
  
    opts = function()
      local icons = Ash.icons
  
      -- ── Colour palette ────────────────────────────────────────────────────
      local p = {}
      pcall(function()
        p = require("catppuccin.palettes").get_palette() or {}
      end)
  
      local overlay = p.overlay0 or "#6c7086"
      local blue    = p.blue     or "#89b4fa"
      local green   = p.green    or "#a6e3a1"
      local yellow  = p.yellow   or "#f9e2af"
      local red     = p.red      or "#f38ba8"
      local mauve   = p.mauve    or "#cba6f7"
      local peach   = p.peach    or "#fab387"
      local teal    = p.teal     or "#94e2d5"
      local surface = p.surface0 or "#313244"
  
      -- ── Excluded filetypes ────────────────────────────────────────────────
      local excluded_ft = {
        "alpha",
        "dashboard",
        "neo-tree",
        "NvimTree",
        "aerial",
        "Trouble",
        "lazy",
        "mason",
        "notify",
        "toggleterm",
        "lazyterm",
        "help",
        "checkhealth",
        "lspinfo",
        "TelescopePrompt",
        "TelescopeResults",
        "WhichKey",
        "noice",
        "dap-repl",
        "dapui_watches",
        "dapui_stacks",
        "dapui_breakpoints",
        "dapui_scopes",
        "neotest-output",
        "neotest-output-panel",
        "neotest-summary",
        "gitcommit",
        "fugitive",
        "DiffviewFiles",
        "DiffviewFileHistory",
      }
  
      return {
        -- ── Global settings ───────────────────────────────────────────────
        current_only  = false,       -- show in all windows, not just current
        winblend      = 20,          -- scrollbar transparency
        -- The scrollbar column
        zindex        = 40,
        -- Scrollbar width in columns
        width         = 2,
  
        -- ── Excluded buffers ───────────────────────────────────────────────
        excluded_filetypes   = excluded_ft,
        excluded_buftypes    = {
          "nofile",
          "terminal",
          "prompt",
          "quickfix",
          "help",
          "nowrite",
          "acwrite",
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- HANDLERS — each overlays different information onto the scrollbar
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        handlers = {
  
          -- ── Cursor position indicator ─────────────────────────────────
          cursor = {
            enable   = true,
            overlap  = true,
            priority = 1024,
            -- hl group: SatelliteCursor (defined below)
          },
  
          -- ── Search matches ────────────────────────────────────────────
          -- Shows all search match positions as small marks on the scrollbar
          search = {
            enable   = true,
            overlap  = true,
            priority = 50,
          },
  
          -- ── Diagnostic positions ──────────────────────────────────────
          -- Each severity gets its own icon on the scrollbar
          diagnostic = {
            enable   = true,
            overlap  = false,
            priority = 40,
            -- Per-severity: icon + highlight group
            signs    = {
              -- [severity] = "icon"
              [vim.diagnostic.severity.ERROR] = icons.diagnostics.signs.Error,
              [vim.diagnostic.severity.WARN]  = icons.diagnostics.signs.Warn,
              [vim.diagnostic.severity.INFO]  = icons.diagnostics.signs.Info,
              [vim.diagnostic.severity.HINT]  = icons.diagnostics.signs.Hint,
            },
          },
  
          -- ── Git hunks (via gitsigns) ──────────────────────────────────
          gitsigns = {
            enable   = true,
            overlap  = false,
            priority = 30,
            signs    = {
              add    = { text = icons.git.diff_add    },
              change = { text = icons.git.diff_change },
              delete = { text = icons.git.diff_delete },
            },
          },
  
          -- ── Marks ─────────────────────────────────────────────────────
          marks = {
            enable   = true,
            overlap  = false,
            priority = 20,
            -- Show all named marks (A-Z, a-z)
            key      = function(mark)
              return mark.pos ~= nil and mark.name or nil
            end,
          },
  
          -- ── QuickFix / LocList entries ─────────────────────────────────
          quickfix = {
            enable   = true,
            overlap  = false,
            priority = 10,
            signs    = {
              quickfix = { text = icons.ui.List,     hl = "SatelliteQuickfix"  },
              loclist  = { text = icons.ui.BookMark, hl = "SatelliteLoclist"   },
            },
          },
        },
      }
    end,
  
    config = function(_, opts)
      require("satellite").setup(opts)
  
      -- ── Highlight groups ──────────────────────────────────────────────────
      local function apply_hl()
        local p = {}
        pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
        local overlay = p.overlay0  or "#6c7086"
        local surface = p.surface0  or "#313244"
        local blue    = p.blue      or "#89b4fa"
        local green   = p.green     or "#a6e3a1"
        local yellow  = p.yellow    or "#f9e2af"
        local red     = p.red       or "#f38ba8"
        local mauve   = p.mauve     or "#cba6f7"
        local peach   = p.peach     or "#fab387"
        local teal    = p.teal      or "#94e2d5"
  
        local hls = {
          -- Scrollbar track
          SatelliteBar               = { bg = surface,  fg = "NONE"              },
          -- Cursor position indicator
          SatelliteCursor            = { bg = blue,     fg = surface, bold = true },
          -- Search matches
          SatelliteSearch            = { fg = yellow,   bold = true               },
          -- Diagnostics
          SatelliteSignDiagnosticE   = { fg = red,      bold = true               },
          SatelliteSignDiagnosticW   = { fg = yellow                              },
          SatelliteSignDiagnosticI   = { fg = blue                                },
          SatelliteSignDiagnosticH   = { fg = teal                                },
          SatelliteDiagnosticError   = { fg = red,      bold = true               },
          SatelliteDiagnosticWarn    = { fg = yellow                              },
          SatelliteDiagnosticInfo    = { fg = blue                                },
          SatelliteDiagnosticHint    = { fg = teal                                },
          -- Git hunks
          SatelliteGitSignsAdd       = { fg = green,    bold = true               },
          SatelliteGitSignsChange    = { fg = yellow                              },
          SatelliteGitSignsDelete    = { fg = red                                 },
          -- Marks
          SatelliteMark              = { fg = peach,    bold = true               },
          -- QuickFix
          SatelliteQuickfix          = { fg = mauve                               },
          SatelliteLoclist           = { fg = overlay                             },
        }
  
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
  
      -- ── Auto-disable for large files ──────────────────────────────────────
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(ev)
          if vim.b[ev.buf].large_file then
            pcall(require("satellite").disable)
          end
        end,
      })
    end,
  }