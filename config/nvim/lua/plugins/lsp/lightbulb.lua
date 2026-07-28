-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       💡 NVIM-LIGHTBULB — ULTRA CODE ACTION INDICATOR v5.0 OMEGA               ║
-- ║   Real-time 💡 sign · virtual text · status line · float preview               ║
-- ║   debounced · per-server · ASH theme-synced · actionable quick menu            ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — lightbulb colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Sign column lightbulb ─────────────────────────────────────────────────
    hl(0, "LightBulbSign",         {
      bold  = true,
      fg    = "#f9e2af",    -- warm amber/yellow
    })
  
    -- ── Virtual text next to line ─────────────────────────────────────────────
    hl(0, "LightBulbVirtualText",  {
      bold   = false,
      italic = true,
      fg     = "#f9e2af",
    })
  
    -- ── Float window ─────────────────────────────────────────────────────────
    hl(0, "LightBulbFloat",        { link = "NormalFloat"   })
    hl(0, "LightBulbFloatBorder",  { link = "FloatBorder"   })
  
    -- ── Status line indicator ─────────────────────────────────────────────────
    hl(0, "LightBulbStatus",       {
      bold  = true,
      fg    = "#f9e2af",
    })
  
    -- ── Animation pulse highlight ─────────────────────────────────────────────
    hl(0, "LightBulbPulse",        {
      bold  = true,
      fg    = "#ff9e64",
    })
  
    -- ── Number column when action available ───────────────────────────────────
    hl(0, "LightBulbNumHl",        { link = "LightBulbSign" })
  
    -- ── Line highlight when action available ──────────────────────────────────
    hl(0, "LightBulbLine",         {
      bg    = "#1e2030",
    })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      local amber = p.yellow or p.peach or "#f9e2af"
      hl(0, "LightBulbSign",        { bold = true, fg = amber              })
      hl(0, "LightBulbVirtualText", { italic = true, fg = amber            })
      hl(0, "LightBulbStatus",      { bold = true, fg = amber              })
      if p.orange then
        hl(0, "LightBulbPulse",     { bold = true, fg = p.orange           })
      end
      if p.surface1 then
        hl(0, "LightBulbLine",      { bg = p.surface1                      })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 SMART ACTION TRIGGER — run action or show menu
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Trigger code action (from lightbulb click or keymap)
  local function trigger_code_action(opts)
    return function()
      -- Try telescope first for better UX
      local ok_t, tele = pcall(require, "telescope.builtin")
      if ok_t then
        tele.lsp_code_actions(vim.tbl_extend("force", {
          prompt_title = "💡 Code Actions",
        }, opts or {}))
        return
      end
  
      -- Try fzf-lua
      local ok_f, fzf = pcall(require, "fzf-lua")
      if ok_f then
        fzf.lsp_code_actions(opts)
        return
      end
  
      -- Native fallback
      vim.lsp.buf.code_action(opts)
    end
  end
  
  -- Quick-fix: apply the first available code action automatically
  local function quick_fix()
    vim.lsp.buf.code_action({
      filter = function(action)
        return action.isPreferred
      end,
      apply = true,
    })
  end
  
  -- Show action count notification
  local function show_action_count()
    local bufnr   = vim.api.nvim_get_current_buf()
    local cursor  = vim.api.nvim_win_get_cursor(0)
    local params  = vim.lsp.util.make_range_params()
  
    vim.lsp.buf_request(
      bufnr,
      "textDocument/codeAction",
      params,
      function(err, result)
        if err or not result then
          vim.notify(
            "💡 No code actions available",
            vim.log.levels.INFO,
            { title = "Lightbulb", timeout = 1200 }
          )
          return
        end
  
        local count = #result
        if count == 0 then
          vim.notify(
            "💡 No code actions at cursor",
            vim.log.levels.INFO,
            { title = "Lightbulb", timeout = 1200 }
          )
        else
          local lines = {
            string.format("💡 %d code action(s) available:", count),
          }
          for i, action in ipairs(result) do
            if i <= 8 then
              table.insert(lines, string.format(
                "  %d. %s%s",
                i,
                action.title,
                action.isPreferred and " ⭐" or ""
              ))
            end
          end
          if count > 8 then
            table.insert(lines, string.format("  … and %d more", count - 8))
          end
          vim.notify(
            table.concat(lines, "\n"),
            vim.log.levels.INFO,
            { title = "Code Actions" }
          )
        end
      end
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "kosayoda/nvim-lightbulb",
      event        = { "LspAttach" },
      dependencies = { "neovim/nvim-lspconfig" },
  
      keys = {
        {
          "<leader>la",
          trigger_code_action(),
          mode   = { "n", "v" },
          desc   = "💡 Code Actions",
          silent = true,
        },
        {
          "<leader>lA",
          quick_fix,
          mode   = "n",
          desc   = "💡 Quick Fix (preferred)",
          silent = true,
        },
        {
          "<leader>l?",
          show_action_count,
          mode   = "n",
          desc   = "💡 Action Count",
          silent = true,
        },
      },
  
      opts = {
        -- ── Priority ─────────────────────────────────────────────────────────
        priority         = 10,
  
        -- ── Sign column ───────────────────────────────────────────────────────
        sign = {
          enabled        = true,
          -- Icon shown in sign column when actions are available
          text           = "💡",
          lens_text      = "🔍",
          hl             = "LightBulbSign",
        },
  
        -- ── Virtual text ──────────────────────────────────────────────────────
        virtual_text = {
          enabled        = false,   -- sign column is cleaner; enable if preferred
          text           = " 💡",
          pos            = "eol",
          hl             = "LightBulbVirtualText",
          hl_mode        = "combine",
        },
  
        -- ── Float window ─────────────────────────────────────────────────────
        float = {
          enabled        = false,
          text           = "💡",
          win_opts       = {
            border       = "rounded",
            focusable    = false,
          },
        },
  
        -- ── Status text (for custom statusline) ────────────────────────────────
        status_text = {
          enabled        = true,
          text           = "💡",
          text_unavailable = "",
          hl             = "LightBulbStatus",
        },
  
        -- ── Number line highlight ──────────────────────────────────────────────
        number = {
          enabled        = false,
          hl             = "LightBulbNumHl",
        },
  
        -- ── Line highlight ─────────────────────────────────────────────────────
        line = {
          enabled        = false,
          hl             = "LightBulbLine",
        },
  
        -- ── Autocmd trigger ───────────────────────────────────────────────────
        autocmd = {
          enabled        = true,
          -- Trigger on cursor position change in normal mode
          pattern        = { "*.lua", "*.py", "*.rs", "*.go", "*.ts",
                             "*.js", "*.tsx", "*.jsx", "*.c", "*.cpp",
                             "*.java", "*.kt", "*.hs", "*.ex", "*.exs",
                             "*.zig", "*.gleam", "*.nix", "*.fish",
                             "*.sh", "*.bash", "*.toml", "*.json", "*.yaml" },
          events         = { "CursorHold", "CursorHoldI" },
        },
  
        -- ── Ignore non-supported diagnostics ──────────────────────────────────
        ignore = {
          clients        = {},
          ft             = {
            "alpha", "dashboard", "neo-tree", "Trouble", "trouble",
            "lazy", "mason", "TelescopePrompt", "fzf",
            "help", "man", "notify", "toggleterm",
          },
        },
  
        -- ── Action kinds to hide (don't show 💡 for these) ──────────────────
        action_kinds     = nil,   -- nil = show for all kinds
      },
  
      config = function(_, opts)
        require("nvim-lightbulb").setup(opts)
  
        setup_highlights()
  
        -- ── Register sign ─────────────────────────────────────────────────────
        vim.fn.sign_define("LightBulbSign", {
          text   = opts.sign.text,
          texthl = opts.sign.hl,
          numhl  = "LightBulbNumHl",
        })
  
        -- ── Expose statusline component ────────────────────────────────────────
        _G.AshLightbulbStatus = function()
          local ok, lb = pcall(require, "nvim-lightbulb")
          if not ok then return "" end
          local st = lb.get_status_text()
          return st ~= "" and (" " .. st .. " ") or ""
        end
  
        local aug = vim.api.nvim_create_augroup("AshLightbulb", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify(
              "💡 Lightbulb highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Lightbulb", timeout = 1200 }
            )
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "💡 Lightbulb loaded — sign: " .. opts.sign.text,
            vim.log.levels.DEBUG,
            { title = "ASH Lightbulb" }
          )
        end
      end,
    },
  }