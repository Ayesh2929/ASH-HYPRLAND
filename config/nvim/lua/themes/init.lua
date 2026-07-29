-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🎨 ASH THEME ENGINE — INIT v5.0 OMEGA                                    ║
-- ║   Dynamic theme loading · hot-reload · palette injection · event system        ║
-- ║   ASH CLI integration · persist state · performance-optimised startup          ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔒 PRIVATE STATE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local _state = {
  -- Currently active theme name
  current       = nil,

  -- Currently active palette (resolved colours)
  palette       = {},

  -- Whether a theme change is in progress
  changing      = false,

  -- Listeners registered for theme-change events
  listeners     = {},

  -- Theme change history (for undo)
  history       = {},
  history_max   = 10,

  -- Startup timestamp for perf tracking
  loaded_at     = os.time(),

  -- Statistics
  stats = {
    changes     = 0,
    last_change = nil,
    total_time  = 0,
  },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗂️  KNOWN THEMES — built-in catalogue
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local BUILTIN_THEMES = {
  -- ── Dark ────────────────────────────────────────────────────────────────
  "catppuccin-mocha",
  "catppuccin-macchiato",
  "catppuccin-frappe",
  "tokyonight",
  "tokyonight-storm",
  "tokyonight-night",
  "tokyonight-moon",
  "gruvbox",
  "gruvbox-dark",
  "gruvbox-material",
  "nord",
  "dracula",
  "onedark",
  "everforest",
  "kanagawa",
  "rose-pine",
  "rose-pine-moon",
  "oxocarbon",
  "nightfox",
  "carbonfox",
  "material",
  "ayu-dark",

  -- ── Light ────────────────────────────────────────────────────────────────
  "catppuccin-latte",
  "gruvbox-light",
  "rose-pine-dawn",
  "everforest-light",
  "dayfox",
  "dawnfox",
  "ayu-light",

  -- ── ASH dynamic ──────────────────────────────────────────────────────────
  "ash-dynamic",
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 INTERNAL HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Notify with consistent title
local function notify(msg, level, opts)
  vim.notify(
    msg,
    level or vim.log.levels.INFO,
    vim.tbl_extend("force", { title = "🎨 ASH Theme" }, opts or {})
  )
end

-- Fire theme-change event for all registered listeners
local function fire_event(event_name, data)
  -- Neovim User autocmd
  vim.api.nvim_exec_autocmds("User", {
    pattern = event_name,
    data    = data,
    modeline= false,
  })

  -- Internal listeners
  for _, listener in ipairs(_state.listeners) do
    if listener.event == event_name then
      local ok, err = pcall(listener.fn, data)
      if not ok and vim.g.ash_debug then
        notify("Listener error: " .. tostring(err), vim.log.levels.WARN)
      end
    end
  end
end

-- Save theme to persistent state file
local function persist_theme(name)
  local state_file = vim.fn.stdpath("data") .. "/ash_theme.txt"
  local f = io.open(state_file, "w")
  if f then
    f:write(name)
    f:close()
  end
end

-- Load theme name from persistent state
local function load_persisted_theme()
  local state_file = vim.fn.stdpath("data") .. "/ash_theme.txt"
  local f = io.open(state_file, "r")
  if f then
    local name = vim.fn.trim(f:read("*a"))
    f:close()
    return name ~= "" and name or nil
  end
  return nil
end

-- Push to history (for undo-theme)
local function push_history(name)
  table.insert(_state.history, name)
  if #_state.history > _state.history_max then
    table.remove(_state.history, 1)
  end
end

-- Map theme name → colorscheme name for vim.cmd.colorscheme
local THEME_MAP = {
  ["catppuccin-mocha"]     = "catppuccin-mocha",
  ["catppuccin-macchiato"] = "catppuccin-macchiato",
  ["catppuccin-frappe"]    = "catppuccin-frappe",
  ["catppuccin-latte"]     = "catppuccin-latte",
  ["tokyonight"]           = "tokyonight-night",
  ["tokyonight-storm"]     = "tokyonight-storm",
  ["tokyonight-night"]     = "tokyonight-night",
  ["tokyonight-moon"]      = "tokyonight-moon",
  ["gruvbox"]              = "gruvbox",
  ["gruvbox-dark"]         = "gruvbox",
  ["gruvbox-light"]        = "gruvbox",
  ["gruvbox-material"]     = "gruvbox-material",
  ["nord"]                 = "nord",
  ["dracula"]              = "dracula",
  ["onedark"]              = "onedark",
  ["everforest"]           = "everforest",
  ["everforest-light"]     = "everforest",
  ["kanagawa"]             = "kanagawa",
  ["rose-pine"]            = "rose-pine",
  ["rose-pine-moon"]       = "rose-pine-moon",
  ["rose-pine-dawn"]       = "rose-pine-dawn",
  ["oxocarbon"]            = "oxocarbon",
  ["nightfox"]             = "nightfox",
  ["carbonfox"]            = "carbonfox",
  ["dayfox"]               = "dayfox",
  ["dawnfox"]              = "dawnfox",
  ["material"]             = "material",
  ["ayu-dark"]             = "ayu-dark",
  ["ayu-light"]            = "ayu-light",
  ["ash-dynamic"]          = "ash-dynamic",
}

-- Apply pre-load setup for specific themes
local function pre_apply(name)
  -- Gruvbox: set background before loading
  if name:find("gruvbox") then
    if name:find("light") then
      vim.opt.background = "light"
    else
      vim.opt.background = "dark"
    end
  end

  -- Everforest: set background
  if name:find("everforest") then
    vim.opt.background = name:find("light") and "light" or "dark"
    vim.g.everforest_background = "hard"
  end

  -- TokyoNight: set style
  if name:find("tokyonight") then
    local style = name:match("tokyonight%-(.+)") or "night"
    vim.g.tokyonight_style = style
  end

  -- Material: set style
  if name:find("material") then
    vim.g.material_style = "oceanic"
  end
end

-- Apply post-load fixups for specific themes
local function post_apply(name)
  -- Force re-apply of terminal colours
  if vim.fn.has("termguicolors") == 1 then
    vim.opt.termguicolors = true
  end

  -- Ensure our custom highlights layer on top
  local ok_hl = pcall(require, "themes.highlights")
  if ok_hl then
    require("themes.highlights").apply()
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🌐 PUBLIC API
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---Get the name of the currently active theme
---@return string|nil
function M.current()
  return _state.current
end

---Get the active palette table
---@return table
function M.palette()
  return _state.palette
end

---Get full engine state (for debugging)
---@return table
function M.state()
  return vim.deepcopy(_state)
end

---Check whether a theme name is known/valid
---@param name string
---@return boolean
function M.is_valid(name)
  if not name or name == "" then return false end
  return THEME_MAP[name] ~= nil or vim.tbl_contains(BUILTIN_THEMES, name)
end

---List all available themes
---@return string[]
function M.list()
  return vim.deepcopy(BUILTIN_THEMES)
end

---Apply a theme by name
---@param name string   Theme name (see BUILTIN_THEMES)
---@param opts? table   { silent=bool, force=bool, notify=bool }
---@return boolean      true on success
function M.apply(name, opts)
  opts = vim.tbl_extend("force", {
    silent = false,
    force  = false,
    notify = true,
  }, opts or {})

  -- Guard against re-entry
  if _state.changing then
    notify("Theme change already in progress", vim.log.levels.WARN)
    return false
  end

  -- Validate
  if not M.is_valid(name) then
    notify("Unknown theme: " .. tostring(name), vim.log.levels.WARN)
    return false
  end

  -- Skip if same theme (unless forced)
  if not opts.force and _state.current == name then
    return true
  end

  _state.changing = true
  local t_start   = vim.uv.hrtime()

  -- Push to history
  if _state.current then
    push_history(_state.current)
  end

  -- Fire pre-change event
  fire_event("AshThemePreChange", { from = _state.current, to = name })

  -- Pre-apply setup
  pre_apply(name)

  -- Apply the colorscheme
  local cs_name = THEME_MAP[name] or name
  local ok, err = pcall(vim.cmd.colorscheme, cs_name)

  if not ok then
    _state.changing = false
    notify(
      string.format("Failed to apply '%s' (cs: %s):\n%s", name, cs_name, tostring(err)),
      vim.log.levels.ERROR
    )
    return false
  end

  -- Post-apply fixups
  post_apply(name)

  -- Update state
  local prev          = _state.current
  _state.current      = name
  _state.changing     = false

  -- Load palette from themes.palette module
  local ok_pal, pal = pcall(require, "themes.palette")
  if ok_pal then
    _state.palette = pal.get(name) or {}
  end

  -- Performance tracking
  local elapsed = (vim.uv.hrtime() - t_start) / 1e6  -- ms
  _state.stats.changes     = _state.stats.changes + 1
  _state.stats.last_change = name
  _state.stats.total_time  = _state.stats.total_time + elapsed

  -- Persist
  persist_theme(name)

  -- Fire post-change event
  fire_event("AshThemeChanged", {
    from    = prev,
    to      = name,
    palette = _state.palette,
    elapsed = elapsed,
  })

  -- Notify user
  if opts.notify and not opts.silent then
    notify(
      string.format("🎨 %s  (%.0fms)", name, elapsed),
      vim.log.levels.INFO,
      { timeout = 1500 }
    )
  end

  if vim.g.ash_debug then
    notify(
      string.format("Theme applied: %s → %s (%.1fms)", prev or "none", name, elapsed),
      vim.log.levels.DEBUG
    )
  end

  return true
end

---Revert to the previous theme
---@return boolean
function M.undo()
  if #_state.history == 0 then
    notify("No previous theme in history", vim.log.levels.WARN)
    return false
  end

  local prev = table.remove(_state.history)
  return M.apply(prev, { notify = true })
end

---Cycle through all themes (next)
---@return boolean
function M.next()
  local themes = M.list()
  local idx     = 1
  if _state.current then
    for i, t in ipairs(themes) do
      if t == _state.current then
        idx = i + 1
        break
      end
    end
  end
  if idx > #themes then idx = 1 end
  return M.apply(themes[idx])
end

---Cycle through all themes (previous)
---@return boolean
function M.prev()
  local themes = M.list()
  local idx     = #themes
  if _state.current then
    for i, t in ipairs(themes) do
      if t == _state.current then
        idx = i - 1
        break
      end
    end
  end
  if idx < 1 then idx = #themes end
  return M.apply(themes[idx])
end

---Apply a random theme
---@return boolean
function M.random()
  local themes = M.list()
  math.randomseed(os.time())
  local idx = math.random(1, #themes)
  return M.apply(themes[idx])
end

---Register a listener for theme events
---@param event string   "AshThemeChanged" | "AshThemePreChange"
---@param fn    function Callback(data)
---@return function      Unregister function
function M.on(event, fn)
  local id = #_state.listeners + 1
  _state.listeners[id] = { event = event, fn = fn }
  return function()
    _state.listeners[id] = nil
  end
end

---Sync theme with ASH CLI (reads active theme from ash CLI)
---@return boolean
function M.sync_from_ash()
  if vim.fn.executable("ash") ~= 1 then
    if vim.g.ash_debug then
      notify("ash CLI not found", vim.log.levels.DEBUG)
    end
    return false
  end

  local result = vim.fn.trim(
    vim.fn.system("ash theme list --current --format=name 2>/dev/null")
  )

  if vim.v.shell_error ~= 0 or result == "" then
    return false
  end

  if result ~= _state.current then
    return M.apply(result, { silent = true, notify = false })
  end

  return true
end

---Show engine statistics
function M.stats()
  local uptime = os.time() - _state.loaded_at

  vim.notify(
    table.concat({
      "🎨 ASH Theme Engine Stats",
      "──────────────────────────────────",
      string.format("  Current:    %s", _state.current or "none"),
      string.format("  Changes:    %d", _state.stats.changes),
      string.format("  Avg time:   %.1fms",
        _state.stats.changes > 0
          and _state.stats.total_time / _state.stats.changes
          or 0),
      string.format("  History:    %d entries", #_state.history),
      string.format("  Listeners:  %d", vim.tbl_count(_state.listeners)),
      string.format("  Uptime:     %dmin", math.floor(uptime / 60)),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "🎨 ASH Theme Engine" }
  )
end

---Setup the theme engine (called once at startup)
---@param opts? table { theme=string, restore=bool, watch_ash=bool }
function M.setup(opts)
  opts = vim.tbl_extend("force", {
    theme      = nil,       -- explicit theme to apply
    restore    = true,      -- restore last theme on startup
    watch_ash  = true,      -- watch for ASH CLI theme changes
  }, opts or {})

  -- Ensure termguicolors
  vim.opt.termguicolors = true

  -- Determine theme to apply
  local theme_to_apply = opts.theme

  if not theme_to_apply and opts.restore then
    theme_to_apply = load_persisted_theme()
  end

  if not theme_to_apply then
    -- Try to sync from ASH CLI
    local ash_theme = vim.fn.trim(
      vim.fn.system("ash theme list --current --format=name 2>/dev/null")
    )
    if vim.v.shell_error == 0 and ash_theme ~= "" then
      theme_to_apply = ash_theme
    end
  end

  -- Final fallback
  theme_to_apply = theme_to_apply or "catppuccin-mocha"

  -- Apply on VimEnter (deferred so plugins are loaded)
  vim.api.nvim_create_autocmd("VimEnter", {
    once     = true,
    callback = function()
      M.apply(theme_to_apply, { silent = true, notify = false })

      -- Setup ASH CLI watcher
      if opts.watch_ash and vim.fn.executable("ash") == 1 then
        local aug = vim.api.nvim_create_augroup("AshThemeEngineWatch", { clear = true })

        -- Re-sync on FocusGained (when returning from external ASH theme change)
        vim.api.nvim_create_autocmd("FocusGained", {
          group    = aug,
          callback = function()
            -- Non-blocking sync
            vim.defer_fn(M.sync_from_ash, 100)
          end,
        })

        -- Listen for the User event fired by ASH CLI integration
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshCliThemeApplied",
          callback = function(ev)
            local name = ev.data and ev.data.theme
            if name and name ~= _state.current then
              M.apply(name, { silent = true, notify = true })
            end
          end,
        })
      end
    end,
  })

  -- User commands
  vim.api.nvim_create_user_command("AshTheme", function(args)
    local sub = args.args ~= "" and args.args or nil
    if sub then
      M.apply(sub)
    else
      M.stats()
    end
  end, {
    nargs    = "?",
    complete = function()
      return M.list()
    end,
    desc = "🎨 ASH: Apply theme or show stats",
  })

  vim.api.nvim_create_user_command("AshThemeNext",   M.next,   { desc = "🎨 ASH: Next theme"     })
  vim.api.nvim_create_user_command("AshThemePrev",   M.prev,   { desc = "🎨 ASH: Prev theme"     })
  vim.api.nvim_create_user_command("AshThemeRandom", M.random, { desc = "🎨 ASH: Random theme"   })
  vim.api.nvim_create_user_command("AshThemeUndo",   M.undo,   { desc = "🎨 ASH: Undo theme"     })
  vim.api.nvim_create_user_command("AshThemeSync",   M.sync_from_ash, { desc = "🎨 ASH: Sync from CLI" })
  vim.api.nvim_create_user_command("AshThemeStats",  M.stats,  { desc = "🎨 ASH: Engine stats"   })

  -- Keymaps
  local function kmap(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = "🎨 " .. desc, silent = true })
  end

  kmap("<leader>at",  "<cmd>AshTheme<cr>",        "Theme: Stats"     )
  kmap("<leader>atn", "<cmd>AshThemeNext<cr>",     "Theme: Next"      )
  kmap("<leader>atp", "<cmd>AshThemePrev<cr>",     "Theme: Prev"      )
  kmap("<leader>atr", "<cmd>AshThemeRandom<cr>",   "Theme: Random"    )
  kmap("<leader>atu", "<cmd>AshThemeUndo<cr>",     "Theme: Undo"      )
  kmap("<leader>ats", "<cmd>AshThemeSync<cr>",     "Theme: Sync"      )
  kmap("<leader>atP", function()
    -- Pick theme via telescope or ui.select
    local ok_tele, tele = pcall(require, "telescope.builtin")
    if ok_tele then
      tele.colorscheme({
        prompt_title     = "🎨 ASH Themes",
        enable_preview   = true,
      })
    else
      vim.ui.select(M.list(), { prompt = "🎨 ASH Theme: " }, function(name)
        if name then M.apply(name) end
      end)
    end
  end, "Theme: Pick")

  -- Expose globally
  vim.g.ash_theme  = _G.AshTheme or {}
  _G.AshTheme      = M
end

return M