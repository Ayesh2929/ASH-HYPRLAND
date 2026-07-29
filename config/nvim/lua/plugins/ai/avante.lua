-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🤖 AVANTE — ULTRA AI PAIR PROGRAMMER v5.0 OMEGA                          ║
-- ║   Cursor-style AI · diff view · multi-provider · inline suggestions            ║
-- ║   Claude · GPT-4 · Ollama · code apply · chat · ASH theme-synced              ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — immersive AI coding interface
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
  local hl = vim.api.nvim_set_hl

  -- ── Panel chrome ──────────────────────────────────────────────────────────
  hl(0, "AvanteNormal",             { link = "NormalFloat"   })
  hl(0, "AvanteNormalNC",           { link = "NormalFloat"   })
  hl(0, "AvanteBorder",             { link = "FloatBorder"   })
  hl(0, "AvanteTitle",              { bold = true, fg = "#bb9af7" })
  hl(0, "AvanteSubtitle",           { italic = true, fg = "#7aa2f7" })
  hl(0, "AvanteStatusText",         { fg = "#9399b2"              })
  hl(0, "AvantePopupHint",          { italic = true, fg = "#9399b2" })
  hl(0, "AvanteInlineHint",         { italic = true, fg = "#9399b2" })

  -- ── Chat messages ─────────────────────────────────────────────────────────
  hl(0, "AvanteUser",               { bold = true, fg = "#7aa2f7"   })
  hl(0, "AvanteAI",                 { bold = true, fg = "#bb9af7"   })
  hl(0, "AvanteUserIcon",           { bold = true, fg = "#7aa2f7"   })
  hl(0, "AvanteAIIcon",             { bold = true, fg = "#bb9af7"   })
  hl(0, "AvanteMessageContainer",   { link = "NormalFloat"   })

  -- ── Code diff ─────────────────────────────────────────────────────────────
  hl(0, "AvanteDiffAdd",            { bg = "#1a2b1a", fg = "NONE"  })
  hl(0, "AvanteDiffDelete",         { bg = "#2d1b1e", fg = "NONE"  })
  hl(0, "AvanteDiffText",           { bg = "#2d2a1e", fg = "NONE"  })
  hl(0, "AvanteDiffAddLine",        {
    bold = true,
    fg   = "#9ece6a",
    bg   = "#1a2b1a",
  })
  hl(0, "AvanteDiffDeleteLine",     {
    bold = true,
    fg   = "#f38ba8",
    bg   = "#2d1b1e",
  })
  hl(0, "AvanteDiffAddBoundary",    { fg = "#9ece6a"               })
  hl(0, "AvanteDiffDeleteBoundary", { fg = "#f38ba8"               })

  -- ── Conflict markers ──────────────────────────────────────────────────────
  hl(0, "AvanteConflictCurrent",    { bg = "#1a2b1a"               })
  hl(0, "AvanteConflictIncoming",   { bg = "#1e2d4a"               })
  hl(0, "AvanteConflictAncestor",   { bg = "#2d2a1e"               })
  hl(0, "AvanteConflictCurrentLabel",  { bold = true, fg = "#9ece6a" })
  hl(0, "AvanteConflictIncomingLabel", { bold = true, fg = "#7aa2f7" })
  hl(0, "AvanteConflictAncestorLabel", { bold = true, fg = "#f9e2af" })

  -- ── Suggestions ────────────────────────────────────────────────────────────
  hl(0, "AvanteSuggestion",         { italic = true, fg = "#6e738d" })
  hl(0, "AvanteThinking",           { bold = true, italic = true, fg = "#f9e2af" })
  hl(0, "AvanteLoading",            { bold = true, fg = "#f9e2af"  })

  -- ── Tokens ────────────────────────────────────────────────────────────────
  hl(0, "AvanteReversedNormal",     { bg = "#bb9af7", fg = "#1a1b26" })
  hl(0, "AvanteReversedSubtitle",   { bg = "#7aa2f7", fg = "#1a1b26" })

  -- ── ASH palette sync ──────────────────────────────────────────────────────
  local ok, ash = pcall(require, "ash.theme")
  if ok and ash.palette then
    local p = ash.palette
    if p.mauve  then
      hl(0, "AvanteTitle",   { bold = true, fg = p.mauve })
      hl(0, "AvanteAI",      { bold = true, fg = p.mauve })
      hl(0, "AvanteAIIcon",  { bold = true, fg = p.mauve })
    end
    if p.blue   then
      hl(0, "AvanteSubtitle",  { italic = true, fg = p.blue })
      hl(0, "AvanteUser",      { bold = true,   fg = p.blue })
      hl(0, "AvanteUserIcon",  { bold = true,   fg = p.blue })
    end
    if p.green  then
      hl(0, "AvanteDiffAdd",      { bg = p.surface0 or "#1a2b1a" })
      hl(0, "AvanteDiffAddLine",  { bold = true, fg = p.green, bg = p.surface0 or "#1a2b1a" })
      hl(0, "AvanteDiffAddBoundary", { fg = p.green })
    end
    if p.red    then
      hl(0, "AvanteDiffDelete",       { bg = p.surface0 or "#2d1b1e" })
      hl(0, "AvanteDiffDeleteLine",   { bold = true, fg = p.red, bg = p.surface0 or "#2d1b1e" })
      hl(0, "AvanteDiffDeleteBoundary",{ fg = p.red })
    end
    if p.yellow then
      hl(0, "AvanteThinking", { bold = true, italic = true, fg = p.yellow })
      hl(0, "AvanteLoading",  { bold = true, fg = p.yellow })
    end
    local dim = p.overlay0 or "#6e738d"
    hl(0, "AvanteSuggestion",  { italic = true, fg = dim })
    hl(0, "AvanteStatusText",  { fg = dim })
    hl(0, "AvantePopupHint",   { italic = true, fg = dim })
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📦 PLUGIN SPEC
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  {
    "yetone/avante.nvim",
    version      = false,
    event        = "VeryLazy",
    build        = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      { "nvim-tree/nvim-web-devicons",   optional = true },
      { "zbirenbaum/copilot.lua",        optional = true },
      { "HakonHarnes/img-clip.nvim",     optional = true },
      { "MeanderingProgrammer/render-markdown.nvim", optional = true },
    },

    keys = {
      {
        "<leader>aa",
        function() require("avante.api").ask() end,
        desc   = "🤖 Avante: Ask",
        mode   = { "n", "v" },
        silent = true,
      },
      {
        "<leader>ae",
        function() require("avante.api").edit() end,
        desc   = "🤖 Avante: Edit",
        mode   = { "n", "v" },
        silent = true,
      },
      {
        "<leader>ar",
        function() require("avante.api").refresh() end,
        desc   = "🤖 Avante: Refresh",
        silent = true,
      },
      {
        "<leader>af",
        function() require("avante.api").focus() end,
        desc   = "🤖 Avante: Focus",
        silent = true,
      },
      {
        "<leader>at",
        function() require("avante").toggle() end,
        desc   = "🤖 Avante: Toggle",
        silent = true,
      },
      -- ── Quick actions ──────────────────────────────────────────────────────
      {
        "<leader>aex",
        function()
          require("avante.api").ask({
            question = "Explain this code in detail. What does it do and how?",
          })
        end,
        mode   = { "n", "v" },
        desc   = "🤖 Avante: Explain",
        silent = true,
      },
      {
        "<leader>afx",
        function()
          require("avante.api").ask({
            question = "Fix any bugs, errors, or issues in this code. Return only the corrected code.",
          })
        end,
        mode   = { "n", "v" },
        desc   = "🤖 Avante: Fix bugs",
        silent = true,
      },
      {
        "<leader>aop",
        function()
          require("avante.api").ask({
            question = "Optimize this code for performance and efficiency. Explain the improvements.",
          })
        end,
        mode   = { "n", "v" },
        desc   = "🤖 Avante: Optimize",
        silent = true,
      },
      {
        "<leader>adoc",
        function()
          require("avante.api").ask({
            question = "Add comprehensive documentation to this code including docstrings, parameter descriptions, and examples.",
          })
        end,
        mode   = { "n", "v" },
        desc   = "🤖 Avante: Document",
        silent = true,
      },
      {
        "<leader>atst",
        function()
          require("avante.api").ask({
            question = "Write comprehensive unit tests for this code covering edge cases, happy paths, and error handling.",
          })
        end,
        mode   = { "n", "v" },
        desc   = "🤖 Avante: Write tests",
        silent = true,
      },
      -- ── Provider switching ─────────────────────────────────────────────────
      {
        "<leader>apm",
        function()
          local providers = { "claude", "openai", "copilot", "gemini", "ollama" }
          vim.ui.select(providers, { prompt = "🤖 Avante provider: " }, function(p)
            if p then
              require("avante").switch_provider(p)
              vim.notify("🤖 Switched to: " .. p, vim.log.levels.INFO,
                { title = "Avante", timeout = 1200 })
            end
          end)
        end,
        desc   = "🤖 Avante: Switch provider",
        silent = true,
      },
    },

    opts = {
      -- ── Provider ─────────────────────────────────────────────────────────
      provider = (function()
        -- Auto-select based on available API keys
        local keys = {
          claude  = os.getenv("ANTHROPIC_API_KEY"),
          openai  = os.getenv("OPENAI_API_KEY"),
          gemini  = os.getenv("GEMINI_API_KEY"),
          copilot = os.getenv("GITHUB_TOKEN"),
        }
        for provider, key in pairs(keys) do
          if key and key ~= "" then return provider end
        end
        return "ollama"  -- Fall back to local Ollama
      end)(),

      -- ── Auto suggestions ──────────────────────────────────────────────────
      auto_suggestions_provider = "copilot",

      -- ── Provider configs ──────────────────────────────────────────────────
      claude = {
        endpoint = "https://api.anthropic.com",
        model    = "claude-3-5-sonnet-20241022",
        timeout  = 30000,
        temperature = 0,
        max_tokens  = 8096,
      },

      openai = {
        endpoint = "https://api.openai.com/v1",
        model    = "gpt-4o",
        timeout  = 30000,
        temperature = 0,
        max_tokens  = 8096,
      },

      gemini = {
        endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
        model    = "gemini-2.0-flash-exp",
        timeout  = 30000,
        temperature = 0,
        max_tokens  = 8096,
      },

      copilot = {
        endpoint = "https://api.githubcopilot.com",
        model    = "gpt-4o-2024-08-06",
        proxy    = nil,
        allow_insecure = false,
        timeout  = 30000,
        temperature = 0,
        max_tokens  = 8096,
      },

      ollama = {
        endpoint = os.getenv("OLLAMA_HOST") or "http://localhost:11434",
        model    = "codestral:latest",
        timeout  = 60000,
        temperature = 0,
        max_tokens  = 8096,
        options  = {
          num_ctx= 32768,
        },
      },

      -- ── Behaviour ─────────────────────────────────────────────────────────
      behaviour = {
        auto_suggestions          = false,
        auto_set_highlight_group  = true,
        auto_set_keymaps          = true,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = true,
        minimize_diff             = true,
        enable_token_counting     = true,
      },

      -- ── Windows ───────────────────────────────────────────────────────────
      windows = {
        position          = "right",
        wrap              = true,
        width             = 40,
        height            = 0,
        sidebar_header    = {
          enabled    = true,
          align      = "center",
          rounded    = false,
        },
        input             = {
          prefix   = " 🤖 ",
          height   = 8,
        },
        edit              = {
          border   = "rounded",
          start_insert = true,
        },
        ask               = {
          floating          = false,
          border            = "rounded",
          start_insert      = true,
          focus_on_apply    = "theirs",
        },
      },

      -- ── Diff ─────────────────────────────────────────────────────────────
      diff = {
        autojump           = false,
        list_opener        = "copen",
        override_timeoutlen= 500,
      },

      -- ── Suggestion ────────────────────────────────────────────────────────
      suggestion = {
        debounce   = 600,
        throttle   = 600,
      },

      -- ── Hints ────────────────────────────────────────────────────────────
      hints = {
        enabled = true,
      },

      -- ── System prompt ─────────────────────────────────────────────────────
      system_prompt = [[You are an elite software engineer with deep expertise across all programming languages, frameworks, and systems.

You are pair programming with a developer using the ASH OMEGA v5.0 dotfiles environment on Arch Linux with Hyprland.

Guidelines:
- Provide concise, correct, production-ready code
- Follow language-specific best practices and idioms
- Prefer modern syntax and patterns
- Include error handling when appropriate
- Add helpful inline comments for complex logic
- Suggest improvements when you notice potential issues
- Be direct and actionable in your responses]],

      -- ── Mappings ─────────────────────────────────────────────━━━━━━━━━━━━
      mappings = {
        diff = {
          ours    = "co",
          theirs  = "ct",
          all_theirs = "ca",
          both    = "cb",
          cursor  = "cc",
          next    = "]x",
          prev    = "[x",
        },
        suggestion = {
          accept  = "<M-l>",
          next    = "<M-]>",
          prev    = "<M-[>",
          dismiss = "<M-[>",
        },
        jump = {
          next = "]]",
          prev = "[[",
        },
        submit = {
          normal  = "<CR>",
          insert  = "<C-s>",
        },
        cancel = {
          normal  = { "<C-c>", "<Esc>", "q" },
          insert  = "<C-c>",
        },
        sidebar = {
          apply_all     = "A",
          apply_cursor  = "a",
          retry_user_request = "r",
          edit_user_request  = "e",
          switch_windows = "<Tab>",
          reverse_switch_windows = "<S-Tab>",
        },
      },
    },

    config = function(_, opts)
      require("avante").setup(opts)

      setup_highlights()

      -- Disable mini-plugins in avante panes
      local aug = vim.api.nvim_create_augroup("AshAvante", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group   = aug,
        pattern = { "Avante", "AvanteInput", "AvanteSelectedCode" },
        callback = function(ev)
          vim.b[ev.buf].miniindentscope_disable = true
          vim.b[ev.buf].minianimate_disable     = true
          vim.opt_local.spell = true
          vim.opt_local.wrap  = true
        end,
      })

      vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
      vim.api.nvim_create_autocmd("User", {
        group   = aug,
        pattern = "AshThemeChanged",
        callback = function()
          setup_highlights()
          vim.notify("🤖 Avante highlights synced", vim.log.levels.INFO,
            { title = "ASH Avante", timeout = 1200 })
        end,
      })
    end,
  },
}
