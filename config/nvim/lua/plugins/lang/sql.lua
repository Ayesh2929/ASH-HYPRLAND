-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🗄️  SQL — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                              ║
-- ║   sqls · sqlfluff · sql-formatter · dadbod · query runner · schema browser    ║
-- ║   PostgreSQL · MySQL · SQLite · ASH theme-synced                               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "@keyword.sql",           { bold = true,   fg = "#7aa2f7" })
    hl(0, "@keyword.operator.sql",  { bold = true,   fg = "#f38ba8" })
    hl(0, "@keyword.type.sql",      { bold = true,   fg = "#f9e2af" })
    hl(0, "@function.builtin.sql",  { bold = true,   fg = "#89b4fa" })
    hl(0, "@string.sql",            { fg = "#a6e3a1"                })
    hl(0, "@number.sql",            { fg = "#fab387"                })
    hl(0, "@operator.sql",          { fg = "#89b4fa"                })
    hl(0, "@punctuation.sql",       { fg = "#9399b2"                })
    hl(0, "@comment.sql",           { italic = true, fg = "#9399b2" })
    hl(0, "@variable.sql",          { fg = "#cba6f7"                })
    hl(0, "@type.sql",              { bold = true,   fg = "#f9e2af" })
    hl(0, "@property.sql",          { fg = "#cdd6f4"                })
    hl(0, "@constant.sql",          { bold = true,   fg = "#fab387" })
  
    -- ── SQL-specific concepts ─────────────────────────────────────────────────
    hl(0, "SqlTable",         { bold = true,   fg = "#f9e2af" })
    hl(0, "SqlColumn",        { fg = "#89b4fa"                })
    hl(0, "SqlConstraint",    { bold = true,   fg = "#f38ba8" })
    hl(0, "SqlIndex",         { italic = true, fg = "#94e2d5" })
    hl(0, "SqlTransaction",   { bold = true,   fg = "#e0af68" })
    hl(0, "SqlAggregate",     { bold = true,   fg = "#89b4fa" })
    hl(0, "SqlWindow",        { bold = true,   fg = "#cba6f7" })
    hl(0, "SqlCTE",           { bold = true,   fg = "#7dcfff" })
    hl(0, "SqlSubquery",      { italic = true, fg = "#9399b2" })
    hl(0, "SqlNull",          { fg = "#9399b2"                })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "@keyword.sql",          { bold = true, fg = p.blue })
        hl(0, "@function.builtin.sql", { bold = true, fg = p.blue })
        hl(0, "SqlColumn",             { fg = p.blue              })
      end
      if p.yellow then
        hl(0, "@keyword.type.sql",     { bold = true, fg = p.yellow })
        hl(0, "SqlTable",              { bold = true, fg = p.yellow })
      end
      if p.red    then
        hl(0, "@keyword.operator.sql", { bold = true, fg = p.red })
        hl(0, "SqlConstraint",         { bold = true, fg = p.red })
      end
      if p.green  then hl(0, "@string.sql", { fg = p.green }) end
      if p.peach  then hl(0, "@number.sql", { fg = p.peach }) end
      if p.mauve  then hl(0, "SqlWindow",   { bold = true, fg = p.mauve }) end
      if p.cyan   then hl(0, "SqlCTE",      { bold = true, fg = p.cyan  }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 SQL UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function format_sql()
    if vim.fn.executable("sql-formatter") == 1 then
      local bufnr  = vim.api.nvim_get_current_buf()
      local lines  = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local result = vim.fn.systemlist(
        "sql-formatter --language postgresql",
        lines
      )
      if vim.v.shell_error == 0 then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, result)
        vim.notify("🗄️  SQL formatted", vim.log.levels.INFO,
          { title = "SQL", timeout = 1000 })
      end
    elseif vim.fn.executable("sqlfluff") == 1 then
      local file = vim.api.nvim_buf_get_name(0)
      vim.fn.system("sqlfluff fix --dialect postgresql " .. vim.fn.shellescape(file))
      vim.cmd("checktime")
      vim.notify("🗄️  SQL fixed (sqlfluff)", vim.log.levels.INFO,
        { title = "SQL", timeout = 1000 })
    else
      vim.lsp.buf.format({ async = true })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        vim.list_extend(opts.ensure_installed, { "sql" })
      end,
    },
  
    -- ── vim-dadbod — database connections + query runner ─────────────────────────
    {
      "tpope/vim-dadbod",
      cmd  = { "DB", "DBUI", "DBUIToggle", "DBUIAddConnection" },
      lazy = true,
    },
  
    {
      "kristijanhusak/vim-dadbod-ui",
      dependencies = {
        "tpope/vim-dadbod",
        { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" } },
      },
      cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
  
      keys = {
        { "<leader>sqd", "<cmd>DBUIToggle<cr>",         desc = "🗄️  SQL: Toggle DB UI"          },
        { "<leader>sqa", "<cmd>DBUIAddConnection<cr>",  desc = "🗄️  SQL: Add connection"         },
        { "<leader>sqf", "<cmd>DBUIFindBuffer<cr>",     desc = "🗄️  SQL: Find buffer"            },
        { "<leader>sqr", "<cmd>DBUIRenameBuffer<cr>",   desc = "🗄️  SQL: Rename buffer"          },
        { "<leader>sqq", format_sql,                    ft   = { "sql", "mysql", "plsql" }, desc = "🗄️  SQL: Format" },
        {
          "<leader>sqe",
          function()
            -- Execute selection or current query
            local mode = vim.fn.mode()
            if mode == "v" or mode == "V" then
              vim.cmd("'<,'>DB")
            else
              -- Find query boundaries (separated by ;)
              vim.cmd("DB")
            end
          end,
          mode = { "n", "v" },
          ft   = { "sql", "mysql", "plsql" },
          desc = "🗄️  SQL: Execute query",
        },
        {
          "<leader>sqi",
          function()
            vim.notify(
              table.concat({
                "🗄️  SQL Environment",
                "──────────────────────────────────",
                string.format("  sqls:         %s", vim.fn.executable("sqls")        == 1 and "✅" or "⭕"),
                string.format("  sql-formatter:%s", vim.fn.executable("sql-formatter") == 1 and "✅" or "⭕"),
                string.format("  sqlfluff:     %s", vim.fn.executable("sqlfluff")    == 1 and "✅" or "⭕"),
                string.format("  psql:         %s", vim.fn.executable("psql")        == 1 and "✅" or "⭕"),
                string.format("  mysql:        %s", vim.fn.executable("mysql")       == 1 and "✅" or "⭕"),
                string.format("  sqlite3:      %s", vim.fn.executable("sqlite3")     == 1 and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "SQL Info" }
            )
          end,
          ft   = { "sql", "mysql", "plsql" },
          desc = "🗄️  SQL: Environment info",
        },
      },
  
      init = function()
        vim.g.db_ui_use_nerd_fonts           = 1
        vim.g.db_ui_show_database_icon       = 1
        vim.g.db_ui_save_location            = vim.fn.stdpath("data") .. "/dadbod-ui"
        vim.g.db_ui_winwidth                 = 30
        vim.g.db_ui_auto_execute_table_helpers = 1
        vim.g.db_ui_disable_progress_bar     = 0
        vim.g.db_ui_execute_on_save          = 0
        vim.g.db_ui_hide_schemas             = { "pg_toast", "pg_temp.*", "pg_toast_temp.*",
                                                 "information_schema", "performance_schema" }
        vim.g.db_ui_table_helpers = {
          postgresql  = { List = "select * from {table} limit 200 offset {offset}" },
          sqlite      = { List = "select * from {table} limit 200 offset {offset}" },
          mysql       = { List = "select * from {table} limit 200 offset {offset}" },
        }
      end,
    },
  
    -- ── LSP: sqls ─────────────────────────────────────────────────────────────────
    {
      "neovim/nvim-lspconfig",
      ft   = { "sql", "mysql", "plsql" },
      opts = {
        servers = {
          sqls = {
            on_attach = function(client, bufnr)
              require("sqls").on_attach(client, bufnr)
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
            settings = {
              sqls = {
                connections = {},  -- populated from project config
              },
            },
          },
        },
      },
    },
  
    {
      "nanotee/sqls.nvim",
      ft           = { "sql", "mysql" },
      dependencies = { "neovim/nvim-lspconfig" },
      lazy         = true,
    },
  
    -- ── Config (highlights + ft options) ──────────────────────────────────────────
    {
      "nvim-lua/plenary.nvim",
      ft = { "sql", "mysql", "plsql" },
      config = function()
        setup_highlights()
  
        -- dadbod-completion
        vim.api.nvim_create_autocmd("FileType", {
          pattern  = { "sql", "mysql", "plsql" },
          callback = function()
            local ok, cmp = pcall(require, "cmp")
            if ok then
              cmp.setup.buffer({
                sources = cmp.config.sources({
                  { name = "vim-dadbod-completion", priority = 1100 },
                  { name = "buffer",                priority = 500  },
                }),
              })
            end
  
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.commentstring = "-- %s"
          end,
        })
  
        local aug = vim.api.nvim_create_augroup("AshSql", { clear = true })
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🗄️  SQL highlights synced", vim.log.levels.INFO,
              { title = "ASH SQL", timeout = 1200 })
          end,
        })
      end,
    },
  }