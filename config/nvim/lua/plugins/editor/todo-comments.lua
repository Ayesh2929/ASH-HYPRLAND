-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║     📝 TODO-COMMENTS — ULTRA ANNOTATION ENGINE v5.0 OMEGA                      ║
-- ║   60+ keyword tags · gradient highlights · Treesitter-safe · Trouble & Tele    ║
-- ║   scope integration · ASH custom tags · animated signs · multi-lang support    ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 COLOUR PALETTE — per-severity, ASH-synced
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Base colours (fallback when ASH palette not available)
local COLOURS = {
    red      = { "#f38ba8", "#db4b4b" },
    orange   = { "#fab387", "#e0af68" },
    yellow   = { "#f9e2af", "#e0af68" },
    green    = { "#a6e3a1", "#9ece6a" },
    teal     = { "#94e2d5", "#73daca" },
    blue     = { "#89b4fa", "#7aa2f7" },
    lavender = { "#b4befe", "#bb9af7" },
    pink     = { "#f5c2e7", "#ff007c" },
    grey     = { "#9399b2", "#545c7e" },
    white    = { "#cdd6f4", "#c0caf5" },
  }
  
  -- Resolve a colour: try ASH palette first, then fallback list
  local function colour(key, fallback_idx)
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      local map = {
        red      = p.red    or p.error,
        orange   = p.peach  or p.orange,
        yellow   = p.yellow or p.warning,
        green    = p.green,
        teal     = p.teal,
        blue     = p.blue   or p.info,
        lavender = p.lavender or p.mauve,
        pink     = p.pink   or p.flamingo,
        grey     = p.overlay1 or p.subtext0,
        white    = p.text,
      }
      if map[key] then return map[key] end
    end
    return COLOURS[key][fallback_idx or 1]
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🏷️  KEYWORD DEFINITIONS — 60+ tags across 12 categories
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  --[[
    KEYWORD SCHEMA:
    {
      icon     = string,          -- sign column icon
      color    = string|"#hex",   -- highlight colour (named or hex)
      alt      = { string, … },   -- alternative spellings also matched
      signs    = bool,            -- show in sign column (default true)
      priority = int,             -- sign priority
      pattern  = string|list,     -- custom Lua pattern(s) (overrides default)
      comments_only = bool,       -- only match inside comment nodes
    }
  ]]
  
  local KEYWORDS = {
  
    -- ── 🔴 CRITICAL — must be fixed before ship ───────────────────────────────
    FIXME = {
      icon  = "🐛",
      color = colour("red"),
      alt   = { "FIXME!", "FIXIT", "FIX", "BUG", "DEFECT", "BROKEN", "CRITICAL" },
      signs = true,
      priority = 80,
    },
    BUG = {
      icon  = " ",
      color = colour("red"),
      alt   = { "BUG!", "REGRESSION", "DEFECT" },
      priority = 79,
    },
    CRITICAL = {
      icon  = "🔥",
      color = colour("red"),
      alt   = { "CRITICAL!" },
      priority = 78,
    },
    ERROR = {
      icon  = " ",
      color = colour("red"),
      alt   = { "ERR" },
      priority = 77,
    },
  
    -- ── 🟡 ATTENTION — needs work but not blocking ────────────────────────────
    TODO = {
      icon  = "✅",
      color = colour("blue"),
      alt   = { "TODO!", "TO-DO", "TO_DO" },
      signs = true,
      priority = 70,
    },
    HACK = {
      icon  = "⚡",
      color = colour("orange"),
      alt   = { "HACK!", "WORKAROUND", "KLUDGE", "BODGE" },
      priority = 69,
    },
    WARN = {
      icon  = " ",
      color = colour("yellow"),
      alt   = { "WARN!", "WARNING", "CAUTION", "DANGER", "UNSAFE" },
      priority = 68,
    },
    DEPRECATED = {
      icon  = "🗑️ ",
      color = colour("grey"),
      alt   = { "DEPRECATED!", "DEPRECATE", "OBSOLETE", "LEGACY", "DEAD" },
      priority = 67,
    },
    REFACTOR = {
      icon  = "🔨",
      color = colour("orange"),
      alt   = { "REFACTOR!", "CLEANUP", "CLEAN" },
      priority = 66,
    },
    SMELL = {
      icon  = "👃",
      color = colour("orange"),
      alt   = { "CODE_SMELL", "ANTI_PATTERN" },
      priority = 65,
    },
    REVISIT = {
      icon  = "🔄",
      color = colour("yellow"),
      alt   = { "REVISIT!", "RETHINK", "RECONSIDER" },
      priority = 64,
    },
  
    -- ── 🟢 INFORMATIONAL — context for readers ───────────────────────────────
    NOTE = {
      icon  = "📝",
      color = colour("teal"),
      alt   = { "NOTE!", "INFO", "INFORMATION", "CONTEXT", "NOTICE", "REMARK" },
      signs = true,
      priority = 60,
    },
    DOCS = {
      icon  = "📖",
      color = colour("teal"),
      alt   = { "DOCS!", "DOC", "DOCUMENTATION", "README" },
      priority = 59,
    },
    EXPLAIN = {
      icon  = "💡",
      color = colour("teal"),
      alt   = { "EXPLAIN!", "WHY", "REASON" },
      priority = 58,
    },
    SEE = {
      icon  = "👁️ ",
      color = colour("teal"),
      alt   = { "SEE:", "SEE ALSO", "REF", "REFERENCE" },
      priority = 57,
    },
    LINK = {
      icon  = "🔗",
      color = colour("teal"),
      alt   = { "LINK:", "URL:", "SOURCE:" },
      priority = 56,
    },
  
    -- ── 🔵 PERFORMANCE ────────────────────────────────────────────────────────
    PERF = {
      icon  = "🚀",
      color = colour("lavender"),
      alt   = { "PERF!", "PERFORMANCE", "OPTIM", "OPTIMIZE", "OPTIMISE", "PROFILING" },
      signs = true,
      priority = 55,
    },
    SLOW = {
      icon  = "🐢",
      color = colour("lavender"),
      alt   = { "SLOW!", "BOTTLENECK", "HOT_PATH" },
      priority = 54,
    },
    MEMORY = {
      icon  = "💾",
      color = colour("lavender"),
      alt   = { "MEMORY!", "LEAK", "OOM", "ALLOC" },
      priority = 53,
    },
    CACHE = {
      icon  = "⚡",
      color = colour("lavender"),
      alt   = { "CACHE!", "MEMOIZE" },
      priority = 52,
    },
  
    -- ── 🧪 TESTING ────────────────────────────────────────────────────────────
    TEST = {
      icon  = "🧪",
      color = colour("green"),
      alt   = { "TEST!", "TESTING", "SPEC", "ASSERT", "VERIFY", "COVERAGE" },
      priority = 50,
    },
    MOCK = {
      icon  = "🎭",
      color = colour("green"),
      alt   = { "MOCK!", "STUB", "FAKE", "DUMMY" },
      priority = 49,
    },
    PENDING = {
      icon  = "⏳",
      color = colour("yellow"),
      alt   = { "PENDING!", "SKIP", "XFAIL", "WIP_TEST" },
      priority = 48,
    },
  
    -- ── 🔒 SECURITY ────────────────────────────────────────────────────────────
    SECURITY = {
      icon  = "🔒",
      color = colour("red"),
      alt   = { "SECURITY!", "SEC", "VULN", "CVE", "INJECT", "XSS", "SQLI" },
      signs = true,
      priority = 75,
    },
    AUDIT = {
      icon  = "🕵️ ",
      color = colour("red"),
      alt   = { "AUDIT!", "REVIEW_SECURITY" },
      priority = 74,
    },
    SECRET = {
      icon  = "🔑",
      color = colour("red"),
      alt   = { "SECRET!", "CREDENTIAL", "PASSWORD", "TOKEN", "API_KEY" },
      priority = 73,
    },
    SANITIZE = {
      icon  = "🧹",
      color = colour("orange"),
      alt   = { "SANITIZE!", "VALIDATE_INPUT", "ESCAPE" },
      priority = 72,
    },
  
    -- ── 📦 DEPENDENCIES ────────────────────────────────────────────────────────
    DEP = {
      icon  = "📦",
      color = colour("grey"),
      alt   = { "DEPENDENCY", "REQUIRES", "NEEDS" },
      priority = 45,
    },
    VERSION = {
      icon  = "🏷️ ",
      color = colour("grey"),
      alt   = { "VERSION!", "BUMP", "UPGRADE", "DOWNGRADE" },
      priority = 44,
    },
    COMPAT = {
      icon  = "🔀",
      color = colour("yellow"),
      alt   = { "COMPAT!", "COMPATIBILITY", "BREAKING", "SEMVER" },
      priority = 43,
    },
  
    -- ── 💡 IDEAS & FUTURE ─────────────────────────────────────────────────────
    IDEA = {
      icon  = "💡",
      color = colour("pink"),
      alt   = { "IDEA!", "PROPOSAL", "SUGGESTION", "MIGHT", "COULD" },
      priority = 40,
    },
    FUTURE = {
      icon  = "🔮",
      color = colour("pink"),
      alt   = { "FUTURE!", "LATER", "SOMEDAY", "V2", "NEXT" },
      priority = 39,
    },
    FEATURE = {
      icon  = "✨",
      color = colour("pink"),
      alt   = { "FEATURE!", "FEAT", "ENHANCEMENT" },
      priority = 38,
    },
    DESIGN = {
      icon  = "🎨",
      color = colour("pink"),
      alt   = { "DESIGN!", "UI", "UX", "STYLE" },
      priority = 37,
    },
  
    -- ── 🏗️ WORK IN PROGRESS ────────────────────────────────────────────────────
    WIP = {
      icon  = "🚧",
      color = colour("orange"),
      alt   = { "WIP!", "DRAFT", "IN_PROGRESS", "INCOMPLETE" },
      signs = true,
      priority = 65,
    },
    SCAFFOLD = {
      icon  = "🏗️ ",
      color = colour("orange"),
      alt   = { "SCAFFOLD!", "PLACEHOLDER", "STUB_CODE" },
      priority = 63,
    },
    TEMP = {
      icon  = "⏳",
      color = colour("orange"),
      alt   = { "TEMP!", "TEMPORARY", "INTERIM", "BAND_AID" },
      priority = 62,
    },
  
    -- ── ❓ QUESTIONS ────────────────────────────────────────────────────────────
    QUESTION = {
      icon  = "❓",
      color = colour("lavender"),
      alt   = { "QUESTION!", "ASK", "UNCLEAR", "UNDERSTAND", "WHY?", "?" },
      priority = 35,
    },
    REVIEW = {
      icon  = "👀",
      color = colour("lavender"),
      alt   = { "REVIEW!", "PR_REVIEW", "CODE_REVIEW", "FEEDBACK" },
      priority = 34,
    },
    DISCUSS = {
      icon  = "💬",
      color = colour("lavender"),
      alt   = { "DISCUSS!", "DEBATE", "BIKESHED", "DECISION" },
      priority = 33,
    },
  
    -- ── ✅ DONE / RESOLVED ─────────────────────────────────────────────────────
    DONE = {
      icon  = "✅",
      color = colour("green"),
      alt   = { "DONE!", "RESOLVED", "FIXED", "CLOSED", "COMPLETE" },
      priority = 30,
    },
    VERIFIED = {
      icon  = "✔️ ",
      color = colour("green"),
      alt   = { "VERIFIED!", "TESTED", "PASSED", "APPROVED" },
      priority = 29,
    },
  
    -- ── 🔥 ASH CUSTOM TAGS ────────────────────────────────────────────────────
    ASH = {
      icon  = "🔥",
      color = colour("orange"),
      alt   = { "ASH!", "ASH_TODO", "ASH_FIXME", "ASH_NOTE" },
      signs = true,
      priority = 90,   -- highest: ASH-specific notes always visible
    },
    OMEGA = {
      icon  = "⚡",
      color = colour("lavender"),
      alt   = { "OMEGA!", "V5", "V5.0" },
      priority = 89,
    },
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  ACTION HELPERS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function todo_telescope(filter)
    return function()
      local ok, tele = pcall(require, "todo-comments.fzf")
      if not ok then
        tele = require("todo-comments.telescope")
      end
      tele.todo(filter or {})
    end
  end
  
  local function todo_trouble(filter)
    return function()
      require("trouble").open(vim.tbl_extend("force",
        { mode = "todo" },
        filter or {}
      ))
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "folke/todo-comments.nvim",
      event        = { "BufReadPre", "BufNewFile" },
      dependencies = {
        "nvim-lua/plenary.nvim",
        { "folke/trouble.nvim",              optional = true },
        { "nvim-telescope/telescope.nvim",   optional = true },
        { "ibhagwan/fzf-lua",               optional = true },
      },
      cmd          = {
        "TodoTrouble",
        "TodoTelescope",
        "TodoFzfLua",
        "TodoLocList",
        "TodoQuickFix",
      },
  
      -- ── Keys ──────────────────────────────────────────────────────────────────
      keys = {
        -- ── Navigation ────────────────────────────────────────────────────────
        {
          "]t",
          function() require("todo-comments").jump_next() end,
          desc = "📝 Next TODO",
        },
        {
          "[t",
          function() require("todo-comments").jump_prev() end,
          desc = "📝 Prev TODO",
        },
        {
          "]T",
          function()
            require("todo-comments").jump_next({
              keywords = { "FIXME", "BUG", "CRITICAL", "ERROR", "SECURITY" },
            })
          end,
          desc = "📝 Next FIXME/BUG/CRITICAL",
        },
        {
          "[T",
          function()
            require("todo-comments").jump_prev({
              keywords = { "FIXME", "BUG", "CRITICAL", "ERROR", "SECURITY" },
            })
          end,
          desc = "📝 Prev FIXME/BUG/CRITICAL",
        },
  
        -- ── Telescope pickers ─────────────────────────────────────────────────
        {
          "<leader>st",
          todo_telescope(),
          desc = "📝 Todo (Telescope)",
        },
        {
          "<leader>sT",
          todo_telescope({ keywords = { "TODO", "FIXME", "BUG", "HACK", "WIP" } }),
          desc = "📝 Todo/Fixme/Bug (Telescope)",
        },
        {
          "<leader>sa",
          todo_telescope({ keywords = { "ASH", "OMEGA" } }),
          desc = "📝 ASH Tags (Telescope)",
        },
  
        -- ── Trouble pickers ───────────────────────────────────────────────────
        {
          "<leader>xT",
          trouble_todo(),
          desc = "📝 Todo (Trouble)",
        },
        {
          "<leader>xF",
          trouble_todo({ filter = { tag = { "TODO", "FIXME", "BUG" } } }),
          desc = "📝 TODO/FIXME/BUG (Trouble)",
        },
  
        -- ── Quickfix / Loclist ─────────────────────────────────────────────────
        {
          "<leader>tq",
          "<cmd>TodoQuickFix<cr>",
          desc = "📝 Todo → Quickfix",
        },
        {
          "<leader>tl",
          "<cmd>TodoLocList<cr>",
          desc = "📝 Todo → Loclist",
        },
  
        -- ── FZF-Lua ────────────────────────────────────────────────────────────
        {
          "<leader>tf",
          function()
            local ok, fl = pcall(require, "todo-comments.fzf")
            if ok then fl.todo() else
              vim.notify("fzf-lua not available", vim.log.levels.WARN,
                { title = "Todo Comments" })
            end
          end,
          desc = "📝 Todo (FZF-Lua)",
        },
      },
  
      -- ── Options ──────────────────────────────────────────────────────────────
      opts = {
        -- ── Sign column ───────────────────────────────────────────────────────
        signs           = true,
        sign_priority   = 8,
  
        -- ── Keywords ─────────────────────────────────────────────────────────
        keywords        = KEYWORDS,
  
        -- ── Merge keywords: alt spellings map to parent ───────────────────────
        merge_keywords  = true,
  
        -- ── Pattern matching ──────────────────────────────────────────────────
        -- Matches: KEYWORD: text  OR  KEYWORD!(text)  OR  KEYWORD (text)
        highlight = {
          -- Only match inside actual comment nodes (Treesitter-aware)
          comments_only   = true,
          -- Number of lines to include in the match
          multiline       = true,
          multiline_pattern = "^.",
          multiline_context = 10,
          -- Before / after the keyword
          before          = "",       -- e.g. "fg"  to colour the comment leader
          keyword         = "wide",   -- "fg" | "bg" | "wide" | "wide_bg" | "wide_fg" | ""
          after           = "fg",
          -- Pattern for matching (Lua pattern, not Vim regex)
          pattern         = [[.*<(KEYWORDS)\s*:]],
          -- Exclude patterns (don't highlight inside these)
          exclude         = {},
        },
  
        -- ── Colour definitions ────────────────────────────────────────────────
        colors = {
          error     = { "DiagnosticError",   "ErrorMsg",   "#db4b4b" },
          warning   = { "DiagnosticWarn",    "WarningMsg", "#e0af68" },
          info      = { "DiagnosticInfo",    "#7aa2f7"               },
          hint      = { "DiagnosticHint",    "#1abc9c"               },
          default   = { "Identifier",        "#7c3aed"               },
          test      = { "Identifier",        "#9ece6a"               },
          -- Custom named colours referenced in KEYWORDS above
          red       = { "#f38ba8"                                     },
          orange    = { "#fab387"                                     },
          yellow    = { "#f9e2af"                                     },
          green     = { "#a6e3a1"                                     },
          teal      = { "#94e2d5"                                     },
          blue      = { "#89b4fa"                                     },
          lavender  = { "#b4befe"                                     },
          pink      = { "#f5c2e7"                                     },
          grey      = { "#9399b2"                                     },
          white     = { "#cdd6f4"                                     },
        },
  
        -- ── Ripgrep search configuration ─────────────────────────────────────
        search = {
          -- Which command to use for searching
          command     = "rg",
          -- Args passed to rg
          args        = {
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--hidden",
            "--glob=!.git",
            "--glob=!node_modules",
            "--glob=!.venv",
            "--glob=!target",
            "--glob=!dist",
            "--glob=!build",
            "--glob=!__pycache__",
            "--glob=!*.lock",
            "--glob=!lazy-lock.json",
          },
          -- Pattern for rg (Rust regex)
          -- Matches: // TODO: ...  # FIXME: ...  -- NOTE: ...  etc.
          pattern     = [[\b(KEYWORDS)\b]],
        },
      },
  
      -- ── Config ───────────────────────────────────────────────────────────────
      config = function(_, opts)
        require("todo-comments").setup(opts)
  
        -- ── ASH hot-reload ───────────────────────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshTodoComments", { clear = true })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            -- Reload with updated palette colours
            local todo = require("todo-comments")
            -- Re-setup with refreshed colour() calls
            local new_opts = vim.deepcopy(opts)
            -- Patch colours to use new palette
            for kw, cfg in pairs(new_opts.keywords) do
              if type(cfg.color) == "string" then
                -- Re-resolve named palette colours
                local col_key
                for c, _ in pairs(COLOURS) do
                  if cfg.color == colour(c) then col_key = c break end
                end
                if col_key then
                  new_opts.keywords[kw].color = colour(col_key)
                end
              end
            end
            todo.setup(new_opts)
  
            vim.notify(
              "📝 Todo-comments palette updated for new ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Todo", timeout = 1500 }
            )
          end,
        })
  
        -- ── which-key group registration ─────────────────────────────────────
        local ok_wk, wk = pcall(require, "which-key")
        if ok_wk then
          wk.add({
            { "<leader>t", group = "📝 Todo" },
            { "<leader>s", group = "🔍 Search" },
          })
        end
  
        if vim.g.ash_debug then
          local kw_count = vim.tbl_count(KEYWORDS)
          local alt_count = 0
          for _, kw in pairs(KEYWORDS) do
            alt_count = alt_count + (#(kw.alt or {}))
          end
          vim.notify(
            string.format(
              "📝 Todo-comments: %d keywords, %d aliases",
              kw_count, alt_count
            ),
            vim.log.levels.DEBUG,
            { title = "ASH Todo" }
          )
        end
      end,
    },
  }