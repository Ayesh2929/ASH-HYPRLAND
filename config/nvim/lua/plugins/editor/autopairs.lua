-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║      🔗 AUTOPAIRS — ULTRA SMART BRACKET ENGINE v5.0 OMEGA                      ║
-- ║   Treesitter-aware · multi-char pairs · cmp integration · per-filetype rules    ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 CONSTANTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local RULE   = nil  -- populated in config()
local COND   = nil  -- populated in config()

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📐 FILETYPES — exclusions & special handling
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Never pair in these buffers (user input / terminal / read-only)
local DISABLE_FILETYPES = {
  "TelescopePrompt",
  "spectre_panel",
  "snacks_picker_input",
  "DressingInput",
  "prompt",
  "fzf",
  "neo-tree",
  "Outline",
  "lazy",
  "mason",
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 CUSTOM RULE BUILDER — thin wrapper for readability
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Build a simple pair rule
---@param open string
---@param close string
---@param filetypes string|string[]|nil   nil = all filetypes
---@param conditions table|nil             list of COND predicates
local function pair(open, close, filetypes, conditions)
  local r = RULE(open, close, filetypes)
  if conditions then
    for _, c in ipairs(conditions) do
      r:with_pair(c)
    end
  end
  return r
end

--- Build a move-right-on-close rule (skip close char if already typed)
---@param close_char string
---@param filetypes  string|string[]|nil
local function move_past(close_char, filetypes)
  return RULE("", close_char, filetypes)
    :with_pair(COND.none())
    :with_move(function(opts2) return opts2.char == close_char end)
    :with_cr(COND.none())
    :with_del(COND.none())
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📜 RULE DEFINITIONS — applied after setup()
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function add_custom_rules(npairs)
  RULE = require("nvim-autopairs.rule")
  COND = require("nvim-autopairs.conds")
  local ts_conds = require("nvim-autopairs.ts-conds")

  -- ── Markdown: backtick code spans ─────────────────────────────────────────
  npairs.add_rules({
    -- Single backtick code span  `…`
    RULE("`", "`", "markdown")
      :with_pair(ts_conds.is_not_ts_node({ "code_span", "fenced_code_block" })),

    -- Triple backtick code block (only at line start)
    RULE("```", "```\n", "markdown")
      :with_pair(function(opts2) return opts2.line:match("^%s*$") ~= nil end)
      :set_end_pair_length(4),
  })

  -- ── Rust / C++: angle brackets for generics  <T> ──────────────────────────
  npairs.add_rules({
    RULE("<", ">", { "rust", "cpp", "c", "typescript", "typescriptreact" })
      :with_pair(COND.before_regex("[%a_]", -1))
      :with_pair(COND.not_before_regex("[%a_]"))
      :with_move(function(opts2) return opts2.char == ">" end)
      :with_del(COND.none()),

    -- Allow `|` pair in Rust closures  |x| { … }
    RULE("|", "|", "rust")
      :with_pair(COND.before_regex("[=(,{%[]%s*", -10))
      :with_move(function(opts2) return opts2.char == "|" end),
  })

  -- ── Elixir / Heex: do … end blocks ────────────────────────────────────────
  npairs.add_rules({
    RULE("do", "end", { "elixir", "heex" })
      :with_pair(COND.before_regex("%s", -1))
      :with_cr(COND.none()),
  })

  -- ── LaTeX: math  $…$ and $$…$$ ───────────────────────────────────────────
  npairs.add_rules({
    RULE("$", "$", "tex")
      :with_pair(ts_conds.is_not_ts_node({ "math_environment" })),
    RULE("$$", "$$", "tex")
      :with_pair(COND.before_regex("^%s*", -10))
      :set_end_pair_length(2),
  })

  -- ── Lua: string delimiters [[…]] ─────────────────────────────────────────
  npairs.add_rules({
    RULE("[[", "]]", "lua")
      :with_pair(COND.not_before_regex("[%[%]]")),
  })

  -- ── Fish shell: command substitution  (…) ────────────────────────────────
  npairs.add_rules({
    RULE("(", ")", "fish")
      :with_move(function(opts2) return opts2.char == ")" end),
  })

  -- ── HTML / JSX / TSX: < tag auto-completion ──────────────────────────────
  -- Handled by nvim-ts-autotag; we skip conflicting angle-bracket rules here.

  -- ── Generic: add space inside braces on <Space> ──────────────────────────
  -- e.g.  {|} → <Space> → { | }
  npairs.add_rules({
    RULE(" ", " ")
      :with_pair(function(opts2)
        local pair_str = opts2.line:sub(opts2.col - 1, opts2.col)
        return vim.tbl_contains({ "{}", "[]", "()" }, pair_str)
      end),
    -- Keep the expansion symmetric on <BS>
    RULE("{ ", " }")
      :with_pair(COND.none())
      :with_del(function(opts2)
        local col = opts2.col
        return opts2.line:sub(col - 2, col + 1) == "{  }"
      end),
  })

  -- ── Multi-char arrow pairs (TypeScript / Rust) ────────────────────────────
  npairs.add_rules({
    -- TS: => (don't pair — just move past >)
    move_past(">", { "typescript", "typescriptreact", "javascript" }),
    -- Rust: -> (don't pair)
    move_past(">", "rust"),
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔌 nvim-cmp INTEGRATION — ensure <CR> works with completion menu
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_cmp_integration(npairs)
  local ok_cmp, cmp = pcall(require, "cmp")
  if not ok_cmp then return end

  local cmp_autopairs = require("nvim-autopairs.completion.cmp")

  -- Insert closing bracket after cmp confirms a function/method
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

  -- Override cmp <CR> mapping so autopairs also fires
  local cmp_mappings = cmp.get_config().mapping
  if cmp_mappings then
    cmp_mappings["<CR>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        if cmp.get_active_entry() then
          cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
        else
          fallback()
        end
      else
        -- Let autopairs handle <CR> when no completion is active
        local autopairs_cr = npairs.autopairs_cr()
        if autopairs_cr then
          vim.api.nvim_feedkeys(autopairs_cr, "n", true)
        else
          fallback()
        end
      end
    end, { "i", "s" })
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📦 PLUGIN SPEC
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  {
    "windwp/nvim-autopairs",
    event        = "InsertEnter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      -- cmp integration (optional; fails gracefully if cmp absent)
      { "hrsh7th/nvim-cmp", optional = true },
    },

    -- ── Options ─────────────────────────────────────────────────────────────
    opts = {
      -- ── Engine ────────────────────────────────────────────────────────────
      -- Use treesitter to detect string / comment nodes
      check_ts               = true,
      ts_config              = {
        -- Don't pair inside these TS nodes for any language
        lua        = { "string", "source", "comment" },
        python     = { "string", "string_content" },
        javascript = { "string", "template_string", "comment" },
        typescript = { "string", "template_string", "comment" },
        rust       = { "string_content", "char_literal", "line_comment", "block_comment" },
        go         = { "interpreted_string_literal", "raw_string_literal", "comment" },
        cpp        = { "string_literal", "char_literal", "comment" },
        c          = { "string_literal", "char_literal", "comment" },
        java       = { "string_literal", "comment", "block_comment" },
        haskell    = { "string", "comment" },
        elixir     = { "string", "sigil", "comment" },
        fish       = { "string", "comment" },
        bash       = { "string", "comment" },
        sh         = { "string", "comment" },
        nix        = { "string", "comment" },
        markdown   = { "fenced_code_block", "code_span" },
        tex        = { "math_environment", "verbatim" },
        hypr       = { "comment" },
        rasi       = { "string_value", "comment" },
      },

      -- ── Behaviour flags ────────────────────────────────────────────────
      -- Skip if the next char is the same closing bracket
      enable_check_bracket_line  = true,

      -- Support for multi-byte characters (CJK etc.)
      enable_moveright           = true,

      -- Pair after a move-right to avoid double-closing
      enable_afterquote          = true,

      -- Bracket balance check for <CR> auto-indent
      enable_bracket_in_quote    = true,

      -- Abort pairing if the closing char already exists on the same line
      enable_abbr                = false,

      -- Break undo sequence before inserting pair
      break_undo                 = true,

      -- Map <CR> automatically (we'll override below if cmp is present)
      map_cr                     = true,

      -- Map <BS> to delete pairs symmetrically
      map_bs                     = true,

      -- Map <C-h> as an alternate backspace inside pairs
      map_c_h                    = false,

      -- Map <C-w> (word-delete) to also remove the pair
      map_c_w                    = false,

      -- Pair < > in insert mode (disabled globally; enabled per-ft above)
      disable_filetype           = DISABLE_FILETYPES,

      -- In insert mode after certain characters (e.g., `=`) don't pair `"`
      ignored_next_char           = [=[[%w%%%'%[%"%.%`%$]]=],

      -- Fast wrap: press <M-e> to wrap the next expression in a bracket
      fast_wrap = {
        map             = "<M-e>",
        chars           = { "{", "[", "(", '"', "'" },
        pattern         = [=[[%'%"%>%]%)%}%,]]=],
        end_key         = "$",
        before_key      = "h",
        after_key       = "l",
        cursor_pos_before = true,
        keys            = "qwertyuiopzxcvbnmasdfghjkl",
        manual_position = true,
        highlight       = "IncSearch",
        highlight_grey  = "Comment",
      },
    },

    -- ── Full config ─────────────────────────────────────────────────────────
    config = function(_, opts)
      local npairs = require("nvim-autopairs")
      npairs.setup(opts)

      -- Add custom language-specific rules
      add_custom_rules(npairs)

      -- Wire up nvim-cmp <CR> integration
      setup_cmp_integration(npairs)

      -- ── ASH hot-reload: re-apply TS config on theme change ───────────────
      -- (ASH may swap parsers; a quick disable/enable refreshes the TS checks)
      local aug = vim.api.nvim_create_augroup("AshAutopairs", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group   = aug,
        pattern = "AshThemeChanged",
        callback = function()
          npairs.disable()
          vim.defer_fn(npairs.enable, 100)
        end,
      })

      -- ── Notify on load (debug / ultra mode indicator) ────────────────────
      if vim.g.ash_debug then
        vim.notify(
          "🔗 Autopairs loaded — " .. vim.tbl_count(npairs.get_rules()) .. " rules active",
          vim.log.levels.DEBUG,
          { title = "ASH Autopairs" }
        )
      end
    end,
  },
}