-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║     ⌨️  BETTER-ESCAPE — ULTRA ESC REMAPPER v5.0 OMEGA                          ║
-- ║   Blazing-fast jk/jj → Esc · zero-timeout · mode-aware · no lag               ║
-- ║   terminal · insert · visual · command · operator-pending modes                 ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📖 OPERATION REFERENCE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
--  INSERT MODE      jk / jj / kj  → <Esc>  (no cursor jump)
--  TERMINAL MODE    jk / jj       → <C-\><C-n>  (exit terminal insert)
--  VISUAL MODE      jk            → <Esc>  (exit visual)
--  CMD MODE         jk            → <C-c>  (cancel command)
--  OP-PENDING       jk            → <Esc>  (cancel operator)
--
--  All mappings are configured to NOT move the cursor left (unlike raw <Esc>)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 ESCAPE ACTION BUILDERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Standard escape: return to normal mode without moving cursor left
local function escape_to_normal()
    return function()
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
        "n",
        false
      )
    end
  end
  
  -- Terminal escape: exit terminal insert mode
  local function escape_terminal()
    return function()
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
        "n",
        false
      )
    end
  end
  
  -- Command escape: cancel command line input
  local function escape_cmdline()
    return function()
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<C-c>", true, false, true),
        "n",
        false
      )
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "max397574/better-escape.nvim",
      event  = "InsertEnter",
  
      opts = {
        -- ── Timeout ─────────────────────────────────────────────────────────
        -- Time (ms) to wait for the full escape sequence
        -- Lower = faster, but more chance of conflict with real typing
        timeout = vim.o.timeoutlen,
  
        -- ── Default mappings ──────────────────────────────────────────────────
        default_mappings = false,
  
        -- ── Mappings ──────────────────────────────────────────────────────────
        -- Format: { mode: { first_key: { second_key: action } } }
        mappings = {
          -- ── Insert mode ─────────────────────────────────────────────────────
          i = {
            j = {
              -- jk → Esc (most common home-row escape)
              k = function()
                -- Move cursor one character back to avoid "jk" appearing
                local cur = vim.api.nvim_win_get_cursor(0)
                if cur[2] > 0 then
                  vim.api.nvim_win_set_cursor(0, { cur[1], cur[2] - 1 })
                end
                return "<Esc>"
              end,
              -- jj → Esc (alternative)
              j = function()
                local cur = vim.api.nvim_win_get_cursor(0)
                if cur[2] > 0 then
                  vim.api.nvim_win_set_cursor(0, { cur[1], cur[2] - 1 })
                end
                return "<Esc>"
              end,
            },
            k = {
              -- kj → Esc (reverse alternative)
              j = function()
                local cur = vim.api.nvim_win_get_cursor(0)
                if cur[2] > 0 then
                  vim.api.nvim_win_set_cursor(0, { cur[1], cur[2] - 1 })
                end
                return "<Esc>"
              end,
            },
          },
  
          -- ── Terminal mode ────────────────────────────────────────────────────
          t = {
            j = {
              k = "<C-\\><C-n>",
              j = "<C-\\><C-n>",
            },
          },
  
          -- ── Visual mode ──────────────────────────────────────────────────────
          v = {
            j = {
              k = "<Esc>",
            },
          },
  
          -- ── Select mode ──────────────────────────────────────────────────────
          s = {
            j = {
              k = "<Esc>",
            },
          },
  
          -- ── Command mode ─────────────────────────────────────────────────────
          c = {
            j = {
              k = "<C-c>",
            },
          },
  
          -- ── Operator-pending ─────────────────────────────────────────────────
          o = {
            j = {
              k = "<Esc>",
            },
          },
        },
      },
  
      config = function(_, opts)
        require("better_escape").setup(opts)
  
        -- ── Additional ergonomic escape helpers ────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshBetterEscape", { clear = true })
  
        -- Caps-Lock alternative: <C-[> already works as Esc in most terminals
        -- Map <C-c> in insert mode to NOT yank (common footgun)
        vim.keymap.set("i", "<C-c>", "<Esc>", {
          silent  = true,
          noremap = true,
          desc    = "⌨️  Ctrl-C as Esc (no yank)",
        })
  
        -- Ensure <Esc> in terminal exits insert mode properly
        vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", {
          silent  = true,
          noremap = true,
          desc    = "⌨️  Double-Esc: exit terminal",
        })
  
        -- Clear search highlight on escape in normal mode
        vim.keymap.set("n", "<Esc>", function()
          vim.cmd("nohlsearch")
          -- Clear any floating notification
          pcall(function() require("notify").dismiss({ silent = true, pending = false }) end)
        end, {
          silent  = true,
          noremap = true,
          desc    = "⌨️  Esc: clear highlights",
        })
  
        -- ASH hot-reload: no-op (no highlights to manage)
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            -- Reload mappings to ensure timeout matches any changes
            local be = require("better_escape")
            if be.load then be.load() end
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "⌨️  Better-escape loaded — mappings: jk/jj/kj → Esc",
            vim.log.levels.DEBUG,
            { title = "ASH Better-Escape" }
          )
        end
      end,
    },
  }