-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/noice.lua — UI Overhaul (cmdline, messages, popups)         ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: folke/noice.nvim                                                    ║
-- ║  Features:                                                                   ║
-- ║    • Floating cmdline with icon prefix per command type                     ║
-- ║    • Beautiful message history (:messages → :Noice)                         ║
-- ║    • LSP signature + hover in styled float                                  ║
-- ║    • Popupmenu with devicons                                                ║
-- ║    • Search count virtual text                                              ║
-- ║    • Progress notifications for LSP operations                             ║
-- ║    • Mini notification popups (bottom-right, auto-dismiss)                 ║
-- ║    • Telescope integration (:Noice telescope)                               ║
-- ║    • Fully routed: messages that are noise are silenced                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "folke/noice.nvim",
    event   = "VeryLazy",
    version = "*",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      { "<leader>nl",  "<Cmd>Noice last<CR>",     desc = "󱓂  Noice last message"    },
      { "<leader>nh",  "<Cmd>Noice history<CR>",  desc = "󱓂  Noice history"          },
      { "<leader>nd",  "<Cmd>Noice dismiss<CR>",  desc = "󱓂  Noice dismiss all"      },
      { "<leader>nT",  "<Cmd>Noice telescope<CR>",desc = "󱓂  Noice (Telescope)"      },
      { "<leader>ne",  "<Cmd>Noice errors<CR>",   desc = "󱓂  Noice errors"           },
      { "<S-Enter>",   function() require("noice").redirect(vim.fn.getcmdline()) end,
        mode = "c",                               desc = "󱓂  Redirect cmdline"       },
      { "<C-f>",
        function()
          if not require("noice.lsp").scroll(4) then return "<C-f>" end
        end,
        silent = true, expr = true, desc = "Scroll forward in docs", mode = { "i", "n", "s" } },
      { "<C-b>",
        function()
          if not require("noice.lsp").scroll(-4) then return "<C-b>" end
        end,
        silent = true, expr = true, desc = "Scroll back in docs",    mode = { "i", "n", "s" } },
    },
  
    opts = function()
      local icons = Ash.icons
  
      -- ── nvim-notify backend config ────────────────────────────────────────
      -- Set up notify BEFORE noice uses it
      local ok_n, notify = pcall(require, "notify")
      if ok_n then
        notify.setup({
          render          = "wrapped-compact",
          stages          = "slide",
          timeout         = 3000,
          max_width       = 60,
          max_height      = 12,
          minimum_width   = 16,
          fps             = 60,
          top_down        = false,
          background_colour = "NotifyBackground",
          on_open         = function(win)
            vim.api.nvim_win_set_config(win, { zindex = 200 })
            if vim.fn.has("nvim-0.9") then
              vim.wo[win].winblend = 5
            end
          end,
          icons = {
            DEBUG = icons.misc.debug,
            ERROR = icons.misc.error,
            INFO  = icons.misc.info,
            TRACE = icons.misc.trace,
            WARN  = icons.misc.warn,
          },
          level           = vim.log.levels.TRACE,
        })
        vim.notify = notify
      end
  
      return {
        -- ── Command line ─────────────────────────────────────────────────────
        cmdline = {
          enabled  = true,
          view     = "cmdline_popup",
          opts     = {
            position = {
              row  = "50%",
              col  = "50%",
            },
            size = {
              min_width = 60,
              width     = "auto",
            },
            border = {
              style   = "rounded",
              padding = { 0, 1 },
            },
            win_options = {
              winhighlight = {
                Normal        = "NoiceCmdlinePopup",
                FloatBorder   = "NoiceCmdlinePopupBorder",
                CursorLine    = "NoiceCmdlinePopupCursorLine",
              },
            },
          },
          format = {
            -- Each command type: { pattern, icon, language, title }
            cmdline      = { pattern = "^:", icon = icons.ui.ChevronRight, lang = "vim",   title = " Command"    },
            search_down  = { kind = "search", pattern = "^/", icon = icons.ui.Search .. " ", lang = "regex", title = " Search ↓" },
            search_up    = { kind = "search", pattern = "^%?", icon = icons.ui.Search .. " ", lang = "regex", title = " Search ↑" },
            filter       = { pattern = "^:%s*!", icon = icons.ui.Terminal, lang = "bash",  title = " Shell"      },
            lua          = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" },
                             icon = icons.lang.lua, lang = "lua", title = " Lua"          },
            help         = { pattern = "^:%s*he?l?p?%s+", icon = icons.ui.Question,       title = " Help"       },
            input        = { view = "cmdline_input", icon = icons.ui.Edit                                        },
          },
        },
  
        -- ── Messages ─────────────────────────────────────────────────────────
        messages = {
          enabled        = true,
          view           = "notify",
          view_error     = "notify",
          view_warn      = "notify",
          view_history   = "messages",
          view_search    = "virtualtext",
        },
  
        -- ── Pop-up menu ───────────────────────────────────────────────────────
        popupmenu = {
          enabled  = true,
          backend  = "nui",        -- "nui" | "cmp"
          kind_icons = icons.kinds,
        },
  
        -- ── Redirect ─────────────────────────────────────────────────────────
        redirect = {
          view  = "popup",
          filter = { event = "msg_show" },
        },
  
        -- ── Commands ─────────────────────────────────────────────────────────
        commands = {
          history = {
            view      = "split",
            opts      = { enter = true, format = "details" },
            filter    = {
              any = {
                { event = "notify"                 },
                { error = true                     },
                { warning = true                   },
                { event = "msg_show", kind = { "" } },
                { event = "lsp",      kind = "message" },
              },
            },
          },
          last = {
            view      = "popup",
            opts      = { enter = true, format = "details" },
            filter    = {
              any = {
                { event = "notify"                        },
                { error = true                            },
                { warning = true                          },
                { event = "msg_show", kind = { "" }       },
                { event = "lsp",      kind = "message"    },
              },
            },
            filter_opts = { count = 1 },
          },
          errors = {
            view      = "popup",
            opts      = { enter = true, format = "details" },
            filter    = { error = true },
            filter_opts = { reverse = true },
          },
        },
  
        -- ── Notification ─────────────────────────────────────────────────────
        notify = {
          enabled = true,
          view    = "notify",
        },
  
        -- ── LSP ──────────────────────────────────────────────────────────────
        lsp = {
          progress = {
            enabled         = true,
            format          = "lsp_progress",
            format_done     = "lsp_progress_done",
            throttle        = 1000 / 30, -- 30fps
            view            = "mini",
          },
          override = {
            -- Use noice for LSP hover / signature / completion docs
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"]                = true,
            ["cmp.entry.get_documentation"]                  = true,
          },
          hover = {
            enabled = true,
            silent  = false,
            view    = nil, -- uses default
          },
          signature = {
            enabled  = true,
            auto_open = {
              enabled    = true,
              trigger    = true,
              luasnip    = true,
              throttle   = 50,
            },
            view     = nil,
          },
          message = {
            enabled = true,
            view    = "notify",
            opts    = {},
          },
          documentation = {
            view = "hover",
            opts = {
              lang          = "markdown",
              replace       = true,
              render        = "plain",
              format        = { "{message}" },
              win_options   = { concealcursor = "n", conceallevel = 3 },
              border        = { style = "rounded", padding = { 0, 1 } },
            },
          },
        },
  
        -- ── Routes (silence known noise) ─────────────────────────────────────
        routes = {
          -- ❶ Silence "written" messages
          {
            filter = { event = "msg_show", kind = "", find = "written" },
            opts   = { skip = true },
          },
          -- ❷ Silence search count messages (shown by lualine searchcount)
          {
            filter = { event = "msg_show", find = "%d+/%d+" },
            opts   = { skip = true },
          },
          -- ❸ Silence "already at newest change" and similar
          {
            filter = {
              event = "msg_show",
              any = {
                { find = "Already at newest change" },
                { find = "Already at oldest change" },
              },
            },
            opts = { skip = true },
          },
          -- ❹ Silence inccommand preview messages
          {
            filter = {
              event = "msg_show",
              kind  = "search_count",
            },
            opts = { skip = true },
          },
          -- ❺ Long messages → split view
          {
            filter = {
              event     = "msg_show",
              min_height = 5,
            },
            view = "split",
          },
          -- ❻ LSP progress → mini (bottom-right, non-intrusive)
          {
            filter = {
              event     = "lsp",
              kind      = "progress",
            },
            view = "mini",
            opts = { timeout = 5000 },
          },
          -- ❼ Errors → full notify popup
          {
            filter = { error = true },
            view   = "notify",
            opts   = { level = vim.log.levels.ERROR },
          },
        },
  
        -- ── Presets ──────────────────────────────────────────────────────────
        presets = {
          bottom_search         = false,  -- we position cmdline center
          command_palette       = true,   -- show cmdline popup
          long_message_to_split = true,   -- route long messages to split
          inc_rename            = true,   -- inc-rename integration
          lsp_doc_border        = true,   -- border around LSP doc windows
        },
  
        -- ── Views ────────────────────────────────────────────────────────────
        views = {
          -- Mini (bottom-right corner, LSP progress etc.)
          mini = {
            backend  = "mini",
            relative = "editor",
            align    = "message-right",
            timeout  = 3000,
            reverse  = true,
            position = { row = -2, col = "100%" },
            size     = { max_height = 8, width = "auto" },
            border   = { style = "none" },
            zindex   = 60,
            win_options = {
              winblend    = 20,
              winhighlight = {
                Normal      = "NoiceMini",
                IncSearch   = "",
                CurSearch   = "",
                Search      = "",
              },
            },
          },
          -- Cmdline popup
          cmdline_popup = {
            border   = { style = "rounded", padding = { 0, 1 } },
            position = { row = "40%", col = "50%" },
            size     = { width = 60, height = "auto" },
            win_options = {
              winblend    = 5,
              winhighlight = {
                Normal      = "NoiceCmdlinePopup",
                FloatBorder = "NoiceCmdlinePopupBorder",
              },
            },
          },
          -- Hover / signature
          hover = {
            view     = "popup",
            relative = "cursor",
            zindex   = 45,
            enter    = false,
            anchor   = "auto",
            size     = { width = "auto", height = "auto", max_height = 20, max_width = 80 },
            border   = { style = "rounded", padding = { 0, 1 } },
            position = { row = 1, col = 0 },
            win_options = {
              wrap        = true,
              linebreak   = true,
              winblend    = 8,
            },
          },
          -- Full popup
          popup = {
            border  = { style = "rounded", padding = { 0, 1 } },
            zindex  = 65,
            size    = { width = "80%", height = "60%" },
            win_options = {
              winblend = 5,
              winhighlight = {
                Normal      = "NoicePopup",
                FloatBorder = "NoicePopupBorder",
              },
            },
          },
          -- Confirm dialog
          confirm = {
            border  = { style = "rounded", padding = { 0, 1 } },
            position = { row = "50%", col = "50%" },
            size    = { width = "auto", height = "auto" },
            win_options = {
              winblend = 8,
              winhighlight = {
                Normal = "NoiceConfirm",
                FloatBorder = "NoiceConfirmBorder",
              },
            },
          },
        },
  
        -- ── Format strings ───────────────────────────────────────────────────
        format = {
          default         = { "{level} ", "{title} ", "{message}" },
          notify          = { "{message}", "{title}", "{level}" },
          details         = {
            "{level} ", "{date} ", "{title}\n", "{cmdline} ",
            "{counter} ", "{message|buf}", "\n{traceback}",
          },
          lsp_progress = {
            "{progress} ", "{spinner} ", "{title} ", "{message}",
          },
          lsp_progress_done = {
            { icons.diagnostics.ok, "NoiceLspProgressSpinnerDone" },
            " ",
            { "{data.progress.title}",  "NoiceLspProgressTitle"  },
            " ",
            { "{data.progress.client}", "NoiceLspProgressClient" },
          },
        },
  
        -- ── Throttle / performance ────────────────────────────────────────────
        throttle = 1000 / 30, -- max 30 redraws/sec
      }
    end,
  
    config = function(_, opts)
      -- Workaround: some ftplugins reset cmdheight; ensure noice can run
      if vim.o.cmdheight == 0 then
        vim.o.cmdheight = 0
      end
  
      require("noice").setup(opts)
  
      -- Telescope extension
      pcall(require("telescope").load_extension, "noice")
  
      -- Custom highlight groups (merged from colorscheme at runtime)
      local function set_noice_hl()
        local p = {}
        pcall(function()
          p = require("catppuccin.palettes").get_palette() or {}
        end)
  
        local surface = p.surface0 or "#313244"
        local overlay = p.overlay0  or "#6c7086"
        local base    = p.base      or "#1e1e2e"
        local text    = p.text      or "#cdd6f4"
        local blue    = p.blue      or "#89b4fa"
        local red     = p.red       or "#f38ba8"
        local yellow  = p.yellow    or "#f9e2af"
        local mauve   = p.mauve     or "#cba6f7"
  
        local hls = {
          NoiceCmdlinePopup        = { bg = surface,  fg = text   },
          NoiceCmdlinePopupBorder  = { fg = blue,   bg = surface  },
          NoiceCmdlinePopupCursorLine = { bg = base },
          NoiceCmdlineIcon         = { fg = mauve                 },
          NoicePopup               = { bg = surface,  fg = text   },
          NoicePopupBorder         = { fg = overlay,  bg = surface },
          NoiceConfirm             = { bg = surface,  fg = text   },
          NoiceConfirmBorder       = { fg = yellow,   bg = surface },
          NoiceMini                = { fg = text,     bg = base   },
          NoiceLspProgressTitle    = { fg = blue,   gui = "bold"  },
          NoiceLspProgressClient   = { fg = mauve                 },
          NotifyBackground         = { bg = base                  },
          NoiceBackground          = { bg = base                  },
        }
  
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      set_noice_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_noice_hl })
    end,
  }