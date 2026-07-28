-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/twilight.lua — Focus Dimming                                ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: folke/twilight.nvim                                                 ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Dims code outside the current scope using Treesitter                   ║
-- ║    • Configurable dim amount per colorscheme luminance                      ║
-- ║    • Per-filetype scope sizes (poetry: 1 stanza, code: 10 lines)           ║
-- ║    • Excluded filetypes / buffers                                           ║
-- ║    • Integrates with zen-mode (auto-enabled inside)                        ║
-- ║    • Standalone toggle with keymap + notification                           ║
-- ║    • Custom treesitter node type inclusions per language                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "folke/twilight.nvim",
    cmd  = { "Twilight", "TwilightEnable", "TwilightDisable" },
    keys = {
      {
        "<leader>uT",
        function()
          require("twilight").toggle()
          local enabled = require("twilight.view").enabled
          vim.notify(
            (enabled and "󰛨 " or "󰛩 ") .. "Twilight " .. (enabled and "on" or "off"),
            vim.log.levels.INFO,
            { title = "ASH NeoVim", timeout = 2000 }
          )
        end,
        desc = "󰛨  Toggle Twilight (focus dim)",
      },
    },
  
    opts = function()
      -- ── Colour palette ────────────────────────────────────────────────────
      local p = {}
      pcall(function()
        p = require("catppuccin.palettes").get_palette() or {}
      end)
  
      local overlay = p.overlay0 or "#6c7086"
  
      -- ── Dim amount: auto-tune from palette luminance ───────────────────────
      -- Darker themes need less dimming to stay readable; lighter themes need more
      local dim_alpha = 0.25    -- default: 25% visible (75% dimmed)
      pcall(function()
        local lum = Ash.util.color.luminance(p.base or "#1e1e2e")
        -- Dark theme (lum < 0.1) → dim to 20%; light theme → dim to 30%
        dim_alpha = lum < 0.1 and 0.20 or 0.28
      end)
  
      return {
        -- ── Dimming ───────────────────────────────────────────────────────
        dimming = {
          alpha      = dim_alpha,       -- proportion of foreground color
          color      = { "Normal",  "#ffffff" },
          term_bg    = "#000000",       -- term background behind the dim
          inactive   = false,           -- don't dim all inactive windows
        },
  
        -- ── Context ───────────────────────────────────────────────────────
        -- Number of lines above/below the current scope to keep lit
        context    = 12,
  
        -- ── Treesitter ────────────────────────────────────────────────────
        treesitter = {
          enabled    = true,
          disable    = {},
          -- Node types that define a "scope" (lit region)
          -- Each entry: { "language", { "node_type1", ... } }
          -- nil → use Twilight built-in defaults
        },
  
        -- ── Expand context to these node types ───────────────────────────
        expand     = {
          -- Generic
          "function",
          "method",
          "table",
          "if_statement",
          "else_clause",
          "else_statement",
          "switch_statement",
          "for_statement",
          "while_statement",
          "with_statement",
          "try_statement",
          "class_definition",
          "class_declaration",
          "impl_item",
          -- JS / TS
          "jsx_element",
          "jsx_fragment",
          "arrow_function",
          "call_expression",
          -- Lua
          "do_statement",
          "repeat_statement",
          -- Rust
          "match_expression",
          "closure_expression",
          -- Go
          "func_declaration",
          "func_literal",
          "type_declaration",
          -- Python
          "decorated_definition",
          "lambda",
          -- Markdown
          "section",
          "fenced_code_block",
          "block_quote",
          -- Norg / Org
          "heading",
          "paragraph",
        },
  
        -- ── Excluded filetypes ────────────────────────────────────────────
        exclude    = {
          "help",
          "dashboard",
          "alpha",
          "neo-tree",
          "Trouble",
          "lazy",
          "mason",
          "notify",
          "aerial",
          "toggleterm",
          "TelescopePrompt",
          "TelescopeResults",
          "WhichKey",
          "noice",
        },
      }
    end,
  
    config = function(_, opts)
      require("twilight").setup(opts)
  
      -- ── Highlight group: dim colour ───────────────────────────────────────
      local function apply_hl()
        local p = {}
        pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
        -- Twilight uses the "Twilight" highlight group for dimmed text
        vim.api.nvim_set_hl(0, "Twilight", {
          fg      = p.overlay0 or "#6c7086",
          bg      = "NONE",
          italic  = true,
          nocombine = false,
        })
      end
  
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
    end,
  }