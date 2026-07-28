-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🗄️  DATABASE — ULTRA DATABASE MANAGER v5.0 OMEGA                         ║
-- ║   vim-dadbod · dadbod-ui · query runner · schema browser · completion         ║
-- ║   PostgreSQL · MySQL · SQLite · Redis · MongoDB · ASH theme-synced            ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── DBUI panel ────────────────────────────────────────────────────────────
    hl(0, "DBUITableName",           { bold = true,   fg = "#7aa2f7" })
    hl(0, "DBUISourceName",          { bold = true,   fg = "#f9e2af" })
    hl(0, "DBUIKeyName",             { italic = true, fg = "#cba6f7" })
    hl(0, "DBUIBlobValue",           { fg = "#9399b2"                })
    hl(0, "NotFound",                { italic = true, fg = "#9399b2" })
    hl(0, "DBUISource",              { bold = true,   fg = "#f9e2af" })
    hl(0, "DBUISourceSchema",        { italic = true, fg = "#94e2d5" })
    hl(0, "DBUIResultHeader",        { bold = true,   fg = "#7aa2f7" })
    hl(0, "DBUIResultHeaderKey",     { bold = true,   fg = "#f9e2af" })
    hl(0, "DBUIResultHeaderType",    { italic = true, fg = "#94e2d5" })
    hl(0, "DBUIResultValue",         { fg = "#a6e3a1"                })
    hl(0, "DBUIResultValueNull",     { italic = true, fg = "#9399b2" })
    hl(0, "DBUIResultValueNumber",   { fg = "#fab387"                })
    hl(0, "DBUIResultValueDate",     { italic = true, fg = "#7dcfff" })
    hl(0, "DBUIResultValueBool",     { bold = true,   fg = "#fab387" })
    hl(0, "DBUIFocusedTable",        { bold = true,   fg = "#9ece6a" })
    hl(0, "DBUITable",               { fg = "#cdd6f4"                })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then hl(0, "DBUITableName",  { bold = true, fg = p.blue   }) end
      if p.yellow then hl(0, "DBUISourceName", { bold = true, fg = p.yellow }) end
      if p.teal   then hl(0, "DBUISourceSchema",{ italic = true, fg = p.teal }) end
      if p.green  then
        hl(0, "DBUIResultValue",   { fg = p.green })
        hl(0, "DBUIFocusedTable",  { bold = true, fg = p.green })
      end
      if p.mauve  then hl(0, "DBUIKeyName",    { italic = true, fg = p.mauve }) end
      local dim = p.overlay0 or "#9399b2"
      hl(0, "DBUIResultValueNull", { italic = true, fg = dim })
      hl(0, "NotFound",            { italic = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 DATABASE UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Parse .env or project config for DATABASE_URL
  local function find_database_urls()
    local urls = {}
    local cwd  = vim.fn.getcwd()
  
    local env_files = {
      cwd .. "/.env",
      cwd .. "/.env.local",
      cwd .. "/.env.development",
      cwd .. "/.env.development.local",
    }
  
    for _, env_file in ipairs(env_files) do
      local f = io.open(env_file, "r")
      if f then
        for line in f:lines() do
          local key, value = line:match("^([%w_]*)=(.+)$")
          if key and value then
            local k_lower = key:lower()
            if k_lower:match("database_url") or k_lower:match("db_url")
              or k_lower:match("postgres") or k_lower:match("mysql")
              or k_lower:match("sqlite")
            then
              -- Strip quotes
              value = value:gsub("^[\"']", ""):gsub("[\"']$", "")
              table.insert(urls, { name = key, url = value, file = vim.fn.fnamemodify(env_file, ":t") })
            end
          end
        end
        f:close()
      end
    end
  
    return urls
  end
  
  -- Add connection from environment
  local function add_env_connection()
    local urls = find_database_urls()
  
    if #urls == 0 then
      vim.ui.input(
        { prompt = "🗄️  Connection URL: " },
        function(url)
          if url and url ~= "" then
            vim.ui.input({ prompt = "🗄️  Connection name: " }, function(name)
              if name and name ~= "" then
                vim.cmd("DBUI")
                -- Let DBUI handle the connection
                vim.notify(
                  "🗄️  Add connection in the DBUI panel",
                  vim.log.levels.INFO,
                  { title = "DB" }
                )
              end
            end)
          end
        end
      )
      return
    end
  
    local choices = vim.tbl_map(function(u)
      return string.format("[%s] %s", u.file, u.name)
    end, urls)
  
    vim.ui.select(choices, { prompt = "🗄️  Connection from env: " }, function(_, idx)
      if idx then
        local selected = urls[idx]
        vim.g["db_" .. idx] = selected.url
        vim.notify(
          string.format("🗄️  Set %s (%s)", selected.name, selected.file),
          vim.log.levels.INFO,
          { title = "DB", timeout = 1500 }
        )
      end
    end)
  end
  
  -- Execute SQL from visual selection
  local function exec_selection()
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" then
      vim.cmd("'<,'>DB")
    else
      vim.cmd("DB")
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- ── vim-dadbod core ───────────────────────────────────────────────────────────
    {
      "tpope/vim-dadbod",
      lazy = true,
      cmd  = { "DB" },
    },
  
    -- ── dadbod-ui — TUI browser ───────────────────────────────────────────────────
    {
      "kristijanhusak/vim-dadbod-ui",
      dependencies = {
        { "tpope/vim-dadbod",                    lazy = true },
        { "kristijanhusak/vim-dadbod-completion", lazy = true },
      },
      cmd = {
        "DBUI",
        "DBUIToggle",
        "DBUIAddConnection",
        "DBUIFindBuffer",
        "DBUIRenameBuffer",
        "DBUILastQueryInfo",
      },
  
      keys = {
        { "<leader>db",  "<cmd>DBUIToggle<cr>",          desc = "🗄️  DB: Toggle UI"            },
        { "<leader>da",  "<cmd>DBUIAddConnection<cr>",   desc = "🗄️  DB: Add connection"       },
        { "<leader>df",  "<cmd>DBUIFindBuffer<cr>",      desc = "🗄️  DB: Find buffer"          },
        { "<leader>dr",  "<cmd>DBUIRenameBuffer<cr>",    desc = "🗄️  DB: Rename buffer"        },
        { "<leader>dq",  "<cmd>DBUILastQueryInfo<cr>",   desc = "🗄️  DB: Last query info"      },
        { "<leader>de",  add_env_connection,             desc = "🗄️  DB: Add from .env"        },
        { "<leader>dx",  exec_selection,       mode = { "n", "v" }, desc = "🗄️  DB: Execute"   },
        {
          "<leader>di",
          function()
            local urls = find_database_urls()
            local lines = {
              "🗄️  Database Environment",
              "──────────────────────────────────",
              string.format("  psql:    %s", vim.fn.executable("psql")    == 1 and "✅" or "⭕"),
              string.format("  mysql:   %s", vim.fn.executable("mysql")   == 1 and "✅" or "⭕"),
              string.format("  sqlite3: %s", vim.fn.executable("sqlite3") == 1 and "✅" or "⭕"),
              string.format("  redis:   %s", vim.fn.executable("redis-cli") == 1 and "✅" or "⭕"),
              string.format("  mongosh: %s", vim.fn.executable("mongosh") == 1 and "✅" or "⭕"),
              "",
              string.format("  Env URLs found: %d", #urls),
            }
            for _, u in ipairs(urls) do
              table.insert(lines, string.format("    • %s (%s)", u.name, u.file))
            end
            vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "DB Info" })
          end,
          desc = "🗄️  DB: Environment info",
        },
      },
  
      init = function()
        -- ── DBUI global settings ──────────────────────────────────────────────
        vim.g.db_ui_use_nerd_fonts              = 1
        vim.g.db_ui_show_database_icon          = 1
        vim.g.db_ui_force_echo_notifications    = 1
        vim.g.db_ui_win_position                = "left"
        vim.g.db_ui_winwidth                    = 32
        vim.g.db_ui_save_location               = vim.fn.stdpath("data") .. "/dadbod-ui"
        vim.g.db_ui_tmp_query_location          = vim.fn.stdpath("data") .. "/dadbod-ui/tmp"
        vim.g.db_ui_auto_execute_table_helpers  = 1
        vim.g.db_ui_execute_on_save             = 0
        vim.g.db_ui_disable_progress_bar        = 0
        vim.g.db_ui_notification_width          = 62
        vim.g.db_ui_icons                       = {
          expanded        = { db = " 󰆼 ", buffers = " 󰓦 ", saved_queries = " 󰬃 ", schemas = " 󰅩 ", schema = " 󰅩 ", tables = " 󰓻 ", table = " 󱡠 " },
          collapsed       = { db = " 󰆼 ", buffers = " 󰓦 ", saved_queries = " 󰬃 ", schemas = " 󰅩 ", schema = " 󰅩 ", tables = " 󰓻 ", table = " 󱡠 " },
          saved_query     = " 󰆼 ",
          new_query       = " 󰬄 ",
          tables          = { middle = "├╴", last = "└╴" },
          add_connection  = " 󰐕 New connection",
          connection_ok   = "✅",
          connection_error= "❌",
        }
        vim.g.db_ui_table_helpers = {
          postgresql = {
            List           = "select * from {table} limit 200 offset {offset}",
            Indexes        = "select indexname, indexdef from pg_indexes where tablename = '{table}'",
            Foreign_Keys   = "select conname, conrelid::regclass, confrelid::regclass from pg_constraint where contype = 'f' and conrelid = '{table}'::regclass",
            Primary_Key    = "select a.attname from pg_index i join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any(i.indkey) where i.indrelid = '{table}'::regclass and i.indisprimary",
            Count          = "select count(*) from {table}",
            Columns        = "select column_name, data_type, character_maximum_length, is_nullable, column_default from information_schema.columns where table_name = '{table}'",
            Size           = "select pg_size_pretty(pg_total_relation_size('{table}'))",
          },
          sqlite = {
            List = "select * from {table} limit 200 offset {offset}",
            Count= "select count(*) from {table}",
          },
          mysql = {
            List = "select * from {table} limit 200 offset {offset}",
            Desc = "describe {table}",
            Count= "select count(*) from {table}",
          },
        }
        vim.g.db_ui_hide_schemas = {
          "pg_toast",
          "pg_temp.*",
          "pg_toast_temp.*",
          "information_schema",
          "performance_schema",
          "mysql",
          "sys",
        }
      end,
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshDatabase", { clear = true })
  
        -- dadbod-completion wire-up
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "sql", "mysql", "plsql" },
          callback = function()
            local ok, cmp = pcall(require, "cmp")
            if ok then
              cmp.setup.buffer({
                sources = cmp.config.sources({
                  { name = "vim-dadbod-completion", priority = 1200 },
                  { name = "buffer",                priority = 500  },
                }),
              })
            end
  
            -- Locally set commentstring for sql
            vim.opt_local.commentstring = "-- %s"
          end,
        })
  
        -- Disable mini plugins in DBUI panes
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "dbui", "dbout" },
          callback = function(ev)
            vim.b[ev.buf].miniindentscope_disable = true
            vim.b[ev.buf].minianimate_disable     = true
            vim.opt_local.number         = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn     = "no"
            vim.opt_local.foldcolumn     = "0"
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🗄️  DB highlights synced", vim.log.levels.INFO,
              { title = "ASH DB", timeout = 1200 })
          end,
        })
      end,
    },
  }