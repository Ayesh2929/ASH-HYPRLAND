-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📏 LSP-LINES — ULTRA INLINE DIAGNOSTIC RENDERER v5.0 OMEGA               ║
-- ║   Full diagnostic messages inline · severity icons · virtual lines             ║
-- ║   toggle-able · coexists with virtual_text · ASH theme-synced colours          ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — virtual line diagnostic colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Virtual line text (severity-matched) ──────────────────────────────────
    hl(0, "DiagnosticVirtualLinesError", {
      bold   = false,
      italic = true,
      fg     = "#f38ba8",
    })
    hl(0, "DiagnosticVirtualLinesWarn",  {
      bold   = false,
      italic = true,
      fg     = "#f9e2af",
    })
    hl(0, "DiagnosticVirtualLinesInfo",  {
      bold   = false,
      italic = true,
      fg     = "#89b4fa",
    })
    hl(0, "DiagnosticVirtualLinesHint",  {
      bold   = false,
      italic = true,
      fg     = "#94e2d5",
    })
  
    -- ── Virtual line connector arrows ─────────────────────────────────────────
    hl(0, "LspLinesArrow",               { fg = "#6e738d" })
    hl(0, "LspLinesSep",                 { fg = "#313244" })
  
    -- ── Error/warn code badge ─────────────────────────────────────────────────
    hl(0, "LspLinesCode",                { italic = true, fg = "#6e738d" })
  
    -- ── Source name badge ─────────────────────────────────────────────────────
    hl(0, "LspLinesSource",              { italic = true, fg = "#9399b2" })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.red    then hl(0, "DiagnosticVirtualLinesError", { italic = true, fg = p.red    }) end
      if p.yellow then hl(0, "DiagnosticVirtualLinesWarn",  { italic = true, fg = p.yellow }) end
      if p.blue   then hl(0, "DiagnosticVirtualLinesInfo",  { italic = true, fg = p.blue   }) end
      if p.teal   then hl(0, "DiagnosticVirtualLinesHint",  { italic = true, fg = p.teal   }) end
      local dim = p.overlay0 or p.subtext0 or "#6e738d"
      hl(0, "LspLinesArrow",  { fg = dim })
      hl(0, "LspLinesCode",   { italic = true, fg = dim })
      hl(0, "LspLinesSource", { italic = true, fg = p.overlay1 or dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 STATE — mutual exclusion with virtual_text
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local _lsp_lines_enabled = false   -- start disabled (virtual_text is default)
  
  -- Sync diagnostic config with current state
  local function apply_state()
    if _lsp_lines_enabled then
      -- Enable lsp-lines, disable compact virtual_text
      vim.diagnostic.config({
        virtual_text  = false,
        virtual_lines = { only_current_line = false },
      })
    else
      -- Disable lsp-lines, restore compact virtual_text
      vim.diagnostic.config({
        virtual_text  = {
          severity     = { min = vim.diagnostic.severity.WARN },
          source       = "if_many",
          prefix       = "●",
          spacing      = 4,
        },
        virtual_lines = false,
      })
    end
  end
  
  local function toggle_lsp_lines()
    local ok, lsp_lines = pcall(require, "lsp_lines")
    if not ok then
      vim.notify(
        "📏 lsp-lines not available",
        vim.log.levels.WARN,
        { title = "lsp-lines" }
      )
      return
    end
  
    _lsp_lines_enabled = not _lsp_lines_enabled
    apply_state()
  
    vim.notify(
      string.format(
        "📏 LSP Lines %s",
        _lsp_lines_enabled and " enabled (full diagnostics)" or " disabled (compact)"
      ),
      vim.log.levels.INFO,
      { title = "lsp-lines", timeout = 1500 }
    )
  end
  
  -- Toggle: show lsp-lines for current line only
  local function toggle_current_line_only()
    if not _lsp_lines_enabled then
      _lsp_lines_enabled = true
    end
  
    local cfg = vim.diagnostic.config()
    local cur_only = type(cfg.virtual_lines) == "table"
      and cfg.virtual_lines.only_current_line
  
    vim.diagnostic.config({
      virtual_text  = false,
      virtual_lines = { only_current_line = not cur_only },
    })
  
    vim.notify(
      string.format(
        "📏 LSP Lines: %s",
        not cur_only and " current line only" or " all lines"
      ),
      vim.log.levels.INFO,
      { title = "lsp-lines", timeout = 1200 }
    )
  end
  
  -- Severity filter: show only errors, or all
  local function toggle_errors_only()
    local cfg = vim.diagnostic.config()
    local vl  = cfg.virtual_lines
  
    if type(vl) == "table" and vl.severity then
      -- Currently errors-only → show all
      vim.diagnostic.config({
        virtual_lines = {
          only_current_line = vl.only_current_line or false,
          severity          = nil,
        },
      })
      vim.notify(
        "📏 LSP Lines: showing all severities",
        vim.log.levels.INFO,
        { title = "lsp-lines", timeout = 1200 }
      )
    else
      -- Show all → errors only
      vim.diagnostic.config({
        virtual_lines = {
          only_current_line = type(vl) == "table" and vl.only_current_line or false,
          severity          = { min = vim.diagnostic.severity.ERROR },
        },
      })
      vim.notify(
        "📏 LSP Lines: errors only",
        vim.log.levels.INFO,
        { title = "lsp-lines", timeout = 1200 }
      )
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
      event        = { "LspAttach" },
      dependencies = { "neovim/nvim-lspconfig" },
  
      keys = {
        {
          "<leader>ul",
          toggle_lsp_lines,
          desc   = "📏 Toggle LSP Lines",
          silent = true,
        },
        {
          "<leader>uL",
          toggle_current_line_only,
          desc   = "📏 Toggle LSP Lines (current line)",
          silent = true,
        },
        {
          "<leader>ue",
          toggle_errors_only,
          desc   = "📏 Toggle LSP Lines (errors only)",
          silent = true,
        },
      },
  
      config = function()
        require("lsp_lines").setup()
  
        setup_highlights()
  
        -- ── Apply initial state (virtual_text on, lines off) ──────────────────
        apply_state()
  
        local aug = vim.api.nvim_create_augroup("AshLspLines", { clear = true })
  
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
              "📏 LSP Lines highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH lsp-lines", timeout = 1200 }
            )
          end,
        })
  
        -- ── Disable in insert mode (less distracting) ─────────────────────────
        vim.api.nvim_create_autocmd("InsertEnter", {
          group    = aug,
          callback = function()
            if _lsp_lines_enabled then
              vim.diagnostic.config({ virtual_lines = false })
            end
          end,
        })
  
        vim.api.nvim_create_autocmd("InsertLeave", {
          group    = aug,
          callback = function()
            if _lsp_lines_enabled then
              vim.diagnostic.config({
                virtual_lines = { only_current_line = false },
              })
            end
          end,
        })
  
        -- ── Expose state for statusline ───────────────────────────────────────
        _G.AshLspLinesEnabled = function()
          return _lsp_lines_enabled and "📏" or ""
        end
  
        if vim.g.ash_debug then
          vim.notify(
            "📏 lsp-lines loaded — default: disabled (use <leader>ul to toggle)",
            vim.log.levels.DEBUG,
            { title = "ASH lsp-lines" }
          )
        end
      end,
    },
  }