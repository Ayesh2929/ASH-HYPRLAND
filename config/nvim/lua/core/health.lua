-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/core/health.lua — :checkhealth ash                                      ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Run with:  :checkhealth ash                                                 ║
-- ║             :AshDoctor      (user command alias)                             ║
-- ║                                                                              ║
-- ║  Checks:                                                                     ║
-- ║    ① Neovim version         ⑦ Wayland / display                             ║
-- ║    ② Core modules           ⑧ ASH dotfiles env                              ║
-- ║    ③ Critical executables   ⑨ LSP servers                                   ║
-- ║    ④ Optional executables   ⑩ Performance baseline                          ║
-- ║    ⑤ Nerd Font              ⑪ AI providers                                  ║
-- ║    ⑥ Clipboard              ⑫ Plugin health                                 ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

local health = vim.health

---@class AshHealth
local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Internal helpers
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ok    = function(msg) health.ok(msg)    end
local warn  = function(msg) health.warn(msg)  end
local error = function(msg) health.error(msg) end
local info  = function(msg) health.info(msg)  end
local start = function(msg) health.start(msg) end

---Check that executable `exe` is on PATH.
---@param exe   string
---@param label string?  Human-readable label
---@param req   boolean? If true, report as error; otherwise warn
local function check_exe(exe, label, req)
  label = label or exe
  if vim.fn.executable(exe) == 1 then
    ok(label .. " — found (" .. (vim.fn.exepath(exe) or exe) .. ")")
  elseif req then
    error(label .. " — NOT FOUND (required)\n  Install: " .. exe)
  else
    warn(label .. " — not found (optional feature degraded)")
  end
end

