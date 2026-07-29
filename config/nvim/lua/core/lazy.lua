-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/core/lazy.lua — Lazy.nvim Spec Helpers & Configuration                 ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  This module provides:                                                       ║
-- ║    • Spec builder helpers  (M.plugin, M.keys, M.on_ft, M.on_event …)        ║
-- ║    • Lazy.nvim setup() options (canonical source of truth)                  ║
-- ║    • Lazy.nvim startup profiling utilities                                  ║
-- ║    • :AshPlugins / :AshUpdate user commands                                 ║
-- ║                                                                              ║
-- ║  NOTE: require("lazy").setup() is called from init.lua, NOT here.           ║
-- ║        This module only EXPORTS the options table and helpers.               ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@class AshLazy
local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 01  LAZY.NVIM SETUP OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- This table is consumed by `require("lazy").setup(specs, M.opts)` in init.lua.

---@type LazyConfig
M.opts = {
  root    = vim.fn.stdpath("data") .. "/lazy",
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",

  -- ── Defaults ──────────────────────────────────────────────────────────────
  defaults = {
    lazy    = true,   -- all plugins lazy by default
    version = false,  -- track `main` / `master` — lockfile pins commits
    cond    = nil,    -- no global condition
  },

  -- ── Auto-install ──────────────────────────────────────────────────────────
  install = {
    missing     = true,
    colorscheme = { Ash.colorscheme, "habamax" },
  },

  -- ── Update checker ────────────────────────────────────────────────────────
  checker = {
    enabled   = true,
    notify    = false, -- we handle notification ourselves below
    frequency = 43200, -- check every 12 h
    threshold = 2,     -- notify only when ≥ 2 plugins have updates
  },

  -- ── Change detection ──────────────────────────────────────────────────────
  change_detection = {
    enabled = true,
    notify  = false,  -- silence; we show our own notification
  },

  -- ── Git ───────────────────────────────────────────────────────────────────
  git = {
    log       = { "--since=3 days ago" },
    timeout   = 120,
    url_format = "https://github.com/%s.git",
    filter    = true,
  },

  -- ── Dev plugin paths ──────────────────────────────────────────────────────
  -- Point to local plugin dev dirs when present
  dev = {
    path     = vim.fn.expand("~/projects/nvim-plugins"),
    patterns = { "ash-dotfiles" },
    fallback = true,
  },

  -- ── Performance ───────────────────────────────────────────────────────────
  performance = {
    cache         = { enabled = true },
    reset_packpath = true,
    rtp = {
      reset = true,
      disabled_plugins = {
        "gzip", "matchit", "matchparen",
        "netrwPlugin", "tarPlugin",
        "tohtml", "tutor", "zipPlugin",
      },
    },
  },

  -- ── UI ────────────────────────────────────────────────────────────────────
  ui = {
    size        = { width = 0.88, height = 0.82 },
    wrap        = false,
    border      = "rounded",
    backdrop    = 60,
    title       = " 󰒲  ASH NeoVim — Plugin Manager ",
    title_pos   = "center",
    pills       = true,
    throttle    = 20,
    icons = {
      cmd        = Ash.icons.ui.Code,
      config     = Ash.icons.ui.Gear,
      event      = Ash.icons.ui.Watch,
      ft         = Ash.icons.ui.File,
      init       = Ash.icons.ui.Fire,
      import     = Ash.icons.ui.Package,
      keys       = Ash.icons.ui.Tab,
      lazy       = "󰒲 ",
      loaded     = "● ",
      not_loaded = "○ ",
      plugin     = Ash.icons.ui.Package,
      runtime    = Ash.icons.ui.Stacks,
      require    = Ash.icons.ui.Package,
      source     = Ash.icons.ui.Code,
      start      = Ash.icons.ui.Fire,
      task       = Ash.icons.ui.Check,
      list       = { "●", "➜", "★", "‒" },
    },
    browser    = "xdg-open",
    custom_keys = {
      -- Open plugin GitHub page with <gh>
      ["<localleader>g"] = {
        function(plugin)
          vim.fn.jobstart({ "xdg-open", plugin.url }, { detach = true })
        end,
        desc = "  Open GitHub repo",
      },
      -- Copy plugin name to clipboard
      ["<localleader>y"] = {
        function(plugin)
          vim.fn.setreg("+", plugin.name)
          vim.notify(" Copied: " .. plugin.name, vim.log.levels.INFO)
        end,
        desc = "  Copy plugin name",
      },
    },
  },

  -- ── Debug ─────────────────────────────────────────────────────────────────
  debug = vim.env.ASH_LAZY_DEBUG == "1",
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 02  SPEC BUILDER HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Usage from plugin spec files:
--   local lazy = require("core.lazy")
--   return {
--     "author/plugin",
--     keys = lazy.keys({ "<leader>xx", cmd = "Telescope" }),
--   }

---Build a lazy `keys` entry with sane defaults
---@param lhs     string    Left-hand side key sequence
---@param rhs     string|function  Right-hand side
---@param mode    string|string[]  Vim mode(s)
---@param desc    string?   Description shown in which-key
---@return table
function M.key(lhs, rhs, mode, desc)
  return {
    lhs,
    rhs,
    mode = mode or "n",
    silent = true,
    noremap = true,
    desc = desc,
  }
end

---Build a lazy `event` trigger — convenience for common events
---@param events string|string[]
---@return string|string[]
function M.on_event(events)
  return events
end

---Lazy trigger: load on specific filetypes
---@param fts string|string[]
---@return string|string[]
function M.on_ft(fts)
  return fts
end

---Lazy trigger: load on command
---@param cmds string|string[]
---@return string|string[]
function M.on_cmd(cmds)
  return cmds
end

---Return true when a given executable is available (used in `cond =`)
---@param exe string
---@return fun(): boolean
function M.has_exe(exe)
  return function()
    return vim.fn.executable(exe) == 1
  end
end

---Return true when a given module can be required (used in `cond =`)
---@param mod string
---@return fun(): boolean
function M.has_mod(mod)
  return function()
    return pcall(require, mod) ~= false
  end
end

---Wrap an `opts` table in a function that deep-merges user overrides
---@param defaults  table
---@param overrides table?
---@return table
function M.merge_opts(defaults, overrides)
  return vim.tbl_deep_extend("force", defaults, overrides or {})
end

---Produce a `build` string that runs a shell command only on UNIX
---@param shell_cmd string
---@return string?
function M.unix_build(shell_cmd)
  if vim.fn.has("win32") == 1 then return nil end
  return shell_cmd
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 03  UPDATE NOTIFICATION (hooked into checker)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---Called by the lazy.nvim checker when updates are available.
---Register this via the `checker.notify = false` + manual hook pattern.
function M.notify_updates()
  local ok, lazy = pcall(require, "lazy")
  if not ok then return end

  local status = lazy.stats()
  if status.updates and status.updates > 0 then
    vim.notify(
      string.format(
        "󰒲  %d plugin update%s available\n  Run :Lazy update to apply.",
        status.updates,
        status.updates == 1 and "" or "s"
      ),
      vim.log.levels.INFO,
      {
        title   = "ASH NeoVim — Plugin Updates",
        timeout = 6000,
      }
    )
  end
end

-- Wire up the notification after lazy is ready
vim.api.nvim_create_autocmd("User", {
  pattern  = "LazyCheck",
  once     = false,
  callback = M.notify_updates,
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 04  STARTUP STATS DISPLAY
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---Display a startup summary in the cmdline after VimEnter.
---Enabled via ASH_NVIM_PROFILE=1 env var.
function M.startup_stats()
  local ok, lazy = pcall(require, "lazy")
  if not ok then return end

  local stats   = lazy.stats()
  local startup = stats.startuptime

  local lines = {
    "",
    "  ╭──────────────────────────────────────────────╮",
    "  │     ⚡  ASH NeoVim — Startup Report           │",
    "  ├──────────────────────────────────────────────┤",
    string.format("  │  ⏱   Startup time    %8.1f ms              │", startup),
    string.format("  │  󰒲   Plugins loaded  %8d / %-6d        │",
      stats.loaded, stats.count),
    string.format("  │  󰩬   Lazy-loaded     %8d                  │",
      stats.count - stats.loaded),
    "  ╰──────────────────────────────────────────────╯",
    "",
  }

  vim.notify(
    table.concat(lines, "\n"),
    startup < 100 and vim.log.levels.INFO or vim.log.levels.WARN,
    {
      title   = "ASH NeoVim — Performance",
      timeout = 6000,
    }
  )
end

-- Hook into VimEnter if profiling is requested
if vim.env.ASH_NVIM_PROFILE == "1" then
  vim.api.nvim_create_autocmd("VimEnter", {
    once     = true,
    callback = function()
      vim.defer_fn(M.startup_stats, 100)
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 05  USER COMMANDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vim.api.nvim_create_user_command("AshPlugins", function()
  require("lazy").home()
end, { desc = "Open Lazy plugin manager" })

vim.api.nvim_create_user_command("AshUpdate", function()
  require("lazy").update()
end, { desc = "Update all plugins via Lazy" })

vim.api.nvim_create_user_command("AshSync", function()
  require("lazy").sync()
end, { desc = "Sync plugins (install + update + clean)" })

vim.api.nvim_create_user_command("AshClean", function()
  require("lazy").clean()
end, { desc = "Remove unused plugins" })

vim.api.nvim_create_user_command("AshProfile", function()
  M.startup_stats()
end, { desc = "Show startup performance stats" })

vim.api.nvim_create_user_command("AshCoreStatus", function()
  require("core").status()
end, { desc = "Show core module load status" })

return M