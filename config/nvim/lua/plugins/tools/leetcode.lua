-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🎯 LEETCODE — ULTRA COMPETITIVE CODING v5.0 OMEGA                        ║
-- ║   Problem browser · multi-language · test runner · submission · stats         ║
-- ║   daily challenge · contest · ASH theme-synced                                 ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Difficulty badges ──────────────────────────────────────────────────────
    hl(0, "LeetCodeEasy",          { bold = true,   fg = "#9ece6a" })
    hl(0, "LeetCodeMedium",        { bold = true,   fg = "#f9e2af" })
    hl(0, "LeetCodeHard",          { bold = true,   fg = "#f38ba8" })
  
    -- ── Status icons ─────────────────────────────────────────────────────────
    hl(0, "LeetCodeAccepted",      { bold = true,   fg = "#9ece6a" })
    hl(0, "LeetCodeWrongAnswer",   { bold = true,   fg = "#f38ba8" })
    hl(0, "LeetCodeTimeLimitExceeded",{ bold = true, fg = "#f9e2af" })
    hl(0, "LeetCodeRuntime",       { bold = true,   fg = "#7aa2f7" })
    hl(0, "LeetCodeMemory",        { bold = true,   fg = "#cba6f7" })
    hl(0, "LeetCodeTested",        { bold = true,   fg = "#94e2d5" })
  
    -- ── UI chrome ─────────────────────────────────────────────────────────────
    hl(0, "LeetCodeNormal",        { link = "NormalFloat"   })
    hl(0, "LeetCodeBorder",        { link = "FloatBorder"   })
    hl(0, "LeetCodeTitle",         { bold = true,   fg = "#7aa2f7" })
    hl(0, "LeetCodeTag",           { italic = true, fg = "#cba6f7" })
    hl(0, "LeetCodeDate",          { italic = true, fg = "#7dcfff" })
    hl(0, "LeetCodeCompletion",    { bold = true,   fg = "#9ece6a" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green  then
        hl(0, "LeetCodeEasy",     { bold = true, fg = p.green  })
        hl(0, "LeetCodeAccepted", { bold = true, fg = p.green  })
      end
      if p.yellow then hl(0, "LeetCodeMedium",  { bold = true, fg = p.yellow }) end
      if p.red    then
        hl(0, "LeetCodeHard",        { bold = true, fg = p.red })
        hl(0, "LeetCodeWrongAnswer", { bold = true, fg = p.red })
      end
      if p.blue   then
        hl(0, "LeetCodeTitle",   { bold = true, fg = p.blue })
        hl(0, "LeetCodeRuntime", { bold = true, fg = p.blue })
      end
      if p.mauve  then hl(0, "LeetCodeTag",    { italic = true, fg = p.mauve }) end
      if p.teal   then hl(0, "LeetCodeTested", { bold = true,   fg = p.teal  }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "kawre/leetcode.nvim",
      build        = ":TSUpdate html",
      dependencies = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-treesitter/nvim-treesitter",
        "rcarriga/nvim-notify",
        "nvim-tree/nvim-web-devicons",
      },
      cmd          = "Leet",
      event        = "VeryLazy",
  
      keys = {
        { "<leader>lc",   "<cmd>Leet<cr>",           desc = "🎯 LeetCode: Open"           },
        { "<leader>lcm",  "<cmd>Leet menu<cr>",       desc = "🎯 LeetCode: Menu"           },
        { "<leader>lcd",  "<cmd>Leet daily<cr>",      desc = "🎯 LeetCode: Daily challenge" },
        { "<leader>lcr",  "<cmd>Leet run<cr>",        desc = "🎯 LeetCode: Run"            },
        { "<leader>lcs",  "<cmd>Leet submit<cr>",     desc = "🎯 LeetCode: Submit"         },
        { "<leader>lct",  "<cmd>Leet test<cr>",       desc = "🎯 LeetCode: Test"           },
        { "<leader>lci",  "<cmd>Leet info<cr>",       desc = "🎯 LeetCode: Problem info"   },
        { "<leader>lcl",  "<cmd>Leet lang<cr>",       desc = "🎯 LeetCode: Change lang"    },
        { "<leader>lcR",  "<cmd>Leet reset<cr>",      desc = "🎯 LeetCode: Reset code"     },
        { "<leader>lch",  "<cmd>Leet hints<cr>",      desc = "🎯 LeetCode: Hints"          },
        { "<leader>lcc",  "<cmd>Leet console<cr>",    desc = "🎯 LeetCode: Console"        },
        { "<leader>lce",  "<cmd>Leet desc toggle<cr>",desc = "🎯 LeetCode: Toggle description" },
        { "<leader>lcS",  "<cmd>Leet list<cr>",       desc = "🎯 LeetCode: Problem list"   },
        { "<leader>lcq",  "<cmd>Leet tabs<cr>",       desc = "🎯 LeetCode: Tabs"           },
        { "<leader>lcP",  "<cmd>Leet pick<cr>",       desc = "🎯 LeetCode: Pick random"    },
      },
  
      opts = {
        -- ── Authentication ────────────────────────────────────────────────────
        -- Set LEETCODE_SESSION cookie in environment
        -- or use :Leet cookie to set interactively
        lang          = "python3",   -- default language
  
        -- ── Storage ───────────────────────────────────────────────────────────
        storage       = {
          home   = vim.fn.stdpath("data") .. "/leetcode",
          cache  = vim.fn.stdpath("cache") .. "/leetcode",
        },
  
        -- ── Injector: auto-insert common imports ──────────────────────────────
        injector      = {
          ["python3"] = {
            before = true,
          },
          ["cpp"] = {
            before = {
              "#include <bits/stdc++.h>",
              "using namespace std;",
            },
            after = "// @lc code=end",
          },
          ["java"] = {
            before = "import java.util.*;",
          },
        },
  
        -- ── Cache ─────────────────────────────────────────────────────────────
        cache         = {
          update_interval = 60 * 60 * 24 * 7, -- 7 days
        },
  
        -- ── Logging ───────────────────────────────────────────────────────────
        logging       = true,
  
        -- ── Hooks ─────────────────────────────────────────────────────────────
        hooks         = {
          LeetEnter = function()
            -- Enable spell check in problem description
            vim.opt_local.spell    = false
            vim.opt_local.wrap     = true
            vim.opt_local.linebreak= true
          end,
        },
  
        -- ── Picker ────────────────────────────────────────────────────────────
        picker        = { provider = "telescope" },
  
        -- ── Description window ────────────────────────────────────────────────
        description   = {
          position = "left",
          width    = 0.40,
          show_stats = true,
        },
  
        -- ── Console ───────────────────────────────────────────────────────────
        console       = {
          open_on_runcode = true,
          dir             = "row",
          size            = {
            width  = 0.7,
            height = 0.35,
          },
          result          = {
            size   = { width = 0.5 },
          },
          testcase        = {
            virt_text  = true,
            size       = { width = 0.5 },
          },
        },
  
        -- ── Keys (in-plugin) ──────────────────────────────────────────────────
        keys          = {
          toggle       = { "q" },
          confirm      = { "<CR>" },
          reset_testcases = "r",
          use_testcase = "u",
          focus_testcases= "<M-1>",
          focus_result   = "<M-2>",
        },
  
        -- ── Image support (disabled by default) ───────────────────────────────
        image_support = false,
      },
  
      config = function(_, opts)
        require("leetcode").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshLeetCode", { clear = true })
  
        -- Disable mini-plugins in leetcode panes
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "leetcode.nvim", "leetcode_ui" },
          callback = function(ev)
            vim.b[ev.buf].miniindentscope_disable = true
            vim.b[ev.buf].minianimate_disable     = true
            vim.opt_local.spell          = false
            vim.opt_local.number         = false
            vim.opt_local.relativenumber = false
          end,
        })
  
        -- Filetype for LeetCode solution files
        vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
          group   = aug,
          pattern = vim.fn.stdpath("data") .. "/leetcode/**.py",
          callback = function()
            vim.bo.filetype = "python"
            -- Auto test on save
            if vim.g.ash_leetcode_auto_test then
              vim.api.nvim_create_autocmd("BufWritePost", {
                buffer   = 0,
                once     = true,
                callback = function() vim.cmd("Leet test") end,
              })
            end
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🎯 LeetCode highlights synced", vim.log.levels.INFO,
              { title = "ASH LeetCode", timeout = 1200 })
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify("🎯 LeetCode loaded", vim.log.levels.DEBUG, { title = "ASH LeetCode" })
        end
      end,
    },
  }