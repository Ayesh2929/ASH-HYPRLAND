-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  ASH DOTFILES v5.0 OMEGA — Luacheck Configuration              ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- Lua version
std = "lua54"

-- Maximum line length
max_line_length = 120
max_string_line_length = 180
max_comment_line_length = 180

-- Report format
codes = true
ranges = true
max_cyclomatic_complexity = 15

-- Global whitelists
globals = {
  -- Neovim core
  "vim",
  "jit",
  "bit",

  -- Lazy.nvim plugin spec
  "spec",

  -- Testing (if using plenary.nvim)
  "describe",
  "it",
  "before_each",
  "after_each",
  "assert",
  "mock",
  "stub",
  "spy",

  -- ASH integration globals
  "ASH_VERSION",
  "ASH_THEME",
  "ASH_MODE",
  "ASH_CONFIG_DIR",
  "ASH_DATA_DIR",
}

-- Read-only globals (can read but not write)
read_globals = {
  -- Neovim API (auto-discovered)
  "vim",
}

-- Per-file/directory overrides
files = {
  -- Neovim configuration
  ["config/nvim/**/*.lua"] = {
    globals = {
      "vim",
      "describe",
      "it",
      "before_each",
      "after_each",
      "assert",
    },
    std = "lua54",
    max_line_length = 120,
  },

  -- Kitty kittens (older Lua API)
  ["config/kitty/kittens/**/*.lua"] = {
    std = "lua54",
    globals = { "kitty" },
  },

  -- Test files
  ["tests/**/*.lua"] = {
    globals = {
      "vim",
      "describe",
      "it",
      "before_each",
      "after_each",
      "assert",
      "mock",
      "stub",
    },
    std = "lua54",
  },

  -- Plugin files (can define more globals)
  ["config/nvim/lua/plugins/**/*.lua"] = {
    globals = { "vim", "spec" },
    -- Plugins often use lazy patterns
    ignore = { "631" },  -- W631: line is too long (plugin specs)
  },
}

-- Patterns to exclude
exclude_files = {
  ".git",
  "node_modules",
  "vendor",
  "*.min.lua",
}

-- Ignore specific codes with justification
ignore = {
  -- "211",  -- Unused variable: too many false positives in Neovim config
  -- "212",  -- Unused argument: _ convention not always followed
}
