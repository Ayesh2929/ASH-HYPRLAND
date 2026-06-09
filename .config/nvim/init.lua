-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — NEOVIM CONFIGURATION                         ║
-- ║           Complete IDE setup with LSP, DAP, AI, and custom theme           ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝
--
-- Architecture:
--   init.lua          → Entry point (this file)
--   lua/core/         → Options, keymaps, autocmds, lazy bootstrap
--   lua/plugins/      → Plugin specifications (lazy.nvim)
--   lua/lsp/          → LSP server configurations
--   lua/themes/       → Dynamic theme (reads ASH colors)
--   lua/ui/           → Custom statusline, winbar
--   lua/utils/        → Shared utilities
--   after/plugin/     → Post-plugin-load configuration

-- ═══════════════════════════════════════════════════════════════════════════════
-- ⚡ PERFORMANCE GUARD
-- ═══════════════════════════════════════════════════════════════════════════════

-- Disable unnecessary built-in plugins (speeds up startup)
local disabled_built_ins = {
    "gzip", "zip", "zipPlugin", "tar", "tarPlugin",
    "getscript", "getscriptPlugin", "vimball", "vimballPlugin",
    "2html_plugin", "logipat", "rrhelper", "spellfile_plugin",
    "matchit", "matchparen", "tutor",
}

for _, plugin in ipairs(disabled_built_ins) do
    vim.g["loaded_" .. plugin] = 1
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 EARLY GLOBAL SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Set leader keys BEFORE loading plugins
vim.g.mapleader      = " "        -- Space as leader
vim.g.maplocalleader = "\\"       -- Backslash as local leader

-- Neovim providers (disable unused for speed)
vim.g.loaded_perl_provider   = 0
vim.g.loaded_ruby_provider   = 0
vim.g.loaded_node_provider   = 0  -- Enable if using node-based plugins
vim.g.python3_host_prog      = vim.fn.exepath("python3")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📁 PATH SETUP
-- ═══════════════════════════════════════════════════════════════════════════════

-- Add ~/.local/bin to vim path
vim.env.PATH = vim.env.HOME .. "/.local/bin:" .. vim.env.PATH

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🚀 LOAD CORE MODULES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Load in order: options first, then keymaps, then autocmds, then plugins
require("core.options")   -- vim.opt settings
require("core.keymaps")   -- Global keymaps
require("core.autocmds")  -- Autocommands
require("core.lazy")      -- Plugin manager bootstrap + plugins

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎨 THEME (loaded after plugins)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Apply ASH dynamic theme
vim.defer_fn(function()
    local ok, theme = pcall(require, "themes.ash")
    if ok then
        theme.apply()
    end
end, 50)