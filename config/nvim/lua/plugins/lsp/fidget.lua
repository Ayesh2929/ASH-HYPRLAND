-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🎭 FIDGET.NVIM — ULTRA LSP PROGRESS UI v5.0 OMEGA                        ║
-- ║   Beautiful LSP progress notifications · spinner animations · history          ║
-- ║   nvim-notify integration · ASH theme-aware · fully customisable UX            ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — fidget UI colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Progress window ────────────────────────────────────────────────────────
    hl(0, "FidgetTitle",       { bold = true, fg = "#7aa2f7"              })
    hl(0, "FidgetTask",        { fg = "#9399b2"                           })
    hl(0, "FidgetDone",        { bold = true, fg = "#9ece6a"              })
    hl(0, "FidgetSpinner",     { bold = true, fg = "#ff9e64"              })
    hl(0, "FidgetAccum",       { italic = true, fg = "#9399b2"            })
    hl(0, "FidgetWindow",      { link = "NormalFloat"                     })
    hl(0, "FidgetWindowBorder",{ link = "FloatBorder"                     })
    hl(0, "FidgetCount",       { bold = true, fg = "#7dcfff"              })
    hl(0, "FidgetProg",        { fg = "#bb9af7"                           })
  
    -- ── Notification styles ───────────────────────────────────────────────────
    hl(0, "FidgetNotifInfo",   { bold = true, fg = "#7aa2f7"              })
    hl(0, "FidgetNotifWarn",   { bold = true, fg = "#f9e2af"              })
    hl(0, "FidgetNotifError",  { bold = true, fg = "#f38ba8"              })
    hl(0, "FidgetNotifDebug",  { fg = "#9399b2"                           })
    hl(0, "FidgetNotifTrace",  { fg = "#6e738d"                           })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "FidgetTitle",     { bold = true, fg = p.blue   })
        hl(0, "FidgetNotifInfo", { bold = true, fg = p.blue   })
      end
      if p.green  then hl(0, "FidgetDone",      { bold = true, fg = p.green  }) end
      if p.orange then hl(0, "FidgetSpinner",   { bold = true, fg = p.orange }) end
      if p.red    then hl(0, "FidgetNotifError",{ bold = true, fg = p.red    }) end
      if p.yellow then hl(0, "FidgetNotifWarn", { bold = true, fg = p.yellow }) end
      if p.mauve  then hl(0, "FidgetProg",      { fg = p.mauve              }) end
      if p.cyan   then hl(0, "FidgetCount",     { bold = true, fg = p.cyan  }) end
      local dim = p.overlay1 or p.subtext0 or "#9399b2"
      hl(0, "FidgetTask",  { fg = dim })
      hl(0, "FidgetAccum", { italic = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌀 SPINNER SETS — different animation styles
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local SPINNERS = {
    -- Premium Braille dot matrix
    dots    = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
    -- Arc sweep
    arc     = { "◜", "◠", "◝", "◞", "◡", "◟" },
    -- Bouncing bar
    bounce  = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "▆", "▅", "▄", "▃", "▂" },
    -- Growing circle
    circle  = { "◐", "◓", "◑", "◒" },
    -- Pipe
    pipe    = { "┤", "┘", "┴", "└", "├", "┌", "┬", "┐" },
    -- Classic
    classic = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
    -- Stars
    star    = { "✶", "✸", "✹", "✺", "✹", "✷" },
    -- Triangle
    tri     = { "◢", "◣", "◤", "◥" },
    -- Nerd font icons
    nerd    = { "󰂚", "󰂛", "󰂜", "󰂝", "󰂞", "󰂟", "󰂠" },
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "j-hui/fidget.nvim",
      event    = "LspAttach",
  
      keys = {
        {
          "<leader>uf",
          function()
            local ok, fid = pcall(require, "fidget")
            if ok then fid.close() end
          end,
          desc   = "🎭 Fidget: Close",
          silent = true,
        },
        {
          "<leader>uF",
          "<cmd>Fidget history<cr>",
          desc   = "🎭 Fidget: History",
          silent = true,
        },
        {
          "<leader>uN",
          "<cmd>Fidget suppress<cr>",
          desc   = "🎭 Fidget: Suppress",
          silent = true,
        },
      },
  
      opts = {
        -- ── Progress display ─────────────────────────────────────────────────────
        progress = {
          poll_rate               = 0,          -- 0 = on every event
          suppress_on_insert      = false,
          ignore_done_already     = false,
          ignore_empty_message    = false,
  
          -- Clear notification when all LSP work is done
          clear_on_detach         = function(client_id)
            local client = vim.lsp.get_client_by_id(client_id)
            return client and client.name or nil
          end,
  
          -- Notification router: which backend to use
          notification_group      = function(msg)
            return msg.lsp_client.name
          end,
  
          ignore                  = {},
  
          -- ── Display ───────────────────────────────────────────────────────────
          display = {
            -- Time (ms) before progress message is removed after completion
            render_limit      = 16,
            done_ttl          = 3,
            done_icon         = "✅",
            done_style        = "Constant",
            progress_ttl      = math.huge,
            progress_icon     = { pattern = "dots", period = 1 },
            progress_style    = "WarningMsg",
            group_style       = "Title",
            icon_style        = "Question",
            priority          = 30,
            skip_history      = true,
            format_message    = require("fidget.progress.display").default_format_message,
            format_annote     = function(msg) return msg.title end,
            format_group_name = function(group) return tostring(group) end,
            overrides         = {
              -- Server-specific display overrides
              rust_analyzer     = { name = "🦀 rust-analyzer" },
              lua_ls            = { name = "🌙 lua_ls"         },
              pyright           = { name = "🐍 pyright"        },
              gopls             = { name = "🐹 gopls"          },
              ts_ls             = { name = "📘 tsserver"       },
              clangd            = { name = "⚙️  clangd"        },
              hls               = { name = "λ hls"             },
              omnisharp         = { name = "🔷 omnisharp"      },
              zls               = { name = "🏗️  zls"           },
              elixirls          = { name = "🌿 elixir-ls"      },
            },
          },
  
          -- ── LSP ───────────────────────────────────────────────────────────────
          lsp = {
            progress_ringbuf_size = 0,
            log_handler           = false,
          },
        },
  
        -- ── Notification backend ────────────────────────────────────────────────
        notification = {
          poll_rate               = 10,
          filter                  = vim.log.levels.INFO,
          history_size            = 128,
          override_vim_notify     = true,         -- replace vim.notify
          redirect                = function(msg, level, opts)
            if level >= vim.log.levels.ERROR then
              -- Route errors to snacks/mini.notify for persistence
              return require("fidget.integration.nvim-notify").delegate(msg, level, opts)
            end
          end,
  
          -- ── View settings ──────────────────────────────────────────────────────
          view = {
            stack_upwards      = true,
            icon_separator     = " ",
            group_separator    = "─────────────────────────",
            group_separator_hl = "Comment",
            render_message     = function(msg, cnt)
              return cnt == 1 and msg or string.format("(%dx) %s", cnt, msg)
            end,
          },
  
          -- ── Window settings ────────────────────────────────────────────────────
          window = {
            -- Position: corner of the screen
            normal_hl          = "FidgetWindow",
            winblend           = 0,
            border             = "none",
            border_hl          = "FidgetWindowBorder",
            -- "editor" | "win" | "cursor"
            zindex             = 45,
            max_width          = 0,
            max_height         = 0,
            x_padding          = 1,
            y_padding          = 0,
            align              = "bottom",
            relative           = "editor",
          },
  
          -- ── Spinner ────────────────────────────────────────────────────────────
          -- Icons for levels
          icon_for_level       = function(level)
            local icons = {
              [vim.log.levels.ERROR] = " ",
              [vim.log.levels.WARN]  = " ",
              [vim.log.levels.INFO]  = " ",
              [vim.log.levels.DEBUG] = "󰃤 ",
              [vim.log.levels.TRACE] = "󰛉 ",
            }
            return icons[level] or " "
          end,
  
          -- Highlight for levels
          hl_for_level         = function(level)
            local hls = {
              [vim.log.levels.ERROR] = "FidgetNotifError",
              [vim.log.levels.WARN]  = "FidgetNotifWarn",
              [vim.log.levels.INFO]  = "FidgetNotifInfo",
              [vim.log.levels.DEBUG] = "FidgetNotifDebug",
              [vim.log.levels.TRACE] = "FidgetNotifTrace",
            }
            return hls[level] or "Normal"
          end,
        },
  
        -- ── Integrations ────────────────────────────────────────────────────────
        integration = {
          ["nvim-tree"]  = { enable = false },
          ["xcodebuild-nvim"] = { enable = false },
        },
  
        -- ── Logger ──────────────────────────────────────────────────────────────
        logger = {
          level     = vim.log.levels.WARN,
          max_size  = 10000,
          float_precision = 0.01,
          path      = vim.fn.stdpath("data") .. "/fidget.log",
        },
      },
  
      config = function(_, opts)
        require("fidget").setup(opts)
  
        setup_highlights()
  
        -- ── Spinner theme selector (picks based on ASH mode) ──────────────────
        local function apply_spinner_theme()
          local ok_ash, ash_mode = pcall(require, "ash.mode")
          local mode = ok_ash and ash_mode.current or "default"
          local spinner_map = {
            game    = "star",
            cinema  = "arc",
            focus   = "dots",
            minimal = "circle",
            default = "dots",
          }
          local theme = SPINNERS[spinner_map[mode] or "dots"]
  
          -- Apply via fidget internals (best-effort)
          local ok_fid, fid = pcall(require, "fidget.progress.display")
          if ok_fid and fid then
            -- Rebuild progress icon with new spinner
            pcall(function()
              require("fidget").setup({
                progress = {
                  display = {
                    progress_icon = { pattern = theme, period = 1 },
                  },
                },
              })
            end)
          end
        end
  
        local aug = vim.api.nvim_create_augroup("AshFidget", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            apply_spinner_theme()
            vim.notify(
              "🎭 Fidget highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Fidget", timeout = 1200 }
            )
          end,
        })
  
        -- ── Mode-change spinner swap ───────────────────────────────────────────
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshModeChanged",
          callback = apply_spinner_theme,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "🎭 Fidget loaded — override vim.notify: true",
            vim.log.levels.DEBUG,
            { title = "ASH Fidget" }
          )
        end
      end,
    },
  }