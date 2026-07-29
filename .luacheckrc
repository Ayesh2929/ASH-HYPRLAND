-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  ASH DOTFILES v5.0 OMEGA — Luacheck Configuration              ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- Lua version
std = "luajit"

-- Maximum line length
max_line_length = 120
max_string_line_length = 180
max_comment_line_length = 180

-- Report format
codes = true
ranges = true
max_cyclomatic_complexity = 150  -- Increase complexity threshold

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
  "Ash",
  "STATE",
  "ElixirLS",
  "Snacks",
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
      "Ash",
      "STATE",
      "ElixirLS",
      "Snacks",
      "describe",
      "it",
      "before_each",
      "after_each",
      "assert",
    },
    std = "luajit",
    max_line_length = 120,
  },

  -- Kitty kittens
  ["config/kitty/kittens/**/*.lua"] = {
    std = "luajit",
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
    std = "luajit",
  },

  -- Plugin files (can define more globals)
  ["config/nvim/lua/plugins/**/*.lua"] = {
    globals = { "vim", "spec", "Ash", "STATE", "ElixirLS", "Snacks" },
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
  "611",  -- W611: line contains only whitespace
  "211",  -- W211: Unused variable
  "212",  -- W212: Unused argument
  "561",  -- W561: cyclomatic complexity of function is too high
  "631",  -- W631: line is too long
  "542",  -- W542: empty if branch
  "582",  -- W582: negation executed before relational operator
  "314",  -- W314: value assigned to field is overwritten before use
  "311",  -- W311: value assigned to variable is unused
  "111",  -- W111: setting non-standard global variable
  "112",  -- W112: mutating non-standard global variable
  "431",  -- W431: shadowing upvalue
  "214",  -- W214: used variable with unused hint
}
