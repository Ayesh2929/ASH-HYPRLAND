-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                                                                              ║
-- ║   ░█████╗░░██████╗██╗░░██╗  ░█████╗░░█████╗░██████╗░███████╗               ║
-- ║   ██╔══██╗██╔════╝██║░░██║  ██╔══██╗██╔══██╗██╔══██╗██╔════╝               ║
-- ║   ███████║╚█████╗░███████║  ██║░░╚═╝██║░░██║██████╔╝█████╗░░               ║
-- ║   ██╔══██║░╚═══██╗██╔══██║  ██║░░██╗██║░░██║██╔══██╗██╔══╝░░               ║
-- ║   ██║░░██║██████╔╝██║░░██║  ╚█████╔╝╚█████╔╝██║░░██║███████╗               ║
-- ║   ╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝  ░╚════╝░░╚════╝░╚═╝░░╚═╝╚══════╝               ║
-- ║                                                                              ║
-- ║   lua/core/init.lua — Core Module Orchestrator                               ║
-- ║   ASH DOTFILES v5.0 OMEGA • Ultra IDE Core Bootstrap                        ║
-- ║                                                                              ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ARCHITECTURE OVERVIEW
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
--  core/init.lua          ← YOU ARE HERE (orchestrator)
--  ├── core/options.lua   ← vim.opt.* settings (pure, no side-effects)
--  ├── core/keymaps.lua   ← base keymaps (leader, navigation, QoL)
--  ├── core/autocmds.lua  ← autocommands (events, lifecycle)
--  └── core/lazy.lua      ← lazy.nvim spec helpers & loader
--
--  Load order contract:
--    options → autocmds → keymaps → lazy
--
--  Each module is isolated: importing one MUST NOT trigger side-effects
--  in another. All modules are safe to hot-reload independently.
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@class AshCore
---@field loaded   table<string, boolean>   Which sub-modules loaded cleanly
---@field errors   table<string, string>    Sub-modules that failed (mod → err)
---@field version  string                   Core module version
local M = {}

M.version = "5.0.0-omega"
M.loaded  = {}
M.errors  = {}

-- ── Internal helpers ─────────────────────────────────────────────────────────

---Safe module loader with structured error reporting
---@param mod string  Lua module path (e.g. "core.options")
---@param label string  Human-readable label for notifications
---@return boolean ok
local function load(mod, label)
  local ok, err = pcall(require, mod)
  if ok then
    M.loaded[mod] = true
    return true
  end

  M.errors[mod] = tostring(err)

  -- Defer notification so the UI is ready
  vim.schedule(function()
    vim.notify(
      string.format(
        "❌  ASH Core — [%s] failed to load\n\n%s\n\n"
          .. "  Run :AshDoctor for diagnostics.",
        label,
        tostring(err)
      ),
      vim.log.levels.ERROR,
      {
        title   = "ASH NeoVim — Core Error",
        timeout = 8000,
      }
    )
  end)

  return false
end

-- ── Public API ───────────────────────────────────────────────────────────────

---Returns true when ALL sub-modules loaded without errors
---@return boolean
function M.healthy()
  return vim.tbl_isempty(M.errors)
end

---Pretty-print load status (used by :AshDoctor)
function M.status()
  local lines = {
    "  ╭─────────────────────────────────────────╮",
    "  │   ASH Core — Module Load Status         │",
    "  ├─────────────────────────────────────────┤",
  }

  local all_mods = {
    "core.options",
    "core.autocmds",
    "core.keymaps",
    "core.lazy",
  }

  for _, mod in ipairs(all_mods) do
    local icon = M.loaded[mod] and "  ✅" or (M.errors[mod] and "  ❌" or "  ⏳")
    local short = mod:gsub("^core%.", "")
    table.insert(lines, string.format("  │  %s  %-32s│", icon, short))
  end

  table.insert(lines, "  ╰─────────────────────────────────────────╯")

  vim.notify(
    table.concat(lines, "\n"),
    M.healthy() and vim.log.levels.INFO or vim.log.levels.WARN,
    { title = "ASH Core Status" }
  )
end

-- ── Boot sequence ────────────────────────────────────────────────────────────
-- Order MATTERS: options first, autocmds may reference option values,
-- keymaps may use which-key groups defined in autocmds, lazy last.

load("core.options",  "Options")
load("core.autocmds", "Autocmds")
load("core.keymaps",  "Keymaps")
load("core.lazy",     "Lazy")

return M