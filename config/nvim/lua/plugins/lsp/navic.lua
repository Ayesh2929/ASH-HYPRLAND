-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🧭 NVIM-NAVIC — ULTRA BREADCRUMB ENGINE v5.0 OMEGA                       ║
-- ║   LSP-powered context breadcrumbs · winbar integration · symbol icons          ║
-- ║   depth control · separator styles · ASH theme-synced · lualine ready         ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 SYMBOL KIND ICONS — Nerd Font v3 premium set
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ICONS = {
    File            = "󰈙 ",
    Module          = "󰅩 ",
    Namespace       = "󰅩 ",
    Package         = "󰹻 ",
    Class           = "󰌗 ",
    Method          = "󰆧 ",
    Property        = "󰖷 ",
    Field           = " ",
    Constructor     = " ",
    Enum            = " ",
    Interface       = " ",
    Function        = "󰊕 ",
    Variable        = "󰀫 ",
    Constant        = "󰏿 ",
    String          = "󱌯 ",
    Number          = " ",
    Boolean         = "󰨙 ",
    Array           = "󱡠 ",
    Object          = "󰅩 ",
    Key             = "󰌋 ",
    Null            = "󰟢 ",
    EnumMember      = " ",
    Struct          = "󱡠 ",
    Event           = " ",
    Operator        = "󰆕 ",
    TypeParameter   = "󰊄 ",
    Component       = "󰅴 ",
    Fragment        = "󰅴 ",
    TypeAlias       = "󰊄 ",
    StaticMethod    = "󰠄 ",
    Macro           = "󰏗 ",
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎨 HIGHLIGHT SETUP — per-kind colours + winbar chrome
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Per-symbol-kind highlight colours (base palette)
  local KIND_COLOURS = {
    File            = "#89b4fa",
    Module          = "#cba6f7",
    Namespace       = "#cba6f7",
    Package         = "#fab387",
    Class           = "#f9e2af",
    Method          = "#89b4fa",
    Property        = "#cba6f7",
    Field           = "#89dceb",
    Constructor     = "#f9e2af",
    Enum            = "#89dceb",
    Interface       = "#94e2d5",
    Function        = "#89b4fa",
    Variable        = "#cdd6f4",
    Constant        = "#fab387",
    String          = "#a6e3a1",
    Number          = "#fab387",
    Boolean         = "#fab387",
    Array           = "#89dceb",
    Object          = "#cba6f7",
    Key             = "#f38ba8",
    Null            = "#6e738d",
    EnumMember      = "#a6e3a1",
    Struct          = "#f9e2af",
    Event           = "#f38ba8",
    Operator        = "#89b4fa",
    TypeParameter   = "#94e2d5",
    Component       = "#fab387",
    Fragment        = "#89dceb",
  }
  
  local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Per-kind symbol highlights ────────────────────────────────────────────
    for kind, colour in pairs(KIND_COLOURS) do
      hl(0, "NavicIcons" .. kind,  { bold = false, fg = colour })
      hl(0, "NavicText" .. kind,   { fg = colour               })
    end
  
    -- ── Separator between breadcrumb segments ────────────────────────────────
    hl(0, "NavicSeparator",        { fg = "#6e738d"            })
  
    -- ── Winbar background (transparent = follows Normal) ─────────────────────
    hl(0, "NavicBackground",       { link = "WinBar"           })
  
    -- ── Unfocused / loading state ─────────────────────────────────────────────
    hl(0, "NavicText",             { fg = "#cdd6f4"            })
  
    -- ── Breadcrumb container (winbar) ─────────────────────────────────────────
    hl(0, "WinBar",                { link = "StatusLine"       })
    hl(0, "WinBarNC",              { link = "StatusLineNC"     })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      -- Remap key colours from ASH palette
      local palette_map = {
        Function     = p.blue   or KIND_COLOURS.Function,
        Class        = p.yellow or KIND_COLOURS.Class,
        Method       = p.blue   or KIND_COLOURS.Method,
        Variable     = p.text   or KIND_COLOURS.Variable,
        Constant     = p.peach  or KIND_COLOURS.Constant,
        String       = p.green  or KIND_COLOURS.String,
        Interface    = p.teal   or KIND_COLOURS.Interface,
        Struct       = p.yellow or KIND_COLOURS.Struct,
        Enum         = p.teal   or KIND_COLOURS.Enum,
        Module       = p.mauve  or KIND_COLOURS.Module,
        Field        = p.cyan   or KIND_COLOURS.Field,
        Property     = p.mauve  or KIND_COLOURS.Property,
        Key          = p.red    or KIND_COLOURS.Key,
        Null         = p.overlay0 or KIND_COLOURS.Null,
        TypeParameter = p.teal  or KIND_COLOURS.TypeParameter,
        Operator     = p.blue   or KIND_COLOURS.Operator,
      }
      for kind, colour in pairs(palette_map) do
        hl(0, "NavicIcons" .. kind, { fg = colour })
        hl(0, "NavicText" .. kind,  { fg = colour })
      end
  
      local sep_col = p.overlay0 or p.subtext0 or "#6e738d"
      hl(0, "NavicSeparator", { fg = sep_col })
  
      if p.text then hl(0, "NavicText", { fg = p.text }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 WINBAR BUILDER — rich winbar with navic + extras
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Filetypes where the winbar should be hidden
  local WINBAR_EXCLUDE_FT = {
    "alpha", "dashboard", "starter", "snacks_dashboard",
    "neo-tree", "NvimTree", "oil", "minifiles", "yazi",
    "Trouble", "trouble", "qf", "quickfix", "loclist",
    "TelescopePrompt", "TelescopeResults",
    "fzf", "lazy", "mason",
    "help", "man", "checkhealth", "lspinfo",
    "noice", "notify", "toggleterm", "terminal",
    "spectre_panel", "undotree",
    "gitcommit", "NeogitStatus", "NeogitCommitMessage",
    "DiffviewFiles", "DiffviewFileHistory",
    "DressingInput", "DressingSelect",
    "codecompanion", "avante", "AvanteInput",
    "NvimTree",
  }
  
  -- Build the winbar string for the current window
  local function get_winbar()
    local bufnr = vim.api.nvim_get_current_buf()
    local ft    = vim.bo[bufnr].filetype
  
    if vim.tbl_contains(WINBAR_EXCLUDE_FT, ft) then return "" end
    if vim.bo[bufnr].buftype ~= ""            then return "" end
  
    local ok_nav, navic = pcall(require, "nvim-navic")
    if not ok_nav                             then return "" end
    if not navic.is_available(bufnr)          then return "" end
  
    local location = navic.get_location({}, bufnr)
    if not location or location == ""         then return "" end
  
    -- ── Left section: file icon + filename ────────────────────────────────────
    local ok_icons, devicons = pcall(require, "nvim-web-devicons")
    local file_icon = ""
    if ok_icons then
      local icon, icon_hl = devicons.get_icon(
        vim.fn.expand("%:t"),
        vim.fn.expand("%:e"),
        { default = true }
      )
      if icon then
        file_icon = string.format("%%#%s#%s%%* ", icon_hl or "Normal", icon)
      end
    end
  
    local fname = vim.fn.expand("%:~:.")
    if fname == "" then fname = "[No Name]" end
  
    -- Truncate long paths
    if #fname > 40 then
      local parts = vim.split(fname, "/")
      if #parts > 3 then
        fname = "…/" .. parts[#parts - 1] .. "/" .. parts[#parts]
      end
    end
  
    -- Modified indicator
    local modified = vim.bo[bufnr].modified
      and " %#DiagnosticWarn#●%* "
      or  " "
  
    -- Readonly indicator
    local readonly = vim.bo[bufnr].readonly
      and " %#DiagnosticError#󰌾%* "
      or  ""
  
    -- ── Assemble winbar ───────────────────────────────────────────────────────
    return table.concat({
      -- File section
      "%#WinBar#",
      "  ",
      file_icon,
      "%#WinBar#",
      fname,
      modified,
      readonly,
      -- Separator
      "%#NavicSeparator#",
      "  ",
  
      -- Navic breadcrumb
      location,
  
      -- Right-align: LSP client name
      "%=",
      "%#Comment#",
      (function()
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        if #clients == 0 then return "" end
        local names = vim.tbl_map(function(c) return c.name end, clients)
        return " 🔧 " .. table.concat(names, ", ") .. "  "
      end)(),
  
      "%*",
    })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART TOGGLE + STATUS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local _navic_winbar_enabled = true
  
  local function toggle_winbar()
    _navic_winbar_enabled = not _navic_winbar_enabled
    if _navic_winbar_enabled then
      vim.o.winbar = "%{%v:lua.AshGetWinbar()%}"
    else
      vim.o.winbar = ""
    end
    vim.notify(
      string.format(
        "🧭 Winbar breadcrumb %s",
        _navic_winbar_enabled and " enabled" or " disabled"
      ),
      vim.log.levels.INFO,
      { title = "Navic", timeout = 1200 }
    )
  end
  
  local function show_navic_location()
    local ok, navic = pcall(require, "nvim-navic")
    if not ok then return end
    local loc = navic.get_location()
    if not loc or loc == "" then
      vim.notify(
        "🧭 No symbol context at cursor",
        vim.log.levels.INFO,
        { title = "Navic" }
      )
      return
    end
    -- Strip highlight groups for plain display
    local plain = loc:gsub("%%#[^#]+#", ""):gsub("%%*", "")
    vim.notify(
      "🧭 " .. plain,
      vim.log.levels.INFO,
      { title = "Current Symbol", timeout = 2000 }
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "SmiteshP/nvim-navic",
      lazy         = true,
      dependencies = { "neovim/nvim-lspconfig" },
  
      keys = {
        {
          "<leader>ub",
          toggle_winbar,
          desc   = "🧭 Toggle Winbar Breadcrumb",
          silent = true,
        },
        {
          "<leader>uB",
          show_navic_location,
          desc   = "🧭 Show Symbol Location",
          silent = true,
        },
      },
  
      opts = {
        -- ── Icons ──────────────────────────────────────────────────────────────
        icons           = ICONS,
  
        -- ── Highlight ──────────────────────────────────────────────────────────
        -- true = use per-kind highlights; false = plain text
        highlight       = true,
  
        -- ── Separator between breadcrumb segments ──────────────────────────────
        separator       = "  ",
  
        -- ── Depth limit (0 = no limit) ──────────────────────────────────────────
        depth_limit     = 8,
  
        -- ── Characters to show when depth limit is exceeded ─────────────────────
        depth_limit_indicator = "⋯",
  
        -- ── Auto-update the winbar ─────────────────────────────────────────────
        auto_update     = true,
  
        -- ── Safe output: avoid errors crashing winbar ──────────────────────────
        safe_output     = true,
  
        -- ── Click handler (open telescope symbol picker) ───────────────────────
        click           = false,
  
        -- ── Format text functions ─────────────────────────────────────────────
        format_text     = {
          -- Shorten long symbol names
          function(text)
            if #text > 30 then
              return text:sub(1, 28) .. "…"
            end
            return text
          end,
        },
  
        -- ── Lazy update: only update when cursor stops ─────────────────────────
        lazy_update_context = false,
  
        -- ── LSP server blocklist ──────────────────────────────────────────────
        -- These servers produce noisy / incorrect breadcrumbs
        lsp = {
          auto_attach  = true,
          preference   = {
            -- Prefer these servers for document symbols in priority order
            "rust_analyzer",
            "lua_ls",
            "pyright",
            "gopls",
            "ts_ls",
            "clangd",
            "hls",
            "zls",
            "elixirls",
          },
        },
      },
  
      config = function(_, opts)
        local navic = require("nvim-navic")
        navic.setup(opts)
  
        setup_highlights()
  
        -- ── Expose global winbar function ─────────────────────────────────────
        _G.AshGetWinbar = get_winbar
  
        -- ── Set global winbar ─────────────────────────────────────────────────
        vim.o.winbar = "%{%v:lua.AshGetWinbar()%}"
  
        -- ── Auto-attach to every LSP client ───────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshNavic", { clear = true })
  
        vim.api.nvim_create_autocmd("LspAttach", {
          group    = aug,
          callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if not client then return end
  
            -- Only attach if server supports documentSymbol
            if client.server_capabilities.documentSymbolProvider then
              navic.attach(client, ev.buf)
            end
          end,
        })
  
        -- ── Winbar refresh on cursor move ─────────────────────────────────────
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufWinEnter" }, {
          group    = aug,
          callback = function()
            -- Force winbar redraw
            if _navic_winbar_enabled then
              vim.cmd("redrawstatus")
            end
          end,
        })
  
        -- ── Hide winbar for excluded filetypes ────────────────────────────────
        vim.api.nvim_create_autocmd("FileType", {
          group    = aug,
          callback = function(ev)
            if vim.tbl_contains(WINBAR_EXCLUDE_FT, vim.bo[ev.buf].filetype) then
              vim.wo.winbar = ""
            elseif _navic_winbar_enabled then
              vim.wo.winbar = "%{%v:lua.AshGetWinbar()%}"
            end
          end,
        })
  
        -- ── Highlights: colorscheme & ASH hot-reload ──────────────────────────
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
              "🧭 Navic highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Navic", timeout = 1200 }
            )
          end,
        })
  
        -- ── Expose navic location for lualine ─────────────────────────────────
        _G.AshNavicLocation = function()
          local ok2, n2 = pcall(require, "nvim-navic")
          if not ok2 or not n2.is_available() then return "" end
          return n2.get_location() or ""
        end
  
        if vim.g.ash_debug then
          vim.notify(
            string.format(
              "🧭 Navic loaded — %d icons configured",
              vim.tbl_count(ICONS)
            ),
            vim.log.levels.DEBUG,
            { title = "ASH Navic" }
          )
        end
      end,
    },
  }