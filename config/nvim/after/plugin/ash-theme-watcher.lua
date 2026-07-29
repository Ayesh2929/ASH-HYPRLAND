-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       👁️  ASH THEME WATCHER — FILE SYSTEM MONITOR v5.0 OMEGA                   ║
-- ║   libuv fs_event · palette hot-reload · plugin highlight refresh               ║
-- ║   Debounced · zero-flicker · cross-plugin broadcast · change detection         ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔒 GUARD
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if vim.g.ash_theme_watcher_loaded then return end
vim.g.ash_theme_watcher_loaded = true

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎯 CONSTANTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local WATCH = {
  -- Directories to watch for theme changes
  DIRS = {
    vim.fn.expand("~/.config/ash/themes/dynamic"),
    vim.fn.expand("~/.config/ash/themes/active"),
    vim.fn.stdpath("data") .. "/ash",
  },

  -- Specific files to watch
  FILES = {
    vim.fn.expand("~/.config/ash/current-palette.json"),
    vim.fn.expand("~/.config/ash/themes/active.conf"),
    vim.fn.expand("~/.config/ash/current-theme"),
    vim.fn.stdpath("data") .. "/ash_theme.txt",
    vim.fn.stdpath("data") .. "/ash_palette.json",
    vim.fn.stdpath("data") .. "/ash_mode.txt",
  },

  -- Extensions to watch in directories
  EXTENSIONS = { ".json", ".conf", ".lua", ".toml" },

  -- Debounce settings
  DEBOUNCE_MS  = 200,
  MIN_INTERVAL = 1.0,    -- minimum seconds between reloads

  -- Animation
  FLASH_MS     = 250,    -- milliseconds to flash highlights on change
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📊 STATE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local Watcher = {
  handles      = {},       -- active fs_event handles
  timers       = {},       -- active debounce timers
  last_reload  = 0,        -- timestamp of last reload
  reload_count = 0,        -- total reload count
  watching     = false,    -- is watching active
  paused       = false,    -- temporarily paused

  -- Snapshot of last known content (for change detection)
  snapshots    = {},
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 UTILITIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function log(msg, level)
  if not vim.g.ash_debug and level == vim.log.levels.DEBUG then return end
  vim.notify("👁️  ASH Watcher: " .. msg, level or vim.log.levels.INFO,
    { title = "Theme Watcher", timeout = 1500 })
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

local function has_changed(path, content)
  local prev = Watcher.snapshots[path]
  if prev == content then return false end
  Watcher.snapshots[path] = content
  return true
end

local function get_file_content(path)
  if vim.fn.filereadable(path) ~= 1 then return nil end
  return read_file(path)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 RELOAD ENGINE — apply theme changes to all active plugins
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local Reload = {}

-- Registry of plugins that need highlight refresh on theme change
local PLUGIN_REFRESHERS = {
  -- Treesitter
  treesitter = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        pcall(vim.treesitter.stop, buf)
        pcall(vim.treesitter.start, buf)
      end
    end
  end,

  -- nvim-cmp
  cmp = function()
    local ok, _ = pcall(require, "cmp")
    if not ok then return end
    -- cmp picks up highlights automatically via ColorScheme event
  end,

  -- telescope.nvim
  telescope = function()
    local ok, _ = pcall(require, "telescope")
    if not ok then return end
    -- Telescope re-reads highlight groups dynamically
  end,

  -- gitsigns.nvim
  gitsigns = function()
    local ok, gs = pcall(require, "gitsigns")
    if not ok then return end
    -- Refresh gitsigns in all loaded buffers
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        pcall(gs.attach, buf)
      end
    end
  end,

  -- illuminate.nvim
  illuminate = function()
    local ok, ill = pcall(require, "illuminate")
    if not ok then return end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        pcall(ill.refresh_buf, buf)
      end
    end
  end,

  -- indent-blankline
  ibl = function()
    local ok, ibl = pcall(require, "ibl")
    if not ok then return end
    pcall(ibl.refresh)
  end,

  -- mini.indentscope
  mini_indent = function()
    local ok, mini_i = pcall(require, "mini.indentscope")
    if not ok then return end
    pcall(function()
      if mini_i.config then
        -- Force redraw of indent scope
        vim.cmd("redrawstatus")
        vim.cmd("redraw!")
      end
    end)
  end,

  -- nvim-notify
  notify = function()
    local ok, notify = pcall(require, "notify")
    if not ok then return end
    -- notify picks up hl groups automatically
    pcall(notify.dismiss, { silent = true, pending = false })
  end,

  -- lualine
  lualine = function()
    local ok, ll = pcall(require, "lualine")
    if not ok then return end

    -- Try to refresh lualine theme from ASH
    local ok_ash, ash_int = pcall(require, "themes.integrations.lualine")
    if ok_ash and ash_int.setup then
      local ok_pal, pal_mod = pcall(require, "themes.palette")
      if ok_pal then
        local p = pal_mod.extract_from_colorscheme()
        ash_int.setup(p)
      end
    end
  end,

  -- bufferline
  bufferline = function()
    local ok, _ = pcall(require, "bufferline")
    if not ok then return end
    -- bufferline re-reads hl groups on next render
    vim.cmd("redrawtabline")
  end,

  -- nvim-dap-ui
  dapui = function()
    local ok, dapui = pcall(require, "dapui")
    if not ok then return end
    -- dapui re-reads hl groups automatically
  end,

  -- neogit
  neogit = function()
    local ok, _ = pcall(require, "neogit")
    if not ok then return end
    -- neogit re-reads on next open
  end,

  -- alpha-nvim
  alpha = function()
    local ok, _ = pcall(require, "alpha")
    if not ok then return end
    vim.cmd("redraw!")
  end,
}

function Reload.refresh_all_plugins()
  for name, fn in pairs(PLUGIN_REFRESHERS) do
    local ok, err = pcall(fn)
    if not ok and vim.g.ash_debug then
      log("Plugin refresh failed (" .. name .. "): " .. tostring(err),
        vim.log.levels.DEBUG)
    end
  end
end

function Reload.apply_integration_highlights()
  -- Re-apply all integration highlight groups
  local ok_pal, pal_mod = pcall(require, "themes.palette")
  local palette = ok_pal and pal_mod.extract_from_colorscheme() or {}

  local integrations = {
    "lualine",
    "gitsigns",
    "which-key",
    "notify",
    "noice",
    "telescope",
    "cmp",
    "neo-tree",
    "bufferline",
    "alpha",
    "trouble",
    "dap",
    "indent",
    "misc",
  }

  for _, name in ipairs(integrations) do
    local ok, mod = pcall(require, "themes.integrations." .. name)
    if ok and mod.apply and next(palette) then
      pcall(mod.apply, palette)
    end
  end

  -- Apply highlights layer
  local ok_hl, hl_mod = pcall(require, "themes.highlights")
  if ok_hl and hl_mod.apply then
    pcall(hl_mod.apply)
  end
end

function Reload.full_reload(source)
  -- Guard: don't reload too frequently
  local now = os.time()
  if (now - Watcher.last_reload) < WATCH.MIN_INTERVAL then return end
  if Watcher.paused then return end

  Watcher.last_reload = now
  Watcher.reload_count = Watcher.reload_count + 1

  -- Re-apply palette from ash-dynamic
  local ok_dyn, dyn = pcall(require, "themes.ash-dynamic")
  if ok_dyn then
    pcall(dyn.invalidate)
    if vim.g.colors_name == "ash-dynamic" then
      pcall(dyn.apply)
    end
  end

  -- Fire the main theme-changed event
  vim.api.nvim_exec_autocmds("ColorScheme", {
    pattern  = vim.g.colors_name or "*",
    modeline = false,
  })

  vim.api.nvim_exec_autocmds("User", {
    pattern  = "AshThemeChanged",
    data     = { source = source or "file_watch" },
    modeline = false,
  })

  -- Brief delay then refresh plugins (let ColorScheme handlers run first)
  vim.defer_fn(function()
    Reload.apply_integration_highlights()
    Reload.refresh_all_plugins()

    -- Flash all windows to signal reload (visual feedback)
    if vim.g.ash_theme_flash ~= false then
      Reload.flash_effect()
    end
  end, 50)

  if vim.g.ash_debug then
    log(string.format(
      "Reload #%d triggered by: %s",
      Watcher.reload_count,
      source or "unknown"
    ), vim.log.levels.DEBUG)
  end
end

function Reload.flash_effect()
  -- Very brief visual flash to signal successful theme reload
  local ns = vim.api.nvim_create_namespace("ash_theme_flash")

  -- Flash all visible windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" then
      local lines = vim.api.nvim_buf_line_count(buf)
      local visible_end = math.min(
        lines,
        vim.fn.line("w$", win)
      )
      local visible_start = math.max(0, vim.fn.line("w0", win) - 1)

      pcall(vim.api.nvim_buf_set_extmark, buf, ns, visible_start, 0, {
        end_row    = visible_end,
        hl_group   = "Visual",
        hl_eol     = true,
        priority   = 999,
      })
    end
  end

  vim.defer_fn(function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_clear_namespace, buf, ns, 0, -1)
      end
    end
  end, WATCH.FLASH_MS)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📁 FS WATCHER — libuv-based file system event monitoring
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function should_watch_file(path)
  if not path then return false end
  for _, ext in ipairs(WATCH.EXTENSIONS) do
    if path:sub(-#ext) == ext then return true end
  end
  -- Also watch files without extension (like ash_theme.txt content)
  return path:match("%.txt$") ~= nil or path:match("palette") ~= nil
end

local debounce_timers = {}

local function debounced_reload(key, source, ms)
  if debounce_timers[key] then
    pcall(function() debounce_timers[key]:stop() end)
    debounce_timers[key] = nil
  end

  local timer = vim.loop.new_timer()
  debounce_timers[key] = timer

  timer:start(ms or WATCH.DEBOUNCE_MS, 0, vim.schedule_wrap(function()
    debounce_timers[key] = nil
    pcall(function() timer:stop(); timer:close() end)
    Reload.full_reload(source)
  end))
end

local function watch_path(path, recursive)
  if vim.fn.filereadable(path) ~= 1 and vim.fn.isdirectory(path) ~= 1 then
    return nil
  end

  local handle = vim.loop.new_fs_event()
  if not handle then return nil end

  local ok, err = handle:start(path, {
    recursive = recursive or false,
    watch_entry = false,
  }, vim.schedule_wrap(function(err2, filename, events)
    if err2 or Watcher.paused then return end

    -- Filter irrelevant files in directory watches
    if filename and not should_watch_file(filename) then return end

    local changed_path = filename
      and (path:match("/$") and path .. filename or path .. "/" .. filename)
      or path

    -- Content-based change detection for specific files
    local content = get_file_content(changed_path)
    if content and not has_changed(changed_path, content) then return end

    debounced_reload(
      changed_path,
      "fs_event: " .. (filename or vim.fn.fnamemodify(path, ":t")),
      WATCH.DEBOUNCE_MS
    )
  end))

  if not ok then
    pcall(function() handle:stop(); handle:close() end)
    return nil
  end

  return handle
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🚀 WATCHER CONTROL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function start_watching()
  if Watcher.watching then return end

  local count = 0

  -- Watch directories (recursive)
  for _, dir in ipairs(WATCH.DIRS) do
    if vim.fn.isdirectory(dir) == 1 then
      local handle = watch_path(dir, true)
      if handle then
        table.insert(Watcher.handles, handle)
        count = count + 1
      end
    end
  end

  -- Watch specific files
  for _, file in ipairs(WATCH.FILES) do
    if vim.fn.filereadable(file) == 1 then
      -- Take initial snapshot
      local content = get_file_content(file)
      if content then
        Watcher.snapshots[file] = content
      end

      local handle = watch_path(file, false)
      if handle then
        table.insert(Watcher.handles, handle)
        count = count + 1
      end
    end
  end

  Watcher.watching = count > 0

  if vim.g.ash_debug then
    log(string.format("Watching %d path(s)", count), vim.log.levels.DEBUG)
  end
end

local function stop_watching()
  Watcher.paused = true

  for _, handle in ipairs(Watcher.handles) do
    pcall(function()
      handle:stop()
      handle:close()
    end)
  end

  for _, timer in pairs(debounce_timers) do
    pcall(function() timer:stop(); timer:close() end)
  end

  Watcher.handles     = {}
  debounce_timers     = {}
  Watcher.watching    = false
  Watcher.paused      = false
end

local function pause_watching()
  Watcher.paused = true
end

local function resume_watching()
  Watcher.paused = false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎛️  USER COMMANDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vim.api.nvim_create_user_command("AshWatchStart", function()
  stop_watching()
  start_watching()
  log("File watcher started", vim.log.levels.INFO, { timeout = 1200 })
end, { desc = "👁️  ASH: Start theme watcher" })

vim.api.nvim_create_user_command("AshWatchStop", function()
  stop_watching()
  log("File watcher stopped", vim.log.levels.INFO, { timeout = 1200 })
end, { desc = "👁️  ASH: Stop theme watcher" })

vim.api.nvim_create_user_command("AshWatchStatus", function()
  local lines = {
    "👁️  ASH Theme Watcher Status",
    "──────────────────────────────────",
    string.format("  Active:   %s", Watcher.watching and "✅ yes" or "⭕ no"),
    string.format("  Paused:   %s", Watcher.paused   and "⏸  yes" or "▶  no"),
    string.format("  Handles:  %d", #Watcher.handles),
    string.format("  Reloads:  %d", Watcher.reload_count),
    string.format("  Snapshots:%d", vim.tbl_count(Watcher.snapshots)),
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO,
    { title = "ASH Watcher" })
end, { desc = "👁️  ASH: Watcher status" })

vim.api.nvim_create_user_command("AshReload", function()
  Reload.full_reload("manual")
  log("Manual reload triggered", vim.log.levels.INFO, { timeout = 1000 })
end, { desc = "👁️  ASH: Force reload theme" })

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔗 AUTOCMD HOOKS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshThemeWatcher", { clear = true })

-- Pause watcher while applying a theme (prevents feedback loop)
vim.api.nvim_create_autocmd("User", {
  group   = aug,
  pattern = "AshThemePreChange",
  callback = pause_watching,
})

-- Resume after theme applied
vim.api.nvim_create_autocmd("User", {
  group   = aug,
  pattern = "AshThemeChanged",
  callback = function()
    vim.defer_fn(resume_watching, 500)
  end,
})

-- Stop watcher cleanly on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  group    = aug,
  callback = stop_watching,
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🚀 INITIALISE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vim.api.nvim_create_autocmd("VimEnter", {
  group    = aug,
  once     = true,
  callback = function()
    -- Small delay to let all plugins initialize first
    vim.defer_fn(start_watching, 1500)
  end,
})