-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ⏱️  WAKATIME — ULTRA CODING ANALYTICS v5.0 OMEGA                         ║
-- ║   Automatic time tracking · language stats · project dashboard                 ║
-- ║   editor leaderboards · daily goals · ASH theme-synced status                  ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "WakaTimeActive",     { bold = true,   fg = "#9ece6a" })
    hl(0, "WakaTimeInactive",   { italic = true, fg = "#9399b2" })
    hl(0, "WakaTimeProject",    { bold = true,   fg = "#7aa2f7" })
    hl(0, "WakaTimeLanguage",   { italic = true, fg = "#cba6f7" })
    hl(0, "WakaTimeGoal",       { bold = true,   fg = "#f9e2af" })
    hl(0, "WakaTimeGoalMet",    { bold = true,   fg = "#9ece6a" })
    hl(0, "WakaTimeGoalMissed", { bold = true,   fg = "#f38ba8" })
    hl(0, "WakaTimeTime",       { fg = "#7dcfff"                })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green  then
        hl(0, "WakaTimeActive",   { bold = true, fg = p.green })
        hl(0, "WakaTimeGoalMet",  { bold = true, fg = p.green })
      end
      if p.blue   then hl(0, "WakaTimeProject",    { bold = true,   fg = p.blue   }) end
      if p.mauve  then hl(0, "WakaTimeLanguage",   { italic = true, fg = p.mauve  }) end
      if p.yellow then hl(0, "WakaTimeGoal",       { bold = true,   fg = p.yellow }) end
      if p.red    then hl(0, "WakaTimeGoalMissed", { bold = true,   fg = p.red    }) end
      if p.cyan   then hl(0, "WakaTimeTime",       { fg = p.cyan                  }) end
      local dim = p.overlay0 or "#9399b2"
      hl(0, "WakaTimeInactive", { italic = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 WAKATIME STATUS UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Cache for today's stats
  local _waka_cache    = { time = nil, today = nil, last_update = 0 }
  local CACHE_TTL      = 300  -- 5 minutes
  
  -- Parse wakatime-cli output for today's time
  local function fetch_today_stats()
    local now = os.time()
    if _waka_cache.today and (now - _waka_cache.last_update) < CACHE_TTL then
      return _waka_cache.today
    end
  
    -- Try wakatime CLI
    local result = vim.fn.trim(vim.fn.system(
      "wakatime-cli --today 2>/dev/null || wakatime --today 2>/dev/null"
    ))
  
    if vim.v.shell_error ~= 0 or result == "" then
      -- Try reading from wakatime heartbeats / summary file
      local summary_file = vim.fn.expand("~/.wakatime/wakatime.bak.json")
      if vim.fn.filereadable(summary_file) == 1 then
        local f = io.open(summary_file, "r")
        if f then
          local content = f:read("*a")
          f:close()
          local ok_j, data = pcall(vim.fn.json_decode, content)
          if ok_j and data and data.grand_total then
            result = data.grand_total.text or ""
          end
        end
      end
    end
  
    if result ~= "" then
      _waka_cache.today       = result
      _waka_cache.last_update = now
    end
  
    return result
  end
  
  -- Format time nicely
  local function format_time(raw)
    if not raw or raw == "" then return "" end
    -- Already formatted (e.g. "3 hrs 22 mins")
    return raw
  end
  
  -- Show detailed WakaTime stats
  local function show_waka_stats()
    local today = fetch_today_stats()
  
    -- Get project from git
    local project = vim.fn.trim(
      vim.fn.system("git -C " .. vim.fn.shellescape(vim.fn.getcwd()) .. " rev-parse --show-toplevel 2>/dev/null")
    )
    local project_name = vim.v.shell_error == 0
      and vim.fn.fnamemodify(project, ":t")
      or vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  
    local lines = {
      "⏱️  WakaTime Analytics",
      "──────────────────────────────────",
      string.format("  Today:    %s", today ~= "" and today or "no data yet"),
      string.format("  Project:  %s", project_name),
      string.format("  Language: %s", vim.bo.filetype ~= "" and vim.bo.filetype or "none"),
      "",
      "  Open wakatime.com for full stats  ",
    }
  
    vim.notify(
      table.concat(lines, "\n"),
      vim.log.levels.INFO,
      { title = "WakaTime" }
    )
  end
  
  -- Open WakaTime dashboard in browser
  local function open_dashboard()
    local url     = "https://wakatime.com/dashboard"
    local open_cmd= vim.fn.has("mac") == 1 and "open"
      or (vim.fn.executable("xdg-open") == 1 and "xdg-open" or "start")
    vim.fn.jobstart({ open_cmd, url }, { detach = true })
    vim.notify(
      "⏱️  Opening WakaTime dashboard…",
      vim.log.levels.INFO,
      { title = "WakaTime", timeout = 1200 }
    )
  end
  
  -- Check WakaTime API key configuration
  local function check_api_key()
    local cfg_file = vim.fn.expand("~/.wakatime.cfg")
    if vim.fn.filereadable(cfg_file) == 0 then
      vim.notify(
        "⏱️  WakaTime not configured.\nRun: :WakaTimeApiKey",
        vim.log.levels.WARN,
        { title = "WakaTime" }
      )
      return false
    end
  
    local f = io.open(cfg_file, "r")
    if not f then return false end
  
    local has_key = false
    for line in f:lines() do
      if line:match("^api_key%s*=") and not line:match("api_key%s*=%s*$") then
        has_key = true
        break
      end
    end
    f:close()
  
    if not has_key then
      vim.notify(
        "⏱️  WakaTime API key missing.\nAdd to ~/.wakatime.cfg:\n[settings]\napi_key = YOUR_KEY",
        vim.log.levels.WARN,
        { title = "WakaTime" }
      )
    end
  
    return has_key
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "wakatime/vim-wakatime",
      lazy  = false,           -- must be eager (tracks all file events)
      cond  = function()
        -- Only load if wakatime-cli is available
        return vim.fn.executable("wakatime-cli") == 1
            or vim.fn.executable("wakatime")     == 1
      end,
  
      keys = {
        {
          "<leader>wks",
          show_waka_stats,
          desc   = "⏱️  WakaTime: Today's stats",
          silent = true,
        },
        {
          "<leader>wkd",
          open_dashboard,
          desc   = "⏱️  WakaTime: Open dashboard",
          silent = true,
        },
        {
          "<leader>wkc",
          check_api_key,
          desc   = "⏱️  WakaTime: Check API key",
          silent = true,
        },
        {
          "<leader>wkr",
          function()
            _waka_cache.today       = nil
            _waka_cache.last_update = 0
            vim.notify("⏱️  WakaTime cache refreshed", vim.log.levels.INFO,
              { title = "WakaTime", timeout = 1000 })
          end,
          desc   = "⏱️  WakaTime: Refresh cache",
          silent = true,
        },
      },
  
      init = function()
        -- Suppress wakatime startup messages
        vim.g.wakatime_PyCLIPath  = ""
        vim.g.wakatime_CLIPath    = vim.fn.executable("wakatime-cli") == 1
          and vim.fn.exepath("wakatime-cli")
          or  vim.fn.exepath("wakatime")
  
        -- Log level: error only (avoid clutter)
        vim.g.wakatime_logLevel   = "ERROR"
  
        -- Proxy (read from environment)
        local proxy = os.getenv("WAKATIME_PROXY") or os.getenv("HTTPS_PROXY") or ""
        if proxy ~= "" then
          vim.g.wakatime_proxy = proxy
        end
  
        -- Debug mode (only when ASH debug is on)
        vim.g.wakatime_DebugEnabled = vim.g.ash_debug and 1 or 0
      end,
  
      config = function()
        setup_highlights()
  
        -- Verify API key on startup (non-blocking)
        vim.defer_fn(function()
          check_api_key()
        end, 3000)
  
        -- ── Expose statusline component ────────────────────────────────────────
        -- Shows today's time; cached to avoid blocking the UI
        _G.AshWakaTime = function()
          -- Only fetch if we haven't recently
          local now = os.time()
          if (now - _waka_cache.last_update) > CACHE_TTL then
            -- Async fetch (non-blocking)
            vim.fn.jobstart(
              "wakatime-cli --today 2>/dev/null || wakatime --today 2>/dev/null",
              {
                stdout_buffered = true,
                on_stdout = function(_, data)
                  if data and data[1] and data[1] ~= "" then
                    _waka_cache.today       = data[1]
                    _waka_cache.last_update = os.time()
                  end
                end,
              }
            )
          end
  
          local today = _waka_cache.today
          if today and today ~= "" then
            return string.format(" ⏱️  %s ", today)
          end
          return " ⏱️  "
        end
  
        -- ── Auto-update cache periodically ────────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshWakaTime", { clear = true })
  
        -- Refresh every 10 minutes via CursorHold
        local _last_refresh = 0
        vim.api.nvim_create_autocmd("CursorHold", {
          group    = aug,
          callback = function()
            local now = os.time()
            if (now - _last_refresh) > 600 then
              _last_refresh         = now
              _waka_cache.last_update = 0  -- force refresh
            end
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("⏱️  WakaTime highlights synced", vim.log.levels.INFO,
              { title = "ASH WakaTime", timeout = 1200 })
          end,
        })
  
        -- ── ASH integration: track theme changes as activity ──────────────────
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            -- Invalidate cache so next statusline refresh pulls fresh data
            _waka_cache.last_update = 0
          end,
        })
  
        -- ── User commands ──────────────────────────────────────────────────────
        vim.api.nvim_create_user_command("WakaTimeStats", function()
          show_waka_stats()
        end, { desc = "⏱️  Show WakaTime stats" })
  
        vim.api.nvim_create_user_command("WakaTimeDashboard", function()
          open_dashboard()
        end, { desc = "⏱️  Open WakaTime dashboard" })
  
        vim.api.nvim_create_user_command("WakaTimeApiKey", function()
          vim.ui.input(
            { prompt = "⏱️  WakaTime API key: ", default = "" },
            function(key)
              if not key or key == "" then return end
  
              local cfg = vim.fn.expand("~/.wakatime.cfg")
              local content = "[settings]\napi_key = " .. key .. "\n"
  
              -- Merge with existing config if present
              if vim.fn.filereadable(cfg) == 1 then
                local f = io.open(cfg, "r")
                if f then
                  local existing = f:read("*a")
                  f:close()
                  -- Replace api_key line if exists
                  if existing:match("api_key%s*=") then
                    content = existing:gsub("api_key%s*=.-\n", "api_key = " .. key .. "\n")
                  else
                    content = existing .. "\napi_key = " .. key .. "\n"
                  end
                end
              end
  
              local f = io.open(cfg, "w")
              if f then
                f:write(content)
                f:close()
                vim.notify(
                  "⏱️  API key saved to ~/.wakatime.cfg",
                  vim.log.levels.INFO,
                  { title = "WakaTime", timeout = 2000 }
                )
              end
            end
          )
        end, { desc = "⏱️  Set WakaTime API key" })
  
        if vim.g.ash_debug then
          local cli = vim.g.wakatime_CLIPath or ""
          vim.notify(
            string.format("⏱️  WakaTime loaded — CLI: %s", cli ~= "" and cli or "⭕"),
            vim.log.levels.DEBUG,
            { title = "ASH WakaTime" }
          )
        end
      end,
    },
  }