-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║     🌳 TREESITTER-CONTEXT — ULTRA STICKY SCOPE HEADER v5.0 OMEGA              ║
-- ║   Always-visible breadcrumb showing current function/class/block context        ║
-- ║   ASH theme-aware • animated separator • smart multi-line support               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT PALETTE — synced with ASH theme engine
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- Context window background (slightly darker than Normal)
    hl(0, "TreesitterContext", {
      link = "NormalFloat",
    })
  
    -- Line numbers inside context
    hl(0, "TreesitterContextLineNumber", {
      link = "LineNr",
    })
  
    -- Bottom separator line
    hl(0, "TreesitterContextSeparator", {
      link = "FloatBorder",
    })
  
    -- The "bottom" of the context (line being scrolled to)
    hl(0, "TreesitterContextBottom", {
      underline = true,
      sp        = (function()
        -- Dynamically pull the FloatBorder fg for the underline colour
        local ok, fl = pcall(vim.api.nvim_get_hl, 0, { name = "FloatBorder", link = false })
        return (ok and fl.fg) and string.format("#%06x", fl.fg) or nil
      end)(),
    })
  
    -- Current node kind label (function / class / if …)
    hl(0, "TreesitterContextLineNumberBottom", {
      underline = true,
    })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 FILETYPE EXCLUSIONS — never show context in these buffers
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local EXCLUDE_FILETYPES = {
    -- UI / plugin windows
    "alpha",
    "dashboard",
    "starter",
    "neo-tree",
    "NvimTree",
    "Outline",
    "aerial",
    "symbols-outline",
    "Trouble",
    "trouble",
    "qf",
    "quickfix",
    "loclist",
  
    -- Terminal / REPL
    "toggleterm",
    "terminal",
    "neoterm",
    "fterm",
    "floaterm",
  
    -- Fuzzy finders
    "TelescopePrompt",
    "TelescopeResults",
    "TelescopePreview",
    "fzf",
  
    -- LSP / completion
    "lspinfo",
    "lsp-installer",
    "mason",
    "null-ls-info",
  
    -- Notification / popup
    "notify",
    "noice",
    "Noice",
    "fidget",
    "DressingInput",
    "DressingSelect",
    "nui",
  
    -- Help / docs
    "help",
    "man",
  
    -- Git
    "fugitive",
    "fugitiveblame",
    "gitcommit",
    "git",
    "Diffview*",
    "NeogitStatus",
    "NeogitCommitMessage",
  
    -- Note-taking
    "neorg",
    "org",
    "orgagenda",
  
    -- Misc
    "lazy",
    "lazyterm",
    "packer",
    "prompt",
    "oil",
    "yazi",
    "minifiles",
    "codecompanion",
    "avante",
    "AvanteInput",
    "snacks_dashboard",
    "snacks_picker",
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📐 CONTEXT MODES — per-filetype max_lines overrides
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Languages with deeply nested structures benefit from more context lines
  local DEEP_CONTEXT_FT = {
    "rust",
    "haskell",
    "cpp",
    "java",
    "kotlin",
    "scala",
    "elixir",
    "ocaml",
    "go",
  }
  
  -- Languages where minimal context (1–2 lines) is sufficient
  local MINIMAL_CONTEXT_FT = {
    "lua",
    "python",
    "javascript",
    "typescript",
    "bash",
    "fish",
    "sh",
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  STATUS LINE INTEGRATION — show context in lualine / statusline
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Returns a compact single-line breadcrumb string for statusline use
  -- e.g.  "MyClass > my_method > if condition"
  local function get_context_string()
    local ok, ctx_mod = pcall(require, "treesitter-context")
    if not ok then return "" end
  
    -- nvim-treesitter-context does not expose a public Lua API for the
    -- breadcrumb text, so we walk the context nodes manually.
    local winnr   = vim.api.nvim_get_current_win()
    local bufnr   = vim.api.nvim_win_get_buf(winnr)
    local cursor  = vim.api.nvim_win_get_cursor(winnr)
    local row     = cursor[1] - 1
  
    local lang_tree_ok, lang_tree = pcall(vim.treesitter.get_parser, bufnr)
    if not lang_tree_ok or not lang_tree then return "" end
  
    local tree = lang_tree:parse()[1]
    if not tree then return "" end
  
    local node = tree:root():named_descendant_for_range(row, 0, row, 0)
    if not node then return "" end
  
    local INTEREST = {
      ["function_declaration"]  = true,
      ["function_definition"]   = true,
      ["method_declaration"]    = true,
      ["method_definition"]     = true,
      ["class_declaration"]     = true,
      ["class_definition"]      = true,
      ["impl_item"]             = true,
      ["trait_item"]            = true,
      ["if_expression"]         = true,
      ["for_statement"]         = true,
      ["while_statement"]       = true,
      ["match_expression"]      = true,
      ["block"]                 = false,  -- too noisy
    }
  
    local parts  = {}
    local walker = node
  
    -- Walk upward collecting interesting ancestors
    while walker do
      local kind = walker:type()
      if INTEREST[kind] then
        -- Extract identifier child as label
        for child in walker:iter_children() do
          local ctype = child:type()
          if ctype == "name"
            or ctype == "identifier"
            or ctype == "field_identifier"
            or ctype == "type_identifier"
          then
            local text = vim.treesitter.get_node_text(child, bufnr)
            if text and text ~= "" then
              table.insert(parts, 1, text)
              break
            end
          end
        end
      end
      walker = walker:parent()
    end
  
    if #parts == 0 then return "" end
    return table.concat(parts, "  ")
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "nvim-treesitter/nvim-treesitter-context",
      event        = { "BufReadPre", "BufNewFile" },
      dependencies = { "nvim-treesitter/nvim-treesitter" },
  
      -- ── Keybindings ─────────────────────────────────────────────────────────
      keys = {
        -- Jump upward to the context node (repeat with count)
        {
          "[x",
          function()
            require("treesitter-context").go_to_context(vim.v.count1)
          end,
          desc   = "🌳 Jump to context scope",
          silent = true,
        },
  
        -- Toggle context visibility
        {
          "<leader>ux",
          function()
            local ctx = require("treesitter-context")
            ctx.toggle()
            local enabled = require("treesitter-context.config").enable
            vim.notify(
              enabled and "🌳 Context  enabled" or "🌳 Context  disabled",
              vim.log.levels.INFO,
              { title = "Treesitter Context", timeout = 2000 }
            )
          end,
          desc   = "🌳 Toggle Treesitter Context",
          silent = true,
        },
  
        -- Increase max_lines on the fly
        {
          "<leader>u+",
          function()
            local cfg = require("treesitter-context.config")
            cfg.max_lines = math.min((cfg.max_lines or 3) + 1, 10)
            vim.notify(
              "🌳 Context max_lines → " .. cfg.max_lines,
              vim.log.levels.INFO,
              { title = "Treesitter Context", timeout = 1500 }
            )
          end,
          desc   = "🌳 Context: more lines",
          silent = true,
        },
  
        -- Decrease max_lines on the fly
        {
          "<leader>u-",
          function()
            local cfg = require("treesitter-context.config")
            cfg.max_lines = math.max((cfg.max_lines or 3) - 1, 1)
            vim.notify(
              "🌳 Context max_lines → " .. cfg.max_lines,
              vim.log.levels.INFO,
              { title = "Treesitter Context", timeout = 1500 }
            )
          end,
          desc   = "🌳 Context: fewer lines",
          silent = true,
        },
      },
  
      -- ── Options ─────────────────────────────────────────────────────────────
      opts = {
        -- Show context when the top of the scope has scrolled off-screen
        enable             = true,
  
        -- Maximum lines the context window may occupy
        -- Dynamically adjusted per-filetype in the config() hook below
        max_lines          = 4,
  
        -- Minimum window height before context activates
        min_window_height  = 16,
  
        -- Always show line numbers in context
        line_numbers       = true,
  
        -- Trim outer scope nodes to avoid redundant wrappers
        trim_scope         = "outer",
  
        -- Track by cursor position (most responsive) or "topline"
        mode               = "cursor",
  
        -- Separator between context and buffer content
        -- Set to nil for no separator, or a single character e.g. "─"
        separator          = "─",
  
        -- zindex: float above most UI elements but below popups
        zindex             = 20,
  
        -- Custom on_attach: disable for excluded filetypes
        on_attach          = function(bufnr)
          local ft = vim.bo[bufnr].filetype
          -- Exact match exclusion
          if vim.tbl_contains(EXCLUDE_FILETYPES, ft) then
            return false
          end
          -- Wildcard pattern exclusion (e.g. "Diffview*")
          for _, pattern in ipairs(EXCLUDE_FILETYPES) do
            if pattern:find("%*") then
              local glob = "^" .. pattern:gsub("%*", ".*") .. "$"
              if ft:match(glob) then return false end
            end
          end
          return true
        end,
      },
  
      -- ── Full config hook ────────────────────────────────────────────────────
      config = function(_, opts)
        local ctx = require("treesitter-context")
        ctx.setup(opts)
  
        -- Apply ASH-aware highlights immediately
        setup_highlights()
  
        -- Re-apply highlights whenever the colorscheme changes (ASH hot-reload)
        local aug = vim.api.nvim_create_augroup("AshTreesitterContext", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        -- ASH theme-change event (fired by ash-cli after palette swap)
        vim.api.nvim_create_autocmd("User", {
          group    = aug,
          pattern  = "AshThemeChanged",
          callback = function()
            setup_highlights()
            -- Brief disable/enable cycle forces context to repaint with new colours
            ctx.disable()
            vim.defer_fn(ctx.enable, 80)
          end,
        })
  
        -- Per-filetype max_lines adjustment
        vim.api.nvim_create_autocmd("FileType", {
          group    = aug,
          callback = function(ev)
            local ft  = vim.bo[ev.buf].filetype
            local cfg = require("treesitter-context.config")
  
            if vim.tbl_contains(DEEP_CONTEXT_FT, ft) then
              cfg.max_lines = 6
            elseif vim.tbl_contains(MINIMAL_CONTEXT_FT, ft) then
              cfg.max_lines = 2
            else
              cfg.max_lines = opts.max_lines
            end
          end,
        })
  
        -- Expose the context breadcrumb for lualine / other status plugins
        -- Usage in lualine:  { require("plugins.editor.treesitter-context").breadcrumb }
        _G.AshContextBreadcrumb = get_context_string
      end,
    },
  }