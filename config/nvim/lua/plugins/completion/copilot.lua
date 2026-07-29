-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🤖 COPILOT — ULTRA AI COMPLETION v5.0 OMEGA                              ║
-- ║   GitHub Copilot · ghost text · panel · cmp source · smart toggle             ║
-- ║   per-filetype control · ASH theme-synced · keybind ergonomics                ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — copilot ghost text & panel
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- Ghost text (suggestion shown before accepting)
    hl(0, "CopilotSuggestion",         {
      italic    = true,
      fg        = "#6e738d",
    })
  
    -- Annotation in status / panel
    hl(0, "CopilotAnnotation",         {
      bold      = true,
      fg        = "#6cc644",
    })
  
    -- Panel chrome
    hl(0, "CopilotPanelNormal",        { link = "NormalFloat"    })
    hl(0, "CopilotPanelBorder",        { link = "FloatBorder"    })
    hl(0, "CopilotPanelHeader",        {
      bold      = true,
      fg        = "#6cc644",
    })
  
    -- cmp item kind colour
    hl(0, "CmpItemKindCopilot",        { fg = "#6cc644"          })
  
    -- Status indicator
    hl(0, "CopilotStatusEnabled",      { bold = true, fg = "#6cc644" })
    hl(0, "CopilotStatusDisabled",     { italic = true, fg = "#6e738d" })
    hl(0, "CopilotStatusWarning",      { bold = true, fg = "#f9e2af" })
  
    -- ASH palette sync
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      local dim = p.overlay0 or p.subtext0 or "#6e738d"
      hl(0, "CopilotSuggestion", { italic = true, fg = dim })
      if p.green then
        hl(0, "CopilotAnnotation",   { bold = true, fg = p.green })
        hl(0, "CopilotPanelHeader",  { bold = true, fg = p.green })
        hl(0, "CmpItemKindCopilot",  { fg = p.green              })
        hl(0, "CopilotStatusEnabled",{ bold = true, fg = p.green })
      end
      hl(0, "CopilotStatusDisabled", { italic = true, fg = dim })
      if p.yellow then
        hl(0, "CopilotStatusWarning", { bold = true, fg = p.yellow })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 STATE MANAGEMENT — toggle & status
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local _copilot_enabled = true
  
  local function toggle_copilot()
    local ok, copilot = pcall(require, "copilot.suggestion")
    if not ok then
      vim.notify(
        "🤖 Copilot not available",
        vim.log.levels.WARN,
        { title = "Copilot" }
      )
      return
    end
  
    if _copilot_enabled then
      vim.cmd("Copilot disable")
      _copilot_enabled = false
      vim.notify(
        "🤖 Copilot  disabled",
        vim.log.levels.INFO,
        { title = "Copilot", timeout = 1200 }
      )
    else
      vim.cmd("Copilot enable")
      _copilot_enabled = true
      vim.notify(
        "🤖 Copilot  enabled",
        vim.log.levels.INFO,
        { title = "Copilot", timeout = 1200 }
      )
    end
  end
  
  local function show_copilot_status()
    local ok, copilot_api = pcall(require, "copilot.api")
    if not ok then
      vim.notify("🤖 Copilot not loaded", vim.log.levels.WARN, { title = "Copilot" })
      return
    end
  
    copilot_api.check_status({}, function(err, status)
      if err then
        vim.notify(
          "🤖 Copilot error: " .. tostring(err),
          vim.log.levels.ERROR,
          { title = "Copilot Status" }
        )
        return
      end
  
      local lines = {
        "🤖 GitHub Copilot Status",
        "─────────────────────────",
        string.format("  User:     %s", status.user or "unknown"),
        string.format("  Status:   %s", status.status or "unknown"),
        string.format("  Enabled:  %s", _copilot_enabled and "✅" or "⭕"),
      }
  
      vim.notify(
        table.concat(lines, "\n"),
        status.status == "OK" and vim.log.levels.INFO or vim.log.levels.WARN,
        { title = "Copilot" }
      )
    end)
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- ── Main copilot.vim plugin ────────────────────────────────────────────────
    {
      "zbirenbaum/copilot.lua",
      cmd          = "Copilot",
      event        = "InsertEnter",
  
      keys = {
        { "<leader>ac",  toggle_copilot,    desc = "🤖 Toggle Copilot",  silent = true },
        { "<leader>aS",  show_copilot_status, desc = "🤖 Copilot Status", silent = true },
        { "<leader>ap",  "<cmd>Copilot panel<cr>", desc = "🤖 Copilot Panel", silent = true },
        -- Accept suggestion
        {
          "<M-l>",
          function()
            local ok, suggestion = pcall(require, "copilot.suggestion")
            if ok and suggestion.is_visible() then suggestion.accept() end
          end,
          mode   = "i",
          desc   = "🤖 Accept Copilot suggestion",
          silent = true,
        },
        -- Accept next word only
        {
          "<M-w>",
          function()
            local ok, suggestion = pcall(require, "copilot.suggestion")
            if ok and suggestion.is_visible() then suggestion.accept_word() end
          end,
          mode   = "i",
          desc   = "🤖 Accept word",
          silent = true,
        },
        -- Accept next line only
        {
          "<M-Enter>",
          function()
            local ok, suggestion = pcall(require, "copilot.suggestion")
            if ok and suggestion.is_visible() then suggestion.accept_line() end
          end,
          mode   = "i",
          desc   = "🤖 Accept line",
          silent = true,
        },
        -- Next suggestion
        {
          "<M-]>",
          function()
            local ok, suggestion = pcall(require, "copilot.suggestion")
            if ok then suggestion.next() end
          end,
          mode   = "i",
          desc   = "🤖 Next suggestion",
          silent = true,
        },
        -- Prev suggestion
        {
          "<M-[>",
          function()
            local ok, suggestion = pcall(require, "copilot.suggestion")
            if ok then suggestion.prev() end
          end,
          mode   = "i",
          desc   = "🤖 Prev suggestion",
          silent = true,
        },
        -- Dismiss
        {
          "<M-e>",
          function()
            local ok, suggestion = pcall(require, "copilot.suggestion")
            if ok and suggestion.is_visible() then suggestion.dismiss() end
          end,
          mode   = "i",
          desc   = "🤖 Dismiss suggestion",
          silent = true,
        },
      },
  
      opts = {
        panel = {
          enabled       = true,
          auto_refresh  = false,
          keymap        = {
            jump_prev   = "[[",
            jump_next   = "]]",
            accept      = "<CR>",
            refresh     = "gr",
            open        = "<M-CR>",
          },
          layout        = {
            position     = "bottom",
            ratio        = 0.4,
          },
        },
  
        suggestion = {
          enabled         = true,
          auto_trigger    = true,
          debounce        = 75,
          keymap          = {
            accept         = false,   -- managed manually above
            accept_word    = false,
            accept_line    = false,
            next           = false,
            prev           = false,
            dismiss        = false,
          },
        },
  
        filetypes = {
          -- Enabled filetypes
          lua           = true,
          python        = true,
          rust          = true,
          go            = true,
          typescript    = true,
          typescriptreact = true,
          javascript    = true,
          javascriptreact = true,
          c             = true,
          cpp           = true,
          java          = true,
          kotlin        = true,
          swift         = true,
          dart          = true,
          zig           = true,
          haskell       = true,
          elixir        = true,
          ocaml         = true,
          gleam         = true,
          nix           = true,
          sh            = true,
          bash          = true,
          fish          = true,
          sql           = true,
          graphql       = true,
          proto         = true,
          yaml          = true,
          json          = true,
          toml          = true,
          terraform     = true,
          dockerfile    = true,
          markdown      = true,
          html          = true,
          css           = true,
          svelte        = true,
          vue           = true,
          astro         = true,
  
          -- Disabled filetypes
          ["."]         = false,   -- dotfiles
          text          = false,
          gitcommit     = false,
          gitrebase     = false,
          help          = false,
          TelescopePrompt = false,
          ["neo-tree"]  = false,
          lazy          = false,
          mason         = false,
          alpha         = false,
          dashboard     = false,
        },
  
        copilot_node_command = "node",
  
        server_opts_overrides = {
          settings = {
            advanced = {
              listCount          = 10,
              inlineSuggestCount = 3,
            },
          },
        },
      },
  
      config = function(_, opts)
        require("copilot").setup(opts)
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshCopilot", { clear = true })
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🤖 Copilot highlights synced", vim.log.levels.INFO,
              { title = "ASH Copilot", timeout = 1200 })
          end,
        })
  
        -- Expose statusline component
        _G.AshCopilotStatus = function()
          if not _copilot_enabled then return " 🤖 " end
          local ok, api = pcall(require, "copilot.api")
          if not ok then return "" end
          return " 🤖 "
        end
      end,
    },
  
    -- ── cmp source for copilot ─────────────────────────────────────────────────
    {
      "zbirenbaum/copilot-cmp",
      dependencies = { "zbirenbaum/copilot.lua" },
      event        = "InsertEnter",
      config       = function()
        require("copilot_cmp").setup({
          method       = "getCompletionsCycling",
          formatters   = {
            label        = require("copilot_cmp.format").format_label_text,
            insert_text  = require("copilot_cmp.format").format_insert_text,
            preview      = require("copilot_cmp.format").deindent,
          },
        })
      end,
    },
  }