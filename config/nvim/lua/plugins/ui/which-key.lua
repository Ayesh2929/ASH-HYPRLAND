-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/which-key.lua — Keybind Discovery & Legend                  ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: folke/which-key.nvim  (v3)                                          ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Beautiful popup with Nerd Font icons per group                         ║
-- ║    • Full group registration for every <leader> namespace                   ║
-- ║    • Mode-aware: Normal / Visual / Insert / Operator-pending               ║
-- ║    • Delay tuned to feel instant but not flash during fast keystrokes       ║
-- ║    • Preset: motion hints (w/b/e/ge), g-prefix, z-prefix, bracket pairs    ║
-- ║    • Catppuccin palette-aware highlight groups                              ║
-- ║    • Telescope integration: <leader>? shows all keymaps                    ║
-- ║    • Layout: helix-style (sort by key, not description)                    ║
-- ║    • Breadcrumbs in the title bar                                           ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "folke/which-key.nvim",
    event    = "VeryLazy",
    version  = "*",
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "󰌌  Buffer keymaps (which-key)",
      },
      {
        "<C-w><space>",
        function()
          require("which-key").show({ keys = "<C-w>", loop = true })
        end,
        desc = "󰖵  Window keybinds (which-key)",
      },
      {
        "<leader>K",
        function()
          require("which-key").show({ keys = "<leader>", global = true })
        end,
        desc = "󰌌  All leader keymaps",
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
      local overlay = p.overlay0 or "#6c7086"
      local text    = p.text     or "#cdd6f4"
      local blue    = p.blue     or "#89b4fa"
      local green   = p.green    or "#a6e3a1"
      local yellow  = p.yellow   or "#f9e2af"
      local red     = p.red      or "#f38ba8"
      local mauve   = p.mauve    or "#cba6f7"
      local peach   = p.peach    or "#fab387"
      local teal    = p.teal     or "#94e2d5"
      local sky     = p.sky      or "#89dceb"
      local sapph   = p.sapphire or "#74c7ec"
      local lavend  = p.lavender or "#b4befe"
      local pink    = p.pink     or "#f5c2e7"
      local rosewater = p.rosewater or "#f5e0dc"
  
      return {
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Core behaviour
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        preset       = "helix",       -- "classic" | "modern" | "helix"
        delay        = function(ctx)
          -- Show immediately for non-prefix keys (already waited timeoutlen)
          return ctx.plugin and 0 or 300
        end,
        defer        = function(ctx)
          -- Defer for motions: d, y, c, g, z
          return ctx.mode == "V" or ctx.mode == "v"
        end,
        notify       = false,
        triggers     = {
          { "<auto>", mode = "nxsot" },
        },
        -- Avoid triggering on these keys (they're too common)
        filter       = function(mapping)
          -- Hide mappings without descriptions in normal use
          -- (show them in the full :WhichKey dump)
          return mapping.desc and mapping.desc ~= ""
        end,
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Layout
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        win          = {
          border       = "rounded",
          title        = true,
          title_pos    = "center",
          padding      = { 1, 2 },    -- { top/bottom, left/right }
          wo           = {
            winblend   = 8,
            winhighlight = table.concat({
              "Normal:WhichKeyFloat",
              "FloatBorder:WhichKeyBorder",
              "FloatTitle:WhichKeyTitle",
              "CursorLine:WhichKeyCursorLine",
            }, ","),
          },
        },
        layout       = {
          width       = { min = 20, max = 50 },
          spacing     = 3,
          align       = "left",
        },
        -- Show separator between key and description
        separator    = " " .. icons.ui.ArrowRight .. " ",
        -- Sort: by local key letter, then description
        sort         = { "local", "order", "group", "alphanum", "mod" },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Icons
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        icons        = {
          breadcrumb   = icons.ui.ChevronRight,
          separator    = icons.ui.ArrowRight,
          group        = icons.ui.ChevronRight .. " ",
          ellipsis     = icons.ui.Ellipsis,
          -- Per-key-prefix icons (key → icon)
          mappings     = true,
          rules        = {
            -- Explicit per-key overrides
            { pattern = "buffer",   icon = icons.ui.Files,        color = "azure"  },
            { pattern = "git",      icon = icons.git.branch,      color = "orange" },
            { pattern = "search",   icon = icons.ui.Search,       color = "green"  },
            { pattern = "ui",       icon = icons.ui.Gear,         color = "purple" },
            { pattern = "debug",    icon = icons.dap.play,        color = "red"    },
            { pattern = "test",     icon = icons.test.suite,      color = "green"  },
            { pattern = "terminal", icon = icons.ui.Terminal,     color = "red"    },
            { pattern = "quit",     icon = icons.ui.Power,        color = "red"    },
            { pattern = "session",  icon = icons.ui.BookMark,     color = "azure"  },
            { pattern = "window",   icon = icons.ui.Stacks,       color = "azure"  },
            { pattern = "find",     icon = icons.ui.FindFile,     color = "green"  },
            { pattern = "file",     icon = icons.ui.File,         color = "azure"  },
            { pattern = "toggle",   icon = icons.ui.Gear,         color = "purple" },
            { pattern = "note",     icon = icons.ui.Note,         color = "yellow" },
            { pattern = "ai",       icon = icons.misc.ai,         color = "purple" },
            { pattern = "lsp",      icon = icons.ui.Code,         color = "azure"  },
            { pattern = "notify",   icon = icons.ui.Bell,         color = "orange" },
            { pattern = "plugin",   icon = icons.misc.lazy,       color = "azure"  },
            { pattern = "format",   icon = icons.status.formatter, color = "green" },
            { pattern = "theme",    icon = icons.ui.Star,         color = "purple" },
            { pattern = "zen",      icon = icons.ui.Eye,          color = "cyan"   },
            { pattern = "fold",     icon = icons.ui.Triangle,     color = "azure"  },
            { pattern = "tab",      icon = icons.ui.Tab,          color = "orange" },
            { pattern = "workspace", icon = icons.ui.Table,       color = "azure"  },
            { pattern = "mark",     icon = icons.ui.BookMark,     color = "orange" },
            { pattern = "yank",     icon = icons.ui.Copy,         color = "yellow" },
            { pattern = "paste",    icon = icons.ui.Paste,        color = "yellow" },
            { pattern = "run",      icon = icons.ui.Rocket,       color = "green"  },
          },
          -- Colour map for icon colours
          colors       = true,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Spec: group definitions
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        spec         = {
          -- ── Top-level groups ────────────────────────────────────────────
          { "<leader>a",  group = icons.misc.ai         .. "  AI Assistant"          },
          { "<leader>b",  group = icons.ui.Files        .. "  Buffers"               },
          { "<leader>c",  group = icons.ui.Code         .. "  Code / LSP"            },
          { "<leader>d",  group = icons.dap.play        .. "  Debug (DAP)"           },
          { "<leader>e",  group = icons.diagnostics.Error .. "  Diagnostics"         },
          { "<leader>f",  group = icons.ui.FindFile     .. "  Find / Search"         },
          { "<leader>g",  group = icons.git.branch      .. "  Git"                   },
          { "<leader>h",  group = icons.ui.Hammer       .. "  Hunks (Git)"           },
          { "<leader>l",  group = icons.misc.lazy       .. "  Lazy / Plugins"        },
          { "<leader>n",  group = icons.ui.Bell         .. "  Notifications"         },
          { "<leader>o",  group = icons.ui.Note         .. "  Obsidian / Notes"      },
          { "<leader>p",  group = icons.ui.Package      .. "  Project"               },
          { "<leader>q",  group = icons.ui.Power        .. "  Quit / Session"        },
          { "<leader>r",  group = icons.ui.Refresh      .. "  Refactor"              },
          { "<leader>s",  group = icons.ui.Search       .. "  Search (Telescope)"    },
          { "<leader>t",  group = icons.ui.Terminal     .. "  Terminal"              },
          { "<leader>u",  group = icons.ui.Gear         .. "  UI / Toggles"         },
          { "<leader>v",  group = icons.git.commit      .. "  Version Control"       },
          { "<leader>w",  group = icons.ui.Stacks       .. "  Windows"               },
          { "<leader>x",  group = icons.ui.List         .. "  Diagnostics / Lists"   },
          { "<leader>y",  group = icons.ui.Copy         .. "  Yank"                  },
          { "<leader>z",  group = icons.ui.Eye          .. "  Zen / Focus"           },
          { "<leader>.",  group = icons.ui.Note         .. "  Scratch"               },
  
          -- ── Buffer sub-groups ────────────────────────────────────────────
          { "<leader>bd", group = icons.ui.Close        .. "  Delete buffer"         },
          { "<leader>bo", group = icons.ui.Files        .. "  Buffer operations"     },
  
          -- ── Code / LSP sub-groups ────────────────────────────────────────
          { "<leader>ca", group = icons.ui.Lightbulb    .. "  Code actions"          },
          { "<leader>cd", group = icons.diagnostics.Hint .. "  Definitions"          },
          { "<leader>cf", group = icons.status.formatter .. "  Format"               },
          { "<leader>ci", group = icons.ui.Info         .. "  Info / Hover"          },
          { "<leader>cr", group = icons.ui.Rename       .. "  Rename"                },
          { "<leader>cs", group = icons.ui.List         .. "  Symbols"               },
          { "<leader>cm", group = icons.misc.mason      .. "  Mason"                 },
  
          -- ── Debug sub-groups ─────────────────────────────────────────────
          { "<leader>db", group = icons.dap.Breakpoint  .. "  Breakpoints"           },
          { "<leader>dp", group = icons.ui.Graph        .. "  Profiler"              },
          { "<leader>ds", group = icons.dap.step_over   .. "  Step"                  },
          { "<leader>dt", group = icons.test.suite      .. "  Test (Neotest)"        },
          { "<leader>du", group = icons.ui.Table        .. "  DAP UI"                },
  
          -- ── Find / Telescope sub-groups ──────────────────────────────────
          { "<leader>fb", group = icons.ui.BookMark     .. "  Bookmarks"             },
          { "<leader>fc", group = icons.ui.Code         .. "  Code search"           },
          { "<leader>fg", group = icons.git.branch      .. "  Git search"            },
          { "<leader>fl", group = icons.ui.List         .. "  Lists"                 },
  
          -- ── Git sub-groups ───────────────────────────────────────────────
          { "<leader>gb", group = icons.git.branch      .. "  Branch"                },
          { "<leader>gc", group = icons.git.commit      .. "  Commits"               },
          { "<leader>gd", group = icons.git.diff_change .. "  Diff"                  },
          { "<leader>gp", group = icons.git.push        .. "  Push / Pull"           },
          { "<leader>gs", group = icons.git.added       .. "  Stage / Unstage"       },
  
          -- ── UI Toggles sub-groups ────────────────────────────────────────
          { "<leader>uC", group = icons.ui.Circle       .. "  Colorizer"             },
          { "<leader>ub", group = icons.ui.BoldArrowDown .. "  Background"           },
  
          -- ── Session / Quit ────────────────────────────────────────────────
          { "<leader>qa", group = icons.ui.Power        .. "  Quit all"              },
          { "<leader>qs", group = icons.ui.BookMark     .. "  Session"               },
  
          -- ── Window sub-groups ─────────────────────────────────────────────
          { "<leader>ws", group = icons.ui.Table        .. "  Split"                 },
          { "<leader>wt", group = icons.ui.Tab          .. "  Tab"                   },
  
          -- ── Tab management ────────────────────────────────────────────────
          { "<leader><Tab>", group = icons.ui.Tab       .. "  Tabs"                  },
  
          -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          -- Bracket pairs (next/prev navigation)
          -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          { "]",  group = icons.ui.ArrowRight .. "  Next"   },
          { "[",  group = icons.ui.ArrowLeft  .. "  Prev"   },
  
          -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          -- g-prefix (goto / go)
          -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          { "g",  group = icons.ui.ChevronRight .. " Go"    },
  
          -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          -- z-prefix (fold / view)
          -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          { "z",  group = icons.ui.Triangle  .. " Fold / View"  },
  
          -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          -- Visual mode leader
          -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          {
            mode  = { "v", "x" },
            { "<leader>g",  group = icons.git.branch   .. "  Git (visual)"    },
            { "<leader>c",  group = icons.ui.Code      .. "  Code (visual)"   },
            { "<leader>r",  group = icons.ui.Refresh   .. "  Refactor (visual)" },
            { "<leader>s",  group = icons.ui.Search    .. "  Search (visual)" },
            { "<leader>y",  group = icons.ui.Copy      .. "  Yank (visual)"   },
            { "<leader>d",  group = icons.ui.Trash     .. "  Delete (visual)" },
            { "<leader>f",  group = icons.status.formatter .. "  Format (visual)" },
          },
  
          -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          -- Operator-pending mode
          -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          {
            mode = { "o" },
            { "i",  group = "inside" },
            { "a",  group = "around" },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Show help text at bottom of popup
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        show_help   = true,
        show_keys   = true,
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Disable for these filetypes
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        disable      = {
          ft = { "TelescopePrompt", "noice", "neo-tree" },
          bt = { "terminal", "nofile" },
        },
      }
    end,
  
    -- ── config ────────────────────────────────────────────────────────────────
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
  
      -- ── Highlight groups ──────────────────────────────────────────────────
      local function apply_hl()
        local p = {}
        pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
        local base    = p.base     or "#1e1e2e"
        local surface = p.surface0 or "#313244"
        local surface1 = p.surface1 or "#45475a"
        local overlay = p.overlay0 or "#6c7086"
        local text    = p.text     or "#cdd6f4"
        local blue    = p.blue     or "#89b4fa"
        local green   = p.green    or "#a6e3a1"
        local yellow  = p.yellow   or "#f9e2af"
        local red     = p.red      or "#f38ba8"
        local mauve   = p.mauve    or "#cba6f7"
        local peach   = p.peach    or "#fab387"
        local teal    = p.teal     or "#94e2d5"
        local lavend  = p.lavender or "#b4befe"
  
        local hls = {
          -- Popup window
          WhichKeyFloat       = { bg = surface,  fg = text                      },
          WhichKeyBorder      = { bg = surface,  fg = overlay                   },
          WhichKeyTitle       = { bg = surface,  fg = mauve,  bold = true       },
          WhichKeyCursorLine  = { bg = surface1, fg = text,   bold = true       },
          -- Keys
          WhichKey            = { fg = blue,    bold  = true                    },
          WhichKeyGroup       = { fg = mauve,   italic = true                   },
          WhichKeyDesc        = { fg = text                                      },
          WhichKeySeparator   = { fg = overlay                                  },
          WhichKeyValue       = { fg = overlay, italic = true                   },
          -- Breadcrumb
          WhichKeyBreadcrumb  = { fg = overlay                                  },
          -- Icon colours
          WhichKeyIconAzure   = { fg = blue                                     },
          WhichKeyIconBlue    = { fg = blue                                     },
          WhichKeyIconCyan    = { fg = teal                                     },
          WhichKeyIconGreen   = { fg = green                                    },
          WhichKeyIconGrey    = { fg = overlay                                  },
          WhichKeyIconOrange  = { fg = peach                                    },
          WhichKeyIconPurple  = { fg = mauve                                    },
          WhichKeyIconRed     = { fg = red                                      },
          WhichKeyIconYellow  = { fg = yellow                                   },
          -- Normal text inside popup
          WhichKeyNormal      = { bg = surface,  fg = text                      },
        }
  
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
    end,
  }