---Check a Lua module can be required.
---@param mod   string
---@param label string?
local function check_mod(mod, label)
  label = label or mod
  local ok_r, _ = pcall(require, mod)
  if ok_r then
    ok(label .. " — loaded")
  else
    warn(label .. " — not loaded (plugin missing or not installed?)")
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 01  NEOVIM VERSION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function check_version()
  start("① Neovim Version")
  local v = vim.version()
  local ver_str = string.format("%d.%d.%d", v.major, v.minor, v.patch)
  if vim.fn.has("nvim-0.10") == 1 then
    ok("Neovim " .. ver_str .. " ✓ (≥ 0.10 required)")
  else
    error(
      "Neovim " .. ver_str .. " — ASH requires ≥ 0.10\n"
        .. "  Upgrade: https://github.com/neovim/neovim/releases"
    )
  end
  if vim.fn.has("nvim-0.11") == 1 then
    ok("Neovim 0.11+ extras available (enhanced inlay-hints, etc.)")
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 02  CORE MODULE LOAD STATUS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function check_core()
  start("② ASH Core Modules")
  local core_ok, core = pcall(require, "core")
  if not core_ok then
    error("core/init.lua failed to load — config is broken")
    return
  end
  for mod, loaded in pairs(core.loaded) do
    if loaded then
      ok(mod .. " — ✓ loaded")
    end
  end
  for mod, err in pairs(core.errors) do
    error(mod .. " — FAILED\n  " .. err)
  end
  if vim.tbl_isempty(core.errors) then
    ok("All core modules healthy")
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 03  CRITICAL EXECUTABLES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function check_critical()
  start("③ Critical Executables")
  local critical = {
    { "git",     "git (version control)" },
    { "node",    "Node.js (LSP / Mason)" },
    { "npm",     "npm (Mason tool install)" },
    { "python3", "Python 3 (LSP / DAP)" },
    { "cargo",   "Cargo / Rust toolchain" },
    { "go",      "Go toolchain" },
    { "rg",      "ripgrep (telescope / search)" },
    { "fd",      "fd (telescope / file find)" },
    { "make",    "make (build some C extensions)" },
    { "unzip",   "unzip (Mason downloads)" },
    { "curl",    "curl (downloads)" },
    { "tar",     "tar (archive extraction)" },
  }
  for _, c in ipairs(critical) do
    check_exe(c[1], c[2], true)
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 04  OPTIONAL EXECUTABLES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function check_optional()
  start("④ Optional Executables")
  local optional = {
    { "lazygit",       "lazygit (git UI)" },
    { "bat",           "bat (syntax preview in telescope)" },
    { "eza",           "eza (better ls in file browser)" },
    { "delta",         "delta (better git diff)" },
    { "fzf",           "fzf (fuzzy finder fallback)" },
    { "gh",            "GitHub CLI" },
    { "docker",        "Docker" },
    { "kubectl",       "kubectl (kubernetes)" },
    { "terraform",     "terraform (infra-as-code)" },
    { "stylua",        "stylua (Lua formatter)" },
    { "shfmt",         "shfmt (shell formatter)" },
    { "prettier",      "prettier (web formatter)" },
    { "black",         "black (Python formatter)" },
    { "gofumpt",       "gofumpt (Go formatter)" },
    { "rustfmt",       "rustfmt (Rust formatter)" },
    { "eslint_d",      "eslint_d (fast JS linter)" },
    { "xdg-open",      "xdg-open (open files/URLs)" },
    { "wl-copy",       "wl-clipboard (Wayland clipboard)" },
    { "imagemagick",   "ImageMagick (image support)" },
    { "ffmpeg",        "ffmpeg (media processing)" },
  }
  for _, c in ipairs(optional) do
    check_exe(c[1], c[2], false)
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 05  NERD FONT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function check_nerd_font()
  start("⑤ Nerd Font")
  -- Sample a range of Nerd Font codepoints
  local samples = {
    { cp = "\u{E0A0}",  name = "Powerline Branch" },
    { cp = "\u{E0B0}",  name = "Powerline Right Arrow" },
    { cp = "\u{F015}",  name = "Home" },
    { cp = "\u{F07C}",  name = "Folder Open" },
    { cp = "\u{F1D3}",  name = "Git" },
    { cp = "\u{F00D}",  name = "Times" },
    { cp = "\u{E745}",  name = "Neovim" },
  }
  info(
    "Nerd Font glyph samples (they should look like icons, not boxes/?):\n  "
      .. table.concat(
        vim.tbl_map(function(s)
          return s.cp .. "=" .. s.name
        end, samples),
        "  "
      )
  )
  if vim.g.have_nerd_font then
    ok("g.have_nerd_font = true — icons enabled")
  else
    warn("g.have_nerd_font is not set — ASCII fallbacks will be used\n"
      .. "  Set vim.g.have_nerd_font = true in your init.lua")
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 06  CLIPBOARD
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function check_clipboard()
  start("⑥ Clipboard")
  if vim.env.WAYLAND_DISPLAY then
    if vim.fn.executable("wl-copy") == 1 then
      ok("Wayland + wl-copy detected — clipboard should work")
    else
      error(
        "WAYLAND_DISPLAY is set but wl-copy is not found\n"
          .. "  Install wl-clipboard: pacman -S wl-clipboard"
      )
    end
  elseif vim.env.DISPLAY then
    if vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1 then
      ok("X11 + xclip/xsel detected — clipboard should work")
    else
      warn("X11 detected but neither xclip nor xsel found\n"
        .. "  Install: pacman -S xclip")
    end
  elseif vim.fn.has("mac") == 1 then
    ok("macOS detected — pbcopy/pbpaste available natively")
  else
    warn("Could not detect clipboard provider\n"
      .. "  Set vim.g.clipboard manually if needed")
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 07  WAYLAND / DISPLAY SERVER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function check_wayland()
  start("⑦ Wayland / Display Server")
  if vim.env.WAYLAND_DISPLAY then
    ok("Wayland session: WAYLAND_DISPLAY=" .. vim.env.WAYLAND_DISPLAY)
    if vim.env.XDG_SESSION_TYPE == "wayland" then
      ok("XDG_SESSION_TYPE=wayland ✓")
    else
      warn("XDG_SESSION_TYPE is not 'wayland' — some tools may use XWayland")
    end
  elseif vim.env.DISPLAY then
    info("X11 session: DISPLAY=" .. vim.env.DISPLAY)
  else
    warn("Neither WAYLAND_DISPLAY nor DISPLAY is set — headless or SSH?")
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 08  ASH DOTFILES ENVIRONMENT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function check_ash_env()
  start("⑧ ASH Dotfiles Environment")
  local env_vars = {
    { "ASH_THEME",             "Active ASH theme" },
    { "ASH_NVIM_COLORSCHEME",  "NeoVim colorscheme override" },
    { "ASH_TRANSPARENT",       "Transparent background flag" },
    { "ASH_AI_PROVIDER",       "AI completion provider" },
    { "ASH_OLLAMA_MODEL",      "Local Ollama model" },
  }
  for _, e in ipairs(env_vars) do
    local val = vim.env[e[1]]
    if val then
      ok(e[1] .. " = " .. val)
    else
      info(e[1] .. " not set (using default) — " .. e[2])
    end
  end
  -- ASH global
  if Ash then
    ok("Ash global namespace — version " .. Ash.version)
    ok("Theme: " .. Ash.theme .. "  Colorscheme: " .. Ash.colorscheme)
  else
    error("Ash global is nil — core/init.lua may have failed")
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 09  LSP SERVERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function check_lsp()
  start("⑨ LSP Servers (active in current buffer)")
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    info("No LSP clients attached to current buffer\n"
      .. "  Open a source file to trigger LSP attachment")
  else
    for _, c in ipairs(clients) do
      ok(c.name
        .. "  root=" .. (c.root_dir or "none")
        .. "  id=" .. c.id)
    end
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 10  PERFORMANCE BASELINE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function check_performance()
  start("⑩ Performance Baseline")
  local ok_lazy, lazy = pcall(require, "lazy")
  if ok_lazy then
    local s = lazy.stats()
    local t = math.floor(s.startuptime * 10 + 0.5) / 10
    local msg = string.format(
      "Startup: %.1f ms  |  Loaded: %d / %d plugins  |  Lazy: %d",
      t, s.loaded, s.count, s.count - s.loaded
    )
    if t < 80 then
      ok("⚡ " .. msg .. " — EXCELLENT")
    elseif t < 150 then
      ok("✅ " .. msg .. " — GOOD")
    elseif t < 300 then
      warn("⚠️  " .. msg .. " — ACCEPTABLE (consider profiling)")
    else
      error("🐢 " .. msg .. " — TOO SLOW\n"
        .. "  Run :Lazy profile to identify slow plugins")
    end
  else
    info("lazy.nvim not loaded — cannot measure startup time")
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 11  AI PROVIDERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function check_ai()
  start("⑪ AI Providers")
  local provider = Ash and Ash.ai.provider or "none"
  info("Configured AI provider: " .. provider)
  if provider == "codeium" then
    check_mod("codeium", "codeium.nvim")
  elseif provider == "copilot" then
    check_mod("copilot", "copilot.lua")
    if vim.fn.executable("node") == 1 then
      ok("Node.js found — Copilot agent can run")
    else
      error("Node.js required for Copilot but not found")
    end
  elseif provider == "supermaven" then
    check_mod("supermaven-nvim", "supermaven-nvim")
  end
  -- Local Ollama
  if vim.fn.executable("ollama") == 1 then
    ok("ollama — found (local AI inference available)")
    local model = Ash and Ash.ai.ollama_model or "?"
    info("Configured model: " .. model)
  else
    info("ollama not found — local AI unavailable\n"
      .. "  Install: https://ollama.ai")
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 12  KEY PLUGIN HEALTH
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function check_plugins()
  start("⑫ Key Plugin Status")
  local plugins = {
    { "nvim-treesitter",   "Treesitter" },
    { "nvim-lspconfig",    "LSPConfig" },
    { "mason",             "Mason" },
    { "nvim-cmp",          "nvim-cmp (completion)" },
    { "telescope",         "Telescope" },
    { "neo-tree",          "Neo-tree" },
    { "gitsigns",          "Gitsigns" },
    { "which-key",         "Which-key" },
    { "noice",             "Noice (UI)" },
    { "conform",           "Conform (formatter)" },
    { "nvim-dap",          "DAP (debugger)" },
    { "neotest",           "Neotest (testing)" },
  }
  for _, p in ipairs(plugins) do
    check_mod(p[1], p[2])
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PUBLIC ENTRY POINT  (called by :checkhealth ash)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function M.check()
  check_version()
  check_core()
  check_critical()
  check_optional()
  check_nerd_font()
  check_clipboard()
  check_wayland()
  check_ash_env()
  check_lsp()
  check_performance()
  check_ai()
  check_plugins()
end

-- User command alias
vim.api.nvim_create_user_command("AshDoctor", function()
  vim.cmd("checkhealth ash")
end, { desc = "Run ASH NeoVim health checks (:checkhealth ash)" })

return M