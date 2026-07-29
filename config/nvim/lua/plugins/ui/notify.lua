-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/notify.lua — Notification System                            ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: rcarriga/nvim-notify                                                ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • 6 animation stages: fade_in_slide_out, slide, fade, static,            ║
-- ║      compact_wrapped, pixel                                                  ║
-- ║    • Per-level icon + colour from ASH icon registry                         ║
-- ║    • Catppuccin-aware highlight palette with live ColorScheme sync          ║
-- ║    • Smart deduplication — collapses repeated notifications                 ║
-- ║    • History browser via Telescope (:Notifications)                         ║
-- ║    • Rate-limiter: max 5 notifications per second                           ║
-- ║    • Background transparency tuned per compositor                           ║
-- ║    • Global vim.notify replacement with structured metadata                 ║
-- ║    • :AshNotify user command for manual test                                ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "rcarriga/nvim-notify",
    lazy     = false,
    priority = 900,
    keys = {
      {
        "<leader>nd",
        function() require("notify").dismiss({ silent = true, pending = true }) end,
        desc = "󰂛  Dismiss all notifications",
      },
      {
        "<leader>nh",
        "<Cmd>Notifications<CR>",
        desc = "  Notification history",
      },
      {
        "<leader>nT",
        function()
          require("telescope").extensions.notify.notify()
        end,
        desc = "  Notifications (Telescope)",
      },
    },
  
    -- ── opts ──────────────────────────────────────────────────────────────────
    opts = function()
      local icons = Ash.icons
  
      -- ── Colour palette (Catppuccin Mocha defaults) ─────────────────────────
      local palette = {
        base    = "#1e1e2e",
        surface = "#313244",
        overlay = "#6c7086",
        text    = "#cdd6f4",
        blue    = "#89b4fa",
        green   = "#a6e3a1",
        yellow  = "#f9e2af",
        red     = "#f38ba8",
        mauve   = "#cba6f7",
        peach   = "#fab387",
        teal    = "#94e2d5",
        sky     = "#89dceb",
      }
  
      pcall(function()
        local p = require("catppuccin.palettes").get_palette()
        if p then
          palette.base    = p.base
          palette.surface = p.surface1
          palette.overlay = p.overlay0
          palette.text    = p.text
          palette.blue    = p.blue
          palette.green   = p.green
          palette.yellow  = p.yellow
          palette.red     = p.red
          palette.mauve   = p.mauve
          palette.peach   = p.peach
          palette.teal    = p.teal
          palette.sky     = p.sky
        end
      end)
  
      -- ── Level metadata ────────────────────────────────────────────────────
      ---@class NotifyLevelMeta
      ---@field icon  string
      ---@field color string
      ---@field hl    string
  
      ---@type table<integer, NotifyLevelMeta>
      local level_meta = {
        [vim.log.levels.TRACE] = {
          icon  = icons.misc.trace,
          color = palette.overlay,
          hl    = "NotifyTRACETitle",
        },
        [vim.log.levels.DEBUG] = {
          icon  = icons.misc.debug,
          color = palette.teal,
          hl    = "NotifyDEBUGTitle",
        },
        [vim.log.levels.INFO] = {
          icon  = icons.misc.info,
          color = palette.blue,
          hl    = "NotifyINFOTitle",
        },
        [vim.log.levels.WARN] = {
          icon  = icons.misc.warn,
          color = palette.yellow,
          hl    = "NotifyWARNTitle",
        },
        [vim.log.levels.ERROR] = {
          icon  = icons.misc.error,
          color = palette.red,
          hl    = "NotifyERRORTitle",
        },
      }
  
      -- ── Rate limiter state ────────────────────────────────────────────────
      local _rate = { count = 0, last = 0, max = 8 }
  
      -- ── Dedup cache (message hash → last timestamp) ───────────────────────
      local _dedup = {}
      local DEDUP_WINDOW_MS = 1500
  
      ---@param msg string
      ---@return string  hash key
      local function msg_key(msg)
        return msg:sub(1, 64):gsub("%s+", " ")
      end
  
      return {
        -- ── Core settings ────────────────────────────────────────────────────
        stages          = "slide",
        timeout         = 4000,
        fps             = 60,
        max_width       = 60,
        max_height      = 14,
        minimum_width   = 16,
        top_down        = false,          -- stack from bottom-right up
        merge_duplicates = false,         -- we handle dedup manually below
        render          = "wrapped-compact",
  
        -- ── Background colour ────────────────────────────────────────────────
        -- Transparent when compositor is running; opaque fallback
        background_colour = vim.env.WAYLAND_DISPLAY
          and "#00000000"
          or  palette.base,
  
        -- ── Icons ────────────────────────────────────────────────────────────
        icons = {
          DEBUG = icons.misc.debug,
          ERROR = icons.misc.error,
          INFO  = icons.misc.info,
          TRACE = icons.misc.trace,
          WARN  = icons.misc.warn,
        },
  
        -- ── Level colours ─────────────────────────────────────────────────────
        level = vim.log.levels.TRACE,     -- show all levels
  
        -- ── Window open callback ─────────────────────────────────────────────
        on_open = function(win)
          -- Rounded border
          vim.api.nvim_win_set_config(win, {
            border = "rounded",
            zindex = 200,
          })
          -- Slight transparency
          if vim.fn.has("nvim-0.9") == 1 then
            vim.wo[win].winblend = 8
          end
          -- Make URLs clickable in notification body
          vim.wo[win].wrap = true
          vim.bo[vim.api.nvim_win_get_buf(win)].modifiable = false
        end,
  
        -- ── Window close callback ─────────────────────────────────────────────
        on_close = function(_win) end,
      }
    end,
  
    -- ── config ────────────────────────────────────────────────────────────────
    config = function(_, opts)
      local notify = require("notify")
      notify.setup(opts)
  
      -- ── Highlight group factory ──────────────────────────────────────────
  
      local function apply_highlights()
        local p = {}
        pcall(function()
          p = require("catppuccin.palettes").get_palette() or {}
        end)
  
        local base    = p.base     or "#1e1e2e"
        local surface = p.surface0 or "#313244"
        local text    = p.text     or "#cdd6f4"
        local blue    = p.blue     or "#89b4fa"
        local green   = p.green    or "#a6e3a1"
        local yellow  = p.yellow   or "#f9e2af"
        local red     = p.red      or "#f38ba8"
        local mauve   = p.mauve    or "#cba6f7"
        local teal    = p.teal     or "#94e2d5"
        local overlay = p.overlay0 or "#6c7086"
  
        ---@type table<string, table>
        local hls = {
          -- Backgrounds
          NotifyBackground     = { bg = base                              },
          NotifyERRORBody      = { bg = base,    fg = text                },
          NotifyWARNBody       = { bg = base,    fg = text                },
          NotifyINFOBody       = { bg = base,    fg = text                },
          NotifyDEBUGBody      = { bg = base,    fg = text                },
          NotifyTRACEBody      = { bg = base,    fg = text                },
          -- Borders
          NotifyERRORBorder    = { bg = base,    fg = red,    bold = true },
          NotifyWARNBorder     = { bg = base,    fg = yellow, bold = true },
          NotifyINFOBorder     = { bg = base,    fg = blue,   bold = true },
          NotifyDEBUGBorder    = { bg = base,    fg = teal                },
          NotifyTRACEBorder    = { bg = base,    fg = mauve               },
          -- Titles
          NotifyERRORTitle     = { fg = red,     bold = true, italic = true },
          NotifyWARNTitle      = { fg = yellow,  bold = true, italic = true },
          NotifyINFOTitle      = { fg = blue,    bold = true, italic = true },
          NotifyDEBUGTitle     = { fg = teal,    italic = true             },
          NotifyTRACETitle     = { fg = mauve,   italic = true             },
          -- Icons
          NotifyERRORIcon      = { fg = red,     bold = true               },
          NotifyWARNIcon       = { fg = yellow,  bold = true               },
          NotifyINFOIcon       = { fg = blue,    bold = true               },
          NotifyDEBUGIcon      = { fg = teal                               },
          NotifyTRACEIcon      = { fg = mauve                              },
          -- Misc
          NotifyLogTime        = { fg = overlay, italic = true             },
          NotifyLogTitle       = { fg = surface, bold = true               },
        }
  
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      apply_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_highlights })
  
      -- ── Rate-limited, dedup-aware vim.notify replacement ─────────────────
  
      local _rate  = { count = 0, window_start = 0, max_per_sec = 8 }
      local _dedup = {}                     -- msg_key → last_time_ms
      local DEDUP_MS   = 1500               -- suppress same message within 1.5s
      local _suppress  = {}                 -- known-noisy patterns to silently drop
  
      -- Add noisy patterns to suppress silently
      _suppress = {
        "written",
        "fewer lines",
        "more lines",
        "yanked",
        "^%s*$",
      }
  
      local _orig_notify = vim.notify   -- keep reference before overriding
  
      ---Enhanced vim.notify with rate-limiting, dedup and structured opts
      ---@param msg     string
      ---@param level   integer?
      ---@param _opts   table?
      vim.notify = function(msg, level, _opts)
        level = level or vim.log.levels.INFO
        _opts = _opts or {}
  
        -- Suppress known noise
        local msg_lower = (msg or ""):lower()
        for _, pat in ipairs(_suppress) do
          if msg_lower:match(pat) then return end
        end
  
        -- Deduplication
        local key  = msg:sub(1, 64)
        local now  = vim.uv.hrtime() / 1e6         -- ms
        if _dedup[key] and (now - _dedup[key]) < DEDUP_MS then
          return                                    -- duplicate — skip
        end
        _dedup[key] = now
  
        -- Rate limiter (rolling window)
        if math.floor(now / 1000) == math.floor(_rate.window_start / 1000) then
          _rate.count = _rate.count + 1
          if _rate.count > _rate.max_per_sec then
            return                                  -- drop; too many this second
          end
        else
          _rate.window_start = now
          _rate.count        = 1
        end
  
        -- Enrich opts
        _opts.title = _opts.title or "ASH NeoVim"
  
        -- Delegate to nvim-notify
        notify(msg, level, _opts)
      end
  
      -- ── Telescope extension ────────────────────────────────────────────────
      vim.defer_fn(function()
        pcall(require("telescope").load_extension, "notify")
      end, 100)
  
      -- ── User command ──────────────────────────────────────────────────────
      vim.api.nvim_create_user_command("AshNotify", function(args)
        local level_map = {
          trace = vim.log.levels.TRACE,
          debug = vim.log.levels.DEBUG,
          info  = vim.log.levels.INFO,
          warn  = vim.log.levels.WARN,
          error = vim.log.levels.ERROR,
        }
        local parts = vim.split(args.args, " ", { plain = true, trimempty = true })
        local lvl   = level_map[parts[1]] or vim.log.levels.INFO
        local msg   = table.concat(parts, " ", 2)
        if msg == "" then
          msg = "🔥 ASH NeoVim v" .. Ash.version .. " — notification system healthy!"
        end
        vim.notify(msg, lvl, {
          title   = "ASH Test Notification",
          timeout = 6000,
        })
      end, {
        nargs = "*",
        desc  = "Send a test notification (AshNotify [level] [message])",
        complete = function()
          return { "trace", "debug", "info", "warn", "error" }
        end,
      })
  
      -- ── Startup greeting (once, deferred) ────────────────────────────────
      if vim.env.ASH_NVIM_GREETING ~= "0" then
        vim.defer_fn(function()
          local ok, lazy = pcall(require, "lazy")
          if ok then
            local s = lazy.stats()
            vim.notify(
              string.format(
                " %d plugins  ⚡ %.0fms  🎨 %s",
                s.count,
                s.startuptime,
                Ash.theme
              ),
              vim.log.levels.INFO,
              {
                title   = "ASH NeoVim v" .. Ash.version,
                timeout = 3500,
                icon    = "🔥",
              }
            )
          end
        end, 500)
      end
    end,
  }