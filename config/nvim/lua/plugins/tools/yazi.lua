-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🦆 YAZI — ULTRA TERMINAL FILE MANAGER v5.0 OMEGA                         ║
-- ║   Floating yazi TUI · image preview · multi-select · events                   ║
-- ║   Telescope integration · cwd sync · ASH theme-synced                         ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "YaziFloat",             { link = "NormalFloat"   })
    hl(0, "YaziBorder",            { link = "FloatBorder"   })
    hl(0, "YaziTitle",             { bold = true, fg = "#7aa2f7" })
    hl(0, "YaziFilename",          { bold = true, fg = "#cdd6f4" })
    hl(0, "YaziDirectory",         { bold = true, fg = "#7aa2f7" })
    hl(0, "YaziStatusLine",        { link = "StatusLine"    })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue then
        hl(0, "YaziTitle",     { bold = true, fg = p.blue })
        hl(0, "YaziDirectory", { bold = true, fg = p.blue })
      end
      if p.text then hl(0, "YaziFilename", { bold = true, fg = p.text }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 YAZI THEME GENERATOR — write ASH palette to yazi theme
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function generate_yazi_theme()
    local ok, ash = pcall(require, "ash.theme")
    local p = (ok and ash.palette) or {}
  
    local base    = p.base    or "#1a1b26"
    local surface = p.surface0 or "#1e2030"
    local text    = p.text    or "#cdd6f4"
    local subtext = p.subtext1 or "#a6adc8"
    local blue    = p.blue    or "#89b4fa"
    local green   = p.green   or "#a6e3a1"
    local red     = p.red     or "#f38ba8"
    local yellow  = p.yellow  or "#f9e2af"
    local mauve   = p.mauve   or "#cba6f7"
    local teal    = p.teal    or "#94e2d5"
    local overlay = p.overlay0 or "#6e738d"
  
    -- Strip # prefix for yazi
    local function hex(c) return c:gsub("^#", "") end
  
    local theme_content = string.format([[
  # ASH OMEGA v5.0 — Yazi theme (auto-generated)
  # Manager
  [manager]
  cwd = { fg = "%s" }
  hovered         = { fg = "%s", bg = "%s", bold = true }
  preview_hovered = { underline = true }
  find_keyword    = { fg = "%s", bold = true, italic = true, underline = true }
  find_position   = { fg = "%s", bg = "%s", bold = true, italic = true }
  marker_copied   = { fg = "%s", bg = "%s" }
  marker_cut      = { fg = "%s", bg = "%s" }
  marker_marked   = { fg = "%s", bg = "%s" }
  marker_selected = { fg = "%s", bg = "%s" }
  tab_active      = { fg = "%s", bg = "%s", bold = true }
  tab_inactive    = { fg = "%s", bg = "%s" }
  tab_width       = 1
  count_copied    = { fg = "%s", bg = "%s", bold = true }
  count_cut       = { fg = "%s", bg = "%s", bold = true }
  count_selected  = { fg = "%s", bg = "%s", bold = true }
  border_symbol   = "│"
  border_style    = { fg = "%s" }
  
  # Status
  [status]
  separator_open  = ""
  separator_close = ""
  separator_style = { fg = "%s", bg = "%s" }
  mode_normal = { fg = "%s", bg = "%s", bold = true }
  mode_select = { fg = "%s", bg = "%s", bold = true }
  mode_unset  = { fg = "%s", bg = "%s", bold = true }
  progress_label  = { bold = true }
  progress_normal = { fg = "%s", bg = "%s" }
  progress_error  = { fg = "%s", bg = "%s" }
  permissions_t   = { fg = "%s" }
  permissions_r   = { fg = "%s" }
  permissions_w   = { fg = "%s" }
  permissions_x   = { fg = "%s" }
  permissions_s   = { fg = "%s" }
  
  # Input
  [input]
  border   = { fg = "%s" }
  title    = {}
  value    = {}
  selected = { reversed = true }
  
  # Completion
  [completion]
  border   = { fg = "%s" }
  active   = { bg = "%s" }
  inactive = {}
  
  # Tasks
  [tasks]
  border  = { fg = "%s" }
  title   = {}
  hovered = { underline = true }
  
  # Select
  [select]
  border   = { fg = "%s" }
  active   = { fg = "%s" }
  inactive = {}
  
  # Spot
  [spot]
  border = { fg = "%s" }
  
  # Notify
  [notify]
  title_info  = { fg = "%s" }
  title_warn  = { fg = "%s" }
  title_error = { fg = "%s" }
  
  # Filetype colours
  [filetype]
  rules = [
    { mime = "image/*", fg = "%s" },
    { mime = "video/*", fg = "%s" },
    { mime = "audio/*", fg = "%s" },
    { mime = "application/zip",    fg = "%s" },
    { mime = "application/x-tar", fg = "%s" },
    { mime = "application/gzip",  fg = "%s" },
    { mime = "text/*",             fg = "%s" },
    { mime = "application/json",  fg = "%s" },
    { mime = "application/pdf",   fg = "%s" },
  ]
  ]],
    -- cwd
    hex(blue),
    -- hovered
    hex(base), hex(blue),
    -- find_keyword
    hex(yellow),
    -- find_position
    hex(base), hex(yellow),
    -- marker_copied
    hex(base), hex(green),
    -- marker_cut
    hex(base), hex(red),
    -- marker_marked
    hex(base), hex(mauve),
    -- marker_selected
    hex(base), hex(blue),
    -- tab_active
    hex(base), hex(blue),
    -- tab_inactive
    hex(subtext), hex(surface),
    -- count_copied/cut/selected
    hex(base), hex(green),
    hex(base), hex(red),
    hex(base), hex(blue),
    -- border
    hex(overlay),
    -- status separator
    hex(surface), hex(base),
    -- mode_normal
    hex(base), hex(blue),
    -- mode_select
    hex(base), hex(green),
    -- mode_unset
    hex(base), hex(red),
    -- progress
    hex(text), hex(surface),
    hex(red), hex(surface),
    -- permissions
    hex(yellow), hex(red), hex(red), hex(green), hex(mauve),
    -- input border
    hex(blue),
    -- completion border / active
    hex(blue), hex(surface),
    -- tasks border
    hex(blue),
    -- select border / active
    hex(blue), hex(blue),
    -- spot border
    hex(blue),
    -- notify
    hex(blue), hex(yellow), hex(red),
    -- filetype colours
    hex(teal), hex(mauve), hex(yellow),
    hex(red), hex(red), hex(red),
    hex(text), hex(yellow), hex(red)
  )
  
    -- Write to yazi config dir
    local config_dir = vim.fn.expand("~/.config/yazi")
    if vim.fn.isdirectory(config_dir) == 0 then
      vim.fn.mkdir(config_dir, "p")
    end
  
    local theme_file = config_dir .. "/theme.toml"
    local f = io.open(theme_file, "w")
    if f then
      f:write(theme_content)
      f:close()
    end
  
    return theme_file
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "mikavilpas/yazi.nvim",
      version      = false,
      event        = "VeryLazy",
      dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope.nvim", optional = true },
      },
  
      keys = {
        -- ── Primary opens ─────────────────────────────────────────────────────
        {
          "<leader>yy",
          function()
            require("yazi").yazi()
          end,
          desc   = "🦆 Yazi: Open (cwd)",
          silent = true,
        },
        {
          "<leader>yf",
          function()
            require("yazi").yazi(nil, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h"))
          end,
          desc   = "🦆 Yazi: Open (file dir)",
          silent = true,
        },
        {
          "<leader>yw",
          function()
            require("yazi").yazi(nil, require("yazi").get_buffers())
          end,
          desc   = "🦆 Yazi: Open (toggle tabs)",
          silent = true,
        },
        {
          "<leader>y-",
          function()
            -- Open at git root
            local root = vim.fn.trim(
              vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
            )
            local dir = vim.v.shell_error == 0 and root or vim.fn.getcwd()
            require("yazi").yazi(nil, dir)
          end,
          desc   = "🦆 Yazi: Open (git root)",
          silent = true,
        },
        {
          "<leader>yt",
          function()
            -- Generate ASH theme for yazi
            local path = generate_yazi_theme()
            vim.notify(
              "🦆 Yazi theme written → " .. path,
              vim.log.levels.INFO,
              { title = "Yazi", timeout = 1500 }
            )
          end,
          desc   = "🦆 Yazi: Generate ASH theme",
          silent = true,
        },
        {
          "<leader>yi",
          function()
            local ver = vim.fn.trim(vim.fn.system("yazi --version 2>/dev/null"))
            vim.notify(
              table.concat({
                "🦆 Yazi Environment",
                "──────────────────────────────────",
                string.format("  Version:  %s", ver ~= "" and ver or "⭕ not found"),
                string.format("  Config:   %s", vim.fn.expand("~/.config/yazi")),
                string.format("  ya:       %s", vim.fn.executable("ya")   == 1 and "✅" or "⭕"),
                string.format("  ueberzugpp: %s", vim.fn.executable("ueberzugpp") == 1 and "✅" or "⭕"),
                string.format("  kitty:    %s", vim.fn.executable("kitty") == 1 and "✅ (image)" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Yazi" }
            )
          end,
          desc   = "🦆 Yazi: Info",
          silent = true,
        },
      },
  
      opts = {
        -- ── Open in floating window ────────────────────────────────────────────
        open_for_directories = false,
  
        -- ── Float window ─────────────────────────────────────────────────────
        floating_window_scaling_factor = 0.90,
  
        -- ── yazi_floating_window_border ───────────────────────────────────────
        yazi_floating_window_border = "rounded",
  
        -- ── Log level ────────────────────────────────────────────────────────
        log_level = vim.log.levels.OFF,
  
        -- ── Open method ──────────────────────────────────────────────────────
        open_multiple_tabs = false,
  
        -- ── Hooks ─────────────────────────────────────────────────────────────
        hooks = {
          -- Fire when yazi opens
          yazi_opened = function(_preselected_path, _config, _state)
            -- Disable mini-animate when yazi is open
            vim.g.minianimate_disable = true
          end,
  
          -- Fire when yazi closes
          yazi_closed_successfully = function(chosen_file, _config, _state)
            vim.g.minianimate_disable = false
            if chosen_file then
              vim.notify(
                "🦆 Opened: " .. vim.fn.fnamemodify(chosen_file, ":t"),
                vim.log.levels.INFO,
                { title = "Yazi", timeout = 800 }
              )
            end
          end,
  
          -- Fire when yazi closes without selection
          yazi_closed_without_opening = function(_last_directory, _config)
            vim.g.minianimate_disable = false
          end,
        },
  
        -- ── Events ────────────────────────────────────────────────────────────
        events = {
          -- Event: rename / move
          {
            event     = "rename",
            value_type= "path",
            fn        = function(data, _config, _state)
              local ok, buffers = pcall(function()
                return vim.fn.getbufinfo({ bufloaded = 1 })
              end)
              if not ok then return end
              for _, buf in ipairs(buffers) do
                if buf.name == data.from then
                  vim.api.nvim_buf_set_name(buf.bufnr, data.to)
                end
              end
            end,
          },
  
          -- Event: delete
          {
            event  = "trash",
            value_type = "path",
            fn     = function(data, _config, _state)
              -- Close buffers for trashed files
              local ok, buffers = pcall(function()
                return vim.fn.getbufinfo({ bufloaded = 1 })
              end)
              if not ok then return end
              for _, buf in ipairs(buffers) do
                if buf.name == data.url then
                  vim.api.nvim_buf_delete(buf.bufnr, { force = false })
                end
              end
            end,
          },
  
          -- Event: cd (change directory)
          {
            event  = "cd",
            value_type = "path",
            fn     = function(data, _config, _state)
              -- Sync neovim cwd with yazi cwd
              if data.url and vim.fn.isdirectory(data.url) == 1 then
                vim.cmd("lcd " .. vim.fn.fnameescape(data.url))
              end
            end,
          },
        },
  
        -- ── Future API ────────────────────────────────────────────────────────
        integrations = {
          -- Telescope integration for finding files after yazi
          telescope = {
            -- Use telescope to preview before selecting
            keybinding = "<C-t>",
          },
        },
      },
  
      config = function(_, opts)
        require("yazi").setup(opts)
  
        setup_highlights()
  
        -- Generate ASH theme on first load
        if vim.fn.executable("yazi") == 1 then
          generate_yazi_theme()
        end
  
        local aug = vim.api.nvim_create_augroup("AshYazi", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            -- Re-generate yazi theme with new palette
            if vim.fn.executable("yazi") == 1 then
              generate_yazi_theme()
            end
            vim.notify("🦆 Yazi theme regenerated for ASH theme", vim.log.levels.INFO,
              { title = "ASH Yazi", timeout = 1200 })
          end,
        })
  
        -- Disable mini-plugins in yazi terminal buffer
        vim.api.nvim_create_autocmd("TermOpen", {
          group   = aug,
          pattern = "*yazi*",
          callback = function(ev)
            vim.b[ev.buf].miniindentscope_disable = true
            vim.b[ev.buf].minianimate_disable     = true
            vim.opt_local.number         = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn     = "no"
            vim.opt_local.spell          = false
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify("🦆 Yazi loaded", vim.log.levels.DEBUG, { title = "ASH Yazi" })
        end
      end,
    },
  }