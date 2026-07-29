-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/snacks.lua — Snacks.nvim Mega-Plugin Suite                  ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: folke/snacks.nvim                                                   ║
-- ║                                                                              ║
-- ║  Snacks modules enabled:                                                     ║
-- ║    bigfile      — disable heavy features for large files                    ║
-- ║    dashboard    — beautiful startscreen (pairs with alpha)                  ║
-- ║    debug        — pretty-print debug helper                                 ║
-- ║    dim          — focus dimming (pairs with zen-mode)                       ║
-- ║    git          — git helpers                                                ║
-- ║    gitbrowse    — open file/line on GitHub                                  ║
-- ║    indent       — animated indent guides                                    ║
-- ║    input        — beautiful vim.ui.input replacement                        ║
-- ║    lazygit      — lazygit float integration                                 ║
-- ║    notifier     — rich notification system                                  ║
-- ║    profiler     — startup profiler                                           ║
-- ║    quickfile    — fast file opener                                           ║
-- ║    rename       — LSP-aware buffer rename                                   ║
-- ║    scope        — animated scope highlights                                 ║
-- ║    scroll       — smooth scrolling                                          ║
-- ║    statuscolumn — rich sign / fold column                                   ║
-- ║    terminal     — terminal float / split                                    ║
-- ║    toggle       — togglable options with status                             ║
-- ║    win          — smart window helpers                                      ║
-- ║    words        — LSP word references highlight                             ║
-- ║    zen          — distraction-free writing                                  ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy     = false,
    version  = "*",
  
    -- ── Keys ──────────────────────────────────────────────────────────────────
    keys = {
      -- ── Scratch / Notes ───────────────────────────────────────────────────
      { "<leader>.",   function() Snacks.scratch()              end,  desc = "󱦜  Toggle scratch buffer"     },
      { "<leader>S",   function() Snacks.scratch.select()       end,  desc = "󱦜  Select scratch buffer"     },
      -- ── Files ─────────────────────────────────────────────────────────────
      { "<leader>fR",  function() Snacks.rename.rename_file()   end,  desc = "󰑕  Rename file"               },
      -- ── Git ───────────────────────────────────────────────────────────────
      { "<leader>gb",  function() Snacks.git.blame_line()       end,  desc = "  Git blame line"            },
      { "<leader>gB",  function() Snacks.gitbrowse()            end,  desc = "  Git browse (GitHub)"       },
      { "<leader>gf",  function() Snacks.lazygit.log_file()     end,  desc = "  Lazygit file log"          },
      { "<leader>gF",  function() Snacks.lazygit()              end,  desc = "  Lazygit float"             },
      { "<leader>gl",  function() Snacks.lazygit.log()          end,  desc = "  Lazygit log"               },
      -- ── Terminal ──────────────────────────────────────────────────────────
      { "<leader>tt",  function() Snacks.terminal()             end,  desc = "  Toggle terminal (float)"   },
      { "<leader>tT",  function() Snacks.terminal.open()        end,  desc = "  Open terminal"             },
      { [[<C-\>]],     function() Snacks.terminal()             end,  desc = "  Toggle terminal",   mode = { "n", "t" } },
      -- ── Zen / Focus ───────────────────────────────────────────────────────
      { "<leader>z",   function() Snacks.zen()                  end,  desc = "  Zen mode"                  },
      { "<leader>Z",   function() Snacks.zen.zoom()             end,  desc = "  Zoom window"               },
      -- ── Toggle options ────────────────────────────────────────────────────
      { "<leader>uw",  function() Snacks.toggle.option("wrap")             :map("<leader>uw") end, desc = "  Toggle wrap"         },
      { "<leader>un",  function() Snacks.toggle.option("relativenumber")   :map("<leader>un") end, desc = "  Toggle rel-numbers"  },
      { "<leader>uL",  function() Snacks.toggle.option("cursorline")       :map("<leader>uL") end, desc = "  Toggle cursorline"   },
      { "<leader>ud",  function() Snacks.toggle.diagnostics()              :map("<leader>ud") end, desc = "󰒡  Toggle diagnostics"   },
      { "<leader>uc",  function() Snacks.toggle.option("conceallevel", { off = 0, on = 2 }):map("<leader>uc") end, desc = "  Toggle conceal" },
      { "<leader>uT",  function() Snacks.toggle.treesitter()               :map("<leader>uT") end, desc = "  Toggle treesitter"   },
      { "<leader>uf",  function() Snacks.toggle.format()                   :map("<leader>uf") end, desc = "  Toggle format-on-save" },
      { "<leader>us",  function() Snacks.toggle.option("spell")            :map("<leader>us") end, desc = "  Toggle spell"        },
      { "<leader>ui",  function() Snacks.toggle.inlay_hints()              :map("<leader>ui") end, desc = "  Toggle inlay hints"  },
      { "<leader>uI",  function() Snacks.toggle.indent()                   :map("<leader>uI") end, desc = "  Toggle indent guides" },
      { "<leader>uD",  function() Snacks.toggle.dim()                      :map("<leader>uD") end, desc = "  Toggle dim unfocused" },
      -- ── Words / Navigation ─────────────────────────────────────────────
      { "]]",          function() Snacks.words.jump(vim.v.count1)           end, desc = "  Next word reference", mode = { "n", "t" } },
      { "[[",          function() Snacks.words.jump(-vim.v.count1)          end, desc = "  Prev word reference", mode = { "n", "t" } },
      -- ── Debug / Profiler ──────────────────────────────────────────────────
      { "<leader>dps", function() Snacks.profiler.scratch()    end, desc = "  Profiler scratch"   },
      { "<leader>dpp", function() Snacks.profiler()            end, desc = "  Toggle profiler"    },
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
      local surface = p.surface1 or "#313244"
      local overlay = p.overlay0 or "#6c7086"
      local text    = p.text     or "#cdd6f4"
      local blue    = p.blue     or "#89b4fa"
      local green   = p.green    or "#a6e3a1"
      local yellow  = p.yellow   or "#f9e2af"
      local red     = p.red      or "#f38ba8"
      local mauve   = p.mauve    or "#cba6f7"
      local teal    = p.teal     or "#94e2d5"
      local peach   = p.peach    or "#fab387"
  
      return {
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- bigfile — graceful degradation for large files
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        bigfile = {
          enabled   = true,
          size      = Ash.perf.bigfile_size,        -- 256 KB from global
          notify    = true,
          setup     = function(ctx)
            vim.b[ctx.buf].large_file = true
            -- Notify once
            vim.notify(
              string.format(
                "📦 Large file: %s (%dKB) — performance mode",
                vim.fn.fnamemodify(ctx.file, ":t"),
                math.floor(ctx.size / 1024)
              ),
              vim.log.levels.WARN,
              { title = "ASH NeoVim" }
            )
          end,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- debug — Snacks.debug pretty-printer
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        debug = { enabled = true },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- dim — dim unfocused code blocks
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        dim = {
          enabled   = true,
          scope     = {
            min_size  = 5,
            max_size  = 20,
            siblings  = true,
          },
          animate   = {
            enabled  = Ash.flags.enable_animations,
            easing   = "outQuad",
            duration = { step = 20, total = 300 },
          },
          filter    = function(buf)
            return vim.g.snacks_dim ~= false
              and not vim.b[buf].large_file
              and vim.bo[buf].buftype == ""
          end,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- git / gitbrowse
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        git = { enabled = true },
        gitbrowse = {
          enabled  = true,
          notify   = true,
          open     = function(url)
            if vim.fn.executable("xdg-open") == 1 then
              vim.fn.jobstart({ "xdg-open", url }, { detach = true })
            else
              vim.notify("Open: " .. url, vim.log.levels.INFO, { title = "Git Browse" })
            end
          end,
          -- Supported remote patterns
          remote_patterns = {
            { "^https://github%.com/(.+)%.git$",    "https://github.com/%1"    },
            { "^git@github%.com:(.+)%.git$",        "https://github.com/%1"    },
            { "^https://gitlab%.com/(.+)%.git$",    "https://gitlab.com/%1"    },
            { "^git@gitlab%.com:(.+)%.git$",        "https://gitlab.com/%1"    },
            { "^https://bitbucket%.org/(.+)%.git$", "https://bitbucket.org/%1" },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- indent — animated indent guides
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        indent = {
          enabled   = true,
          indent = {
            char      = "│",
            hl        = {
              "SnacksIndent1",
              "SnacksIndent2",
              "SnacksIndent3",
              "SnacksIndent4",
              "SnacksIndent5",
              "SnacksIndent6",
              "SnacksIndent7",
              "SnacksIndent8",
            },
          },
          -- Animated scope highlight
          scope = {
            enabled   = true,
            char      = "│",
            underline = false,
            hl        = "SnacksIndentScope",
            animate   = {
              enabled  = Ash.flags.enable_animations,
              easing   = "linear",
              duration = { step = 20, total = 500 },
            },
          },
          chunk = {
            enabled   = false,     -- use scope instead
            char = {
              corner_top    = "╭",
              corner_bottom = "╰",
              horizontal    = "─",
              vertical      = "│",
              arrow         = "›",
            },
            hl = "SnacksIndentChunk",
          },
          -- Filter: disable for certain filetypes
          filter = function(buf)
            return vim.g.snacks_indent ~= false
              and vim.bo[buf].buftype == ""
              and not vim.b[buf].large_file
          end,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- input — vim.ui.input replacement
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        input = {
          enabled = true,
          icon    = icons.ui.Edit,
          icon_hl = "SnacksInputIcon",
          icon_pos = "left",
          prompt_pos = "title",
          win = {
            style = "input",
            border = "rounded",
            position = "float",
            row = -3,
            width = 60,
            relative = "editor",
          },
          expand = true,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- lazygit — floating lazygit window
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        lazygit = {
          enabled    = vim.fn.executable("lazygit") == 1,
          configure  = true,
          config     = {
            os            = { editPreset = "nvim-remote" },
            gui           = {
              nerdFontsVersion = "3",
              theme = {
                activeBorderColor      = { blue,  "bold" },
                inactiveBorderColor    = { overlay         },
                optionsTextColor       = { blue             },
                selectedLineBgColor    = { surface          },
                cherryPickedCommitBgColor = { teal           },
                cherryPickedCommitFgColor = { base           },
                unstagedChangesColor   = { red               },
                defaultFgColor         = { text              },
                searchingActiveBorderColor = { yellow        },
              },
            },
          },
          -- Size: 95% of editor
          win = {
            style  = "lazygit",
            width  = 0,
            height = 0,
            border = "rounded",
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- notifier — Snacks.notify (used when noice is disabled)
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        notifier = {
          enabled  = false,        -- noice.nvim handles notifications
          timeout  = 3000,
          width    = { min = 10, max = 0.4 },
          height   = { min = 1,  max = 0.6 },
          margin   = { top = 0, right = 1, bottom = 0 },
          padding  = true,
          sort     = { "level", "added" },
          level    = vim.log.levels.TRACE,
          icons    = {
            error  = icons.misc.error,
            warn   = icons.misc.warn,
            info   = icons.misc.info,
            debug  = icons.misc.debug,
            trace  = icons.misc.trace,
          },
          style    = "compact",
          top_down = false,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- profiler
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        profiler = {
          enabled    = true,
          autocmds   = true,
          runtime    = vim.env.VIMRUNTIME,
          thresholds = {
            time  = 2,      -- ms
            pct   = 0.5,    -- percent
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- quickfile — fast file open (bypasses usual buffer setup for speed)
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        quickfile = { enabled = true },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- rename — LSP-aware file rename
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        rename = { enabled = true },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- scope — animated scope indicator
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        scope = {
          enabled  = true,
          animate  = {
            enabled  = Ash.flags.enable_animations,
            easing   = "outQuad",
            duration = { step = 20, total = 300 },
          },
          cursor   = true,
          edge     = true,
          treesitter = {
            enabled  = true,
            blocks   = {
              enabled = false,        -- indent module handles this
            },
          },
          filter = function(buf)
            return vim.bo[buf].buftype == ""
              and not vim.b[buf].large_file
          end,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- scroll — smooth scrolling
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        scroll = {
          enabled   = Ash.flags.enable_animations,
          animate   = {
            easing   = "linear",
            duration = { step = 15, total = 250 },
          },
          filter    = function(buf)
            return vim.g.snacks_scroll ~= false
              and not vim.b[buf].large_file
              and vim.bo[buf].buftype == ""
          end,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- statuscolumn — rich left gutter
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        statuscolumn = {
          enabled = true,
          left    = { "mark", "sign" },      -- left of number
          right   = { "fold", "git" },       -- right of number
          folds   = {
            open   = true,
            git_hl = true,
          },
          git     = { patterns = { "GitSign", "MiniDiffSign" } },
          refresh = 50,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- terminal — floating terminal
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        terminal = {
          enabled = true,
          win     = {
            style   = "terminal",
            border  = "rounded",
            width   = 0.85,
            height  = 0.80,
            wo      = { winblend = 5 },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- toggle — togglable options
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        toggle = {
          enabled  = true,
          map      = vim.keymap.set,
          which_key = true,
          notify   = true,
          -- Custom on/off icons per toggle
          icon     = { enabled = icons.ui.Check, disabled = icons.ui.Close },
          color    = { enabled = "green", disabled = "yellow" },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- win — smart window utilities
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        win = { enabled = true },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- words — highlight word references
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        words = {
          enabled     = true,
          debounce    = 200,
          notify_jump = true,
          notify_end  = false,
          modes       = { "n", "i", "c" },
          filter      = function(buf)
            return not vim.b[buf].large_file
              and vim.bo[buf].buftype == ""
          end,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- zen — distraction-free mode
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        zen = {
          enabled  = true,
          toggle   = { dim = true, git_signs = false, mini_diff_signs = false },
          show     = { statusline = false, tabline = false },
          win      = {
            backdrop = { transparent = true, blend = 40 },
            width    = 100,
            wo       = {
              signcolumn      = "no",
              statuscolumn    = "",
              number          = false,
              relativenumber  = false,
              foldcolumn      = "0",
              colorcolumn     = "",
            },
          },
          zoom = {
            toggles  = {},
            show     = { statusline = true, tabline = true },
            win      = { backdrop = false, width = 0 },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- styles — shared window style presets
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        styles = {
          notification      = { border = "rounded", wo = { winblend = 8 } },
          notification_history = {
            border = "rounded",
            width  = 0.85,
            height = 0.8,
          },
          input = {
            border   = "rounded",
            relative = "cursor",
            row      = -3,
            col      = 0,
            wo       = { winblend = 5 },
          },
          lazygit = {
            width  = 0,
            height = 0,
            border = "rounded",
            wo     = { winblend = 3 },
          },
        },
      }
    end,
  
    -- ── config ────────────────────────────────────────────────────────────────
    config = function(_, opts)
      -- Store global reference used by keys above
      ---@diagnostic disable-next-line: lowercase-global
      _G.Snacks = require("snacks")
      require("snacks").setup(opts)
  
      -- ── Highlight groups ──────────────────────────────────────────────────
      local function apply_hl()
        local p = {}
        pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
        local base    = p.base     or "#1e1e2e"
        local surface = p.surface1 or "#313244"
        local overlay = p.overlay0 or "#6c7086"
        local blue    = p.blue     or "#89b4fa"
        local green   = p.green    or "#a6e3a1"
        local yellow  = p.yellow   or "#f9e2af"
        local red     = p.red      or "#f38ba8"
        local mauve   = p.mauve    or "#cba6f7"
        local teal    = p.teal     or "#94e2d5"
        local peach   = p.peach    or "#fab387"
  
        -- Rainbow indent guides
        local rainbow = { blue, yellow, green, red, mauve, peach, teal, "#f5c2e7" }
        for i, colour in ipairs(rainbow) do
          vim.api.nvim_set_hl(0, "SnacksIndent" .. i, { fg = colour, nocombine = true })
        end
  
        local hls = {
          SnacksIndentScope   = { fg = mauve,   nocombine = true },
          SnacksIndentChunk   = { fg = overlay                   },
          SnacksInputIcon     = { fg = blue,    bold = true      },
          SnacksInputBorder   = { fg = overlay, bg = surface     },
          SnacksDimmerDimmed  = { fg = overlay                   },
          SnacksScrollAnimate = { fg = overlay                   },
        }
  
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
  
      -- ── Init autocmds ─────────────────────────────────────────────────────
      vim.api.nvim_create_autocmd("User", {
        pattern  = "VeryLazy",
        once     = true,
        callback = function()
          -- Register Snacks debug helper globally
          _G.dd = function(...) Snacks.debug.inspect(...) end
          _G.bt = function(...) Snacks.debug.backtrace(...) end
          vim.print = _G.dd
        end,
      })
    end,
  }