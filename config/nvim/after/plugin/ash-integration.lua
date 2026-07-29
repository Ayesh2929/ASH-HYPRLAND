-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔥 ASH INTEGRATION — NEOVIM CORE v5.0 OMEGA                              ║
-- ║   CLI bridge · theme sync · mode detection · event system · health check      ║
-- ║   Palette injection · statusline · analytics · ASH ↔ Neovim bidirectional     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔒 GUARD — only run once
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if vim.g.ash_integration_loaded then return end
vim.g.ash_integration_loaded = true

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎯 CONSTANTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ASH = {
  -- Feature flags
  ENABLED         = vim.fn.executable("ash") == 1,
  DEBUG           = vim.g.ash_debug or false,

  -- Paths
  CONFIG_DIR      = vim.fn.expand("~/.config/ash"),
  DATA_DIR        = vim.fn.stdpath("data") .. "/ash",
  STATE_FILE      = vim.fn.stdpath("data") .. "/ash_nvim_state.json",

  -- IPC
  SOCKET          = os.getenv("XDG_RUNTIME_DIR") and
                    os.getenv("XDG_RUNTIME_DIR") .. "/ash-nvim.sock" or
                    "/tmp/ash-nvim.sock",
  -- Timing
  DEBOUNCE_MS     = 150,
  HEALTH_INTERVAL = 300,   -- seconds between health pings
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📊 STATE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local State = {
  -- Current ASH state
  theme       = nil,
  mode        = nil,
  palette     = {},
  plugins     = {},

  -- Runtime
  connected   = false,
  last_sync   = 0,
  error_count = 0,

  -- Analytics
  analytics   = {
    session_start  = os.time(),
    theme_changes  = 0,
    mode_changes   = 0,
    commands_run   = 0,
    files_edited   = 0,
  },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 UTILITIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function log(msg, level, opts)
  if not ASH.DEBUG and (level == vim.log.levels.DEBUG) then return end
  vim.notify(
    "🔥 ASH: " .. tostring(msg),
    level or vim.log.levels.INFO,
    vim.tbl_extend("force", {
      title   = "ASH Integration",
      timeout = 2000,
    }, opts or {})
  )
end

local function run_ash(args, callback)
  if not ASH.ENABLED then return end

  local result = {}
  local job_id = vim.fn.jobstart(
    vim.list_extend({ "ash" }, vim.split(args, " ", { trimempty = true })),
    {
      stdout_buffered = true,
      stderr_buffered = true,
      on_stdout = function(_, data)
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(result, line) end
        end
      end,
      on_exit = function(_, code)
        if callback then
          vim.schedule(function()
            callback(code == 0, table.concat(result, "\n"))
          end)
        end
      end,
    }
  )

  if job_id <= 0 then
    log("Failed to start ash process", vim.log.levels.ERROR)
    if callback then callback(false, "") end
  end

  return job_id
end

local function run_ash_sync(args)
  if not ASH.ENABLED then return nil end
  local result = vim.fn.system("ash " .. args .. " 2>/dev/null")
  return vim.v.shell_error == 0 and vim.fn.trim(result) or nil
end

local function fire_event(pattern, data)
  vim.api.nvim_exec_autocmds("User", {
    pattern  = pattern,
    data     = data,
    modeline = false,
  })
end

local function debounce(fn, ms)
  local timer = nil
  return function(...)
    local args = { ... }
    if timer then
      vim.loop.timer_stop(timer)
      timer = nil
    end
    timer = vim.defer_fn(function()
      timer = nil
      fn(unpack(args))
    end, ms or ASH.DEBOUNCE_MS)
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔌 CLI BRIDGE — ash ↔ neovim communication
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local CLI = {}

function CLI.get_current_theme()
  return run_ash_sync("theme list --current --format=name")
end

function CLI.get_current_mode()
  return run_ash_sync("mode status --format=name")
end

function CLI.get_palette()
  local result = run_ash_sync("theme colors --format=json")
  if not result or result == "" then return {} end
  local ok, data = pcall(vim.fn.json_decode, result)
  return (ok and type(data) == "table") and data or {}
end

function CLI.get_active_plugins()
  local result = run_ash_sync("plugin list --active --format=json")
  if not result or result == "" then return {} end
  local ok, data = pcall(vim.fn.json_decode, result)
  return (ok and type(data) == "table") and data or {}
end

function CLI.apply_theme(name, opts)
  opts = opts or {}
  local cmd = "theme apply " .. vim.fn.shellescape(name)
  if opts.no_reload then cmd = cmd .. " --no-reload" end

  run_ash(cmd, function(ok, _)
    if ok then
      State.analytics.theme_changes = State.analytics.theme_changes + 1
      log("Theme applied: " .. name, vim.log.levels.INFO,
        { timeout = 1200, title = "ASH Theme" })
    else
      log("Failed to apply theme: " .. name, vim.log.levels.ERROR)
    end
  end)
end

function CLI.set_mode(mode_name)
  run_ash("mode " .. mode_name, function(ok, _)
    if ok then
      State.analytics.mode_changes = State.analytics.mode_changes + 1
      log("Mode: " .. mode_name, vim.log.levels.INFO,
        { timeout = 1000, title = "ASH Mode" })
    end
  end)
end

function CLI.ping()
  if not ASH.ENABLED then
    State.connected = false
    return false
  end
  local result = run_ash_sync("--version")
  State.connected = result ~= nil
  return State.connected
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 THEME SYNC ENGINE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ThemeSync = {}

function ThemeSync.sync()
  local theme = CLI.get_current_theme()
  if not theme or theme == "" then return end
  if theme == State.theme then return end  -- no change

  local prev    = State.theme
  State.theme   = theme

  -- Load palette
  local palette = CLI.get_palette()
  State.palette = palette

  -- Expose palette globally for plugins
  _G.AshDynamicPalette = palette

  -- Try to apply theme via the ASH theme engine
  local ok_engine, engine = pcall(require, "themes.init")
  if ok_engine and engine.is_valid and engine.is_valid(theme) then
    engine.apply(theme, { silent = true, notify = false })
  else
    -- Fallback: try as a colorscheme directly
    local ok_cs = pcall(vim.cmd.colorscheme, theme)
    if not ok_cs then
      -- Try catppuccin-mocha as fallback
      pcall(vim.cmd.colorscheme, "catppuccin-mocha")
    end
  end

  -- Fire event for all listeners
  fire_event("AshThemeChanged", {
    from    = prev,
    to      = theme,
    palette = palette,
  })

  State.last_sync = os.time()

  if ASH.DEBUG then
    log(string.format("Theme synced: %s → %s", prev or "none", theme),
      vim.log.levels.DEBUG)
  end
end

-- Debounced sync (avoids hammering on rapid changes)
ThemeSync.sync_debounced = debounce(ThemeSync.sync, 300)

function ThemeSync.init()
  -- Initial sync on startup
  vim.defer_fn(ThemeSync.sync, 500)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎭 MODE DETECTION ENGINE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ModeDetect = {}

-- Neovim-side mode specific settings
local MODE_NVIM_SETTINGS = {
  focus = {
    -- Minimal UI for focus mode
    setup = function()
      vim.opt.laststatus   = 0
      vim.opt.showtabline  = 0
      vim.opt.signcolumn   = "no"
      vim.opt.number       = false
      vim.opt.relativenumber = false
    end,
    teardown = function()
      vim.opt.laststatus   = 3
      vim.opt.showtabline  = 2
      vim.opt.signcolumn   = "yes"
      vim.opt.number       = true
      vim.opt.relativenumber = true
    end,
  },

  game = {
    -- Disable all non-essential features in game mode
    setup = function()
      vim.opt.laststatus  = 0
      vim.opt.showtabline = 0
    end,
    teardown = function()
      vim.opt.laststatus  = 3
      vim.opt.showtabline = 2
    end,
  },

  cinema = {
    -- Full-screen immersive mode
    setup = function()
      vim.opt.laststatus   = 0
      vim.opt.showtabline  = 0
      vim.opt.cmdheight    = 0
      vim.opt.ruler        = false
    end,
    teardown = function()
      vim.opt.laststatus   = 3
      vim.opt.showtabline  = 2
      vim.opt.cmdheight    = 1
      vim.opt.ruler        = true
    end,
  },

  present = {
    -- Presentation mode: clean, large font
    setup = function()
      vim.opt.laststatus   = 0
      vim.opt.showtabline  = 0
      vim.opt.number       = false
      vim.opt.relativenumber = false
      vim.opt.signcolumn   = "no"
      vim.opt.colorcolumn  = ""
    end,
    teardown = function()
      vim.opt.laststatus   = 3
      vim.opt.showtabline  = 2
      vim.opt.number       = true
      vim.opt.relativenumber = true
      vim.opt.signcolumn   = "yes"
    end,
  },
}

function ModeDetect.apply_mode(mode_name)
  -- Teardown previous mode
  local prev_cfg = STATE and STATE.mode and MODE_NVIM_SETTINGS[STATE.mode]
  if prev_cfg and prev_cfg.teardown then
    pcall(prev_cfg.teardown)
  end

  -- Apply new mode
  local new_cfg = MODE_NVIM_SETTINGS[mode_name]
  if new_cfg and new_cfg.setup then
    pcall(new_cfg.setup)
  end

  local prev    = State.mode
  State.mode    = mode_name

  fire_event("AshModeChanged", {
    from = prev,
    to   = mode_name,
  })
end

function ModeDetect.sync()
  local mode = CLI.get_current_mode()
  if not mode or mode == "" then return end
  if mode == State.mode then return end

  ModeDetect.apply_mode(mode)

  if ASH.DEBUG then
    log("Mode synced: " .. mode, vim.log.levels.DEBUG)
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📊 ANALYTICS REPORTER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local Analytics = {}

function Analytics.collect_session()
  local elapsed = os.time() - State.analytics.session_start
  return {
    session_duration  = elapsed,
    theme_changes     = State.analytics.theme_changes,
    mode_changes      = State.analytics.mode_changes,
    commands_run      = State.analytics.commands_run,
    files_edited      = State.analytics.files_edited,
    buffers_open      = #vim.api.nvim_list_bufs(),
    windows_open      = #vim.api.nvim_list_wins(),
    current_theme     = State.theme or "unknown",
    current_mode      = State.mode  or "default",
    neovim_version    = tostring(vim.version()),
    ash_connected     = State.connected,
  }
end

function Analytics.push()
  if not ASH.ENABLED then return end

  local data   = Analytics.collect_session()
  local json   = vim.fn.json_encode(data)
  local tmpfile= vim.fn.tempname() .. ".json"

  local f = io.open(tmpfile, "w")
  if f then
    f:write(json)
    f:close()
    -- Push to ASH analytics (non-blocking)
    vim.fn.jobstart({ "ash", "analytics", "push", "--data", tmpfile }, {
      on_exit = function()
        vim.fn.delete(tmpfile)
      end,
    })
  end
end

function Analytics.save_state()
  local data = {
    theme     = State.theme,
    mode      = State.mode,
    palette   = State.palette,
    saved_at  = os.time(),
    analytics = State.analytics,
  }

  local f = io.open(ASH.STATE_FILE, "w")
  if f then
    local ok, json = pcall(vim.fn.json_encode, data)
    if ok then
      f:write(json)
    end
    f:close()
  end
end

function Analytics.load_state()
  local f = io.open(ASH.STATE_FILE, "r")
  if not f then return end

  local content = f:read("*a")
  f:close()

  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok or type(data) ~= "table" then return end

  -- Restore analytics (don't restore theme/mode, let sync handle that)
  if data.analytics then
    State.analytics = vim.tbl_extend("force", State.analytics, data.analytics)
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 HEALTH CHECK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local Health = {}

function Health.check()
  return {
    ash_cli    = vim.fn.executable("ash") == 1,
    ash_version= run_ash_sync("--version"),
    connected  = State.connected,
    theme      = State.theme,
    mode       = State.mode,
    palette_keys = vim.tbl_count(State.palette),
    plugins    = #State.plugins,
    error_count= State.error_count,
    uptime     = os.time() - State.analytics.session_start,
  }
end

function Health.show()
  local info = Health.check()
  local lines = {
    "🔥 ASH Integration Health",
    "──────────────────────────────────",
    string.format("  CLI:      %s", info.ash_cli and "✅ found" or "❌ not found"),
    string.format("  Version:  %s", info.ash_version or "unknown"),
    string.format("  Connected:%s", info.connected and "✅" or "⭕"),
    string.format("  Theme:    %s", info.theme or "(none)"),
    string.format("  Mode:     %s", info.mode  or "(default)"),
    string.format("  Palette:  %d colours", info.palette_keys),
    string.format("  Plugins:  %d active", info.plugins),
    string.format("  Errors:   %d", info.error_count),
    string.format("  Uptime:   %dm", math.floor(info.uptime / 60)),
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO,
    { title = "ASH Health" })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🌐 GLOBAL API — exposed as _G.Ash
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_G.Ash = {
  -- State accessors
  theme         = function() return State.theme   end,
  mode          = function() return State.mode    end,
  palette       = function() return State.palette end,
  connected     = function() return State.connected end,
  analytics     = function() return Analytics.collect_session() end,

  -- Actions
  apply_theme   = CLI.apply_theme,
  set_mode      = CLI.set_mode,
  sync_theme    = ThemeSync.sync,
  sync_mode     = ModeDetect.sync,
  health        = Health.show,
  run           = run_ash,
  run_sync      = run_ash_sync,

  -- Palette helpers
  colour = function(key, fallback)
    return State.palette[key] or fallback
  end,

  -- Event helpers
  on = function(event, fn)
    local aug = vim.api.nvim_create_augroup("AshUserCallback_" .. #vim.api.nvim_get_autocmds({}) , { clear = false })
    vim.api.nvim_create_autocmd("User", {
      group    = aug,
      pattern  = event,
      callback = fn,
    })
  end,
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📡 AUTOCMD SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshIntegration", { clear = true })

-- Sync when Neovim regains focus (user switched back from external ASH commands)
vim.api.nvim_create_autocmd("FocusGained", {
  group    = aug,
  callback = debounce(function()
    ThemeSync.sync_debounced()
    ModeDetect.sync()
  end, 500),
})

-- Sync after `:colorscheme` command (report back to ASH)
vim.api.nvim_create_autocmd("ColorScheme", {
  group    = aug,
  callback = function(ev)
    local cs = ev.match
    -- If Neovim changes colorscheme, tell ASH (if different from current)
    if cs ~= State.theme and ASH.ENABLED then
      -- Map colorscheme name to ASH theme name if possible
      local ok_engine, engine = pcall(require, "themes.init")
      if ok_engine and engine.is_valid and engine.is_valid(cs) then
        State.theme = cs
      end
    end
  end,
})

-- Track file edits for analytics
vim.api.nvim_create_autocmd("BufWritePost", {
  group    = aug,
  callback = function()
    State.analytics.files_edited = State.analytics.files_edited + 1
  end,
})

-- Save state on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  group    = aug,
  callback = function()
    Analytics.save_state()
    if ASH.ENABLED then
      Analytics.push()
      -- Notify ASH that Neovim is closing
      vim.fn.system("ash config set nvim.active false 2>/dev/null &")
    end
  end,
})

-- Listen for ASH events from external processes (via named pipe / file)
local function setup_ipc_listener()
  local event_file = ASH.DATA_DIR .. "/nvim-events"
  vim.fn.mkdir(ASH.DATA_DIR, "p")

  local ipc_aug = vim.api.nvim_create_augroup("AshIPC", { clear = true })

  vim.api.nvim_create_autocmd("FocusGained", {
    group    = ipc_aug,
    callback = function()
      local f = io.open(event_file, "r")
      if not f then return end
      local content = f:read("*a")
      f:close()

      if content == "" then return end

      -- Clear the file
      local fw = io.open(event_file, "w")
      if fw then fw:close() end

      -- Process events
      for line in content:gmatch("[^\n]+") do
        local ok, event = pcall(vim.fn.json_decode, line)
        if ok and event and event.type then
          if event.type == "theme_changed" and event.theme then
            ThemeSync.sync()
          elseif event.type == "mode_changed" and event.mode then
            ModeDetect.sync()
          elseif event.type == "reload" then
            vim.cmd("source $MYVIMRC")
          end
        end
      end
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🚀 STARTUP SEQUENCE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function startup()
  -- Create data directory
  vim.fn.mkdir(ASH.DATA_DIR, "p")

  -- Load persisted state (analytics)
  Analytics.load_state()

  -- Check ASH CLI availability
  if not CLI.ping() then
    if ASH.DEBUG then
      log("ASH CLI not available — integration in limited mode",
        vim.log.levels.DEBUG)
    end
    return
  end

  State.connected = true

  -- Setup IPC listener
  setup_ipc_listener()

  -- Register Neovim with ASH
  vim.fn.jobstart({
    "ash", "config", "set", "nvim.active", "true",
    "--silent",
  }, { detach = true })

  -- Initial theme + mode sync
  ThemeSync.init()
  vim.defer_fn(ModeDetect.sync, 800)

  -- Load active plugins list
  vim.defer_fn(function()
    State.plugins = CLI.get_active_plugins()
  end, 1000)

  -- Periodic health ping (every HEALTH_INTERVAL seconds)
  local function schedule_health()
    vim.defer_fn(function()
      if CLI.ping() then
        State.error_count = 0
      else
        State.error_count = State.error_count + 1
        if State.error_count > 5 then
          log("ASH CLI lost connection", vim.log.levels.WARN)
        end
      end
      schedule_health()
    end, ASH.HEALTH_INTERVAL * 1000)
  end
  schedule_health()

  -- User commands
  vim.api.nvim_create_user_command("AshHealth",   Health.show,         { desc = "🔥 ASH: Health check"      })
  vim.api.nvim_create_user_command("AshSync",     ThemeSync.sync,      { desc = "🔥 ASH: Sync theme"        })
  vim.api.nvim_create_user_command("AshAnalytics",function()
    vim.notify(vim.inspect(Analytics.collect_session()), vim.log.levels.INFO,
      { title = "ASH Analytics" })
  end, { desc = "🔥 ASH: Show analytics" })

  vim.api.nvim_create_user_command("AshTheme", function(args)
    if args.args ~= "" then
      CLI.apply_theme(args.args)
    else
      ThemeSync.sync()
    end
  end, {
    nargs    = "?",
    desc     = "🔥 ASH: Apply or sync theme",
    complete = function()
      local result = run_ash_sync("theme list --format=name")
      return result and vim.split(result, "\n") or {}
    end,
  })

  vim.api.nvim_create_user_command("AshMode", function(args)
    if args.args ~= "" then
      CLI.set_mode(args.args)
    else
      ModeDetect.sync()
    end
  end, {
    nargs    = "?",
    desc     = "🔥 ASH: Set or sync mode",
    complete = function()
      return {
        "default", "focus", "game", "cinema", "present",
        "work", "stream", "privacy", "battery",
      }
    end,
  })

  -- Expose state for statusline components
  _G.AshStatus = function()
    local theme = State.theme and (" 🔥 " .. State.theme) or ""
    local mode  = (State.mode and State.mode ~= "default")
      and (" 🎭 " .. State.mode) or ""
    return theme .. mode
  end

  if ASH.DEBUG then
    log("Integration initialized — CLI connected", vim.log.levels.DEBUG)
  end
end

-- Run on VimEnter so all plugins are loaded first
vim.api.nvim_create_autocmd("VimEnter", {
  group    = aug,
  once     = true,
  callback = startup,
})