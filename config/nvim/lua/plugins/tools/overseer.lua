-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ⚙️  OVERSEER — ULTRA TASK RUNNER v5.0 OMEGA                              ║
-- ║   Task templates · parallel · serial · watch · output · DAP integration       ║
-- ║   make · cargo · npm · gradle · custom · ASH theme-synced                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Task status ────────────────────────────────────────────────────────────
    hl(0, "OverseerPENDING",   { bold = true,   fg = "#9399b2" })
    hl(0, "OverseerWAITING",   { bold = true,   fg = "#7dcfff" })
    hl(0, "OverseerRUNNING",   { bold = true,   fg = "#f9e2af" })
    hl(0, "OverseerSUCCESS",   { bold = true,   fg = "#9ece6a" })
    hl(0, "OverseerFAILURE",   { bold = true,   fg = "#f38ba8" })
    hl(0, "OverseerCANCELED",  { bold = true,   fg = "#9399b2" })
    hl(0, "OverseerDISPOSED",  { fg = "#9399b2"                })
  
    -- ── Panel chrome ──────────────────────────────────────────────────────────
    hl(0, "OverseerNormal",    { link = "NormalFloat"   })
    hl(0, "OverseerBorder",    { link = "FloatBorder"   })
    hl(0, "OverseerTask",      { bold = true,   fg = "#7aa2f7" })
    hl(0, "OverseerTaskBorder",{ fg = "#414868"                })
    hl(0, "OverseerOutput",    { link = "Normal"         })
    hl(0, "OverseerComponent", { italic = true, fg = "#cba6f7" })
    hl(0, "OverseerField",     { fg = "#89b4fa"                })
  
    -- ── Task list ─────────────────────────────────────────────────────────────
    hl(0, "OverseerSUCCESSHl",  { bold = true, fg = "#9ece6a", bg = "#1a2b1a" })
    hl(0, "OverseerFAILUREHl",  { bold = true, fg = "#f38ba8", bg = "#2d1b1e" })
    hl(0, "OverseerRUNNINGHl",  { bold = true, fg = "#f9e2af", bg = "#2d2a1e" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green  then hl(0, "OverseerSUCCESS", { bold = true, fg = p.green  }) end
      if p.red    then hl(0, "OverseerFAILURE", { bold = true, fg = p.red    }) end
      if p.yellow then hl(0, "OverseerRUNNING", { bold = true, fg = p.yellow }) end
      if p.blue   then
        hl(0, "OverseerTask",  { bold = true, fg = p.blue })
        hl(0, "OverseerField", { fg = p.blue              })
      end
      if p.mauve  then hl(0, "OverseerComponent", { italic = true, fg = p.mauve }) end
      if p.cyan   then hl(0, "OverseerWAITING",   { bold = true,   fg = p.cyan  }) end
      local dim = p.overlay0 or "#9399b2"
      hl(0, "OverseerPENDING", { bold = true, fg = dim })
      hl(0, "OverseerCANCELED",{ bold = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎯 STATUS ICONS — Nerd Font v3
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local STATUS_ICONS = {
    PENDING  = "󰋖 ",
    WAITING  = "󰔟 ",
    RUNNING  = "󰑖 ",
    SUCCESS  = "󰄬 ",
    FAILURE  = "󰅖 ",
    CANCELED = "󰜺 ",
    DISPOSED = "󰅗 ",
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 CUSTOM TASK TEMPLATES — ASH-specific tasks
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function register_ash_templates(overseer)
    -- ── ASH: Apply theme ──────────────────────────────────────────────────────
    overseer.register_template({
      name     = "⚡ ASH: Apply theme",
      tags     = { "ash", "theme" },
      condition = { callback = function() return vim.fn.executable("ash") == 1 end },
      params = {
        theme = {
          type    = "string",
          name    = "Theme name",
          default = "",
          optional= true,
        },
      },
      builder = function(params)
        local cmd = params.theme ~= "" and { "ash", "theme", "apply", params.theme }
          or { "ash", "theme", "pick" }
        return {
          cmd   = cmd,
          name  = "ASH: Apply theme",
          cwd   = vim.fn.getcwd(),
        }
      end,
    })
  
    -- ── ASH: Doctor ──────────────────────────────────────────────────────────
    overseer.register_template({
      name    = "⚡ ASH: Doctor",
      tags    = { "ash", "diagnostic" },
      condition = { callback = function() return vim.fn.executable("ash") == 1 end },
      builder = function()
        return {
          cmd  = { "ash", "doctor" },
          name = "ASH: Doctor",
        }
      end,
    })
  
    -- ── Git: commit with message ───────────────────────────────────────────────
    overseer.register_template({
      name = "󰊢 Git: commit",
      tags = { "git" },
      condition = {
        callback = function()
          return vim.fn.finddir(".git", vim.fn.getcwd() .. ";") ~= ""
        end,
      },
      params = {
        message = {
          type    = "string",
          name    = "Commit message",
          default = "",
        },
        all = {
          type    = "boolean",
          name    = "Stage all",
          default = false,
        },
      },
      builder = function(params)
        local cmd = { "git" }
        if params.all then
          return {
            cmd  = { "sh", "-c", "git add -A && git commit -m " .. vim.fn.shellescape(params.message) },
            name = "Git: commit (stage all)",
          }
        end
        vim.list_extend(cmd, { "commit", "-m", params.message })
        return {
          cmd  = cmd,
          name = "Git: commit",
        }
      end,
    })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART ACTIONS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function run_task()
    local ok, overseer = pcall(require, "overseer")
    if not ok then return end
    overseer.run_template({}, function(task)
      if task then
        overseer.open({ enter = false, direction = "bottom" })
      end
    end)
  end
  
  local function show_task_status()
    local ok, overseer = pcall(require, "overseer")
    if not ok then return end
  
    local tasks = overseer.list_tasks({ recent_first = true })
    if #tasks == 0 then
      vim.notify("⚙️  No tasks running", vim.log.levels.INFO, { title = "Overseer" })
      return
    end
  
    local lines = { "⚙️  Recent Tasks:", "─────────────────────────────────" }
    for i, task in ipairs(tasks) do
      if i > 8 then break end
      local icon = STATUS_ICONS[task.status] or "? "
      table.insert(lines, string.format(
        "  %s %-30s  %s",
        icon,
        task.name:sub(1, 30),
        task.status
      ))
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Overseer" })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "stevearc/overseer.nvim",
      cmd  = {
        "OverseerOpen",  "OverseerClose",  "OverseerToggle",
        "OverseerSaveBundle", "OverseerLoadBundle", "OverseerDeleteBundle",
        "OverseerRunCmd", "OverseerRun",   "OverseerInfo",
        "OverseerBuild",  "OverseerQuickAction", "OverseerTaskAction",
        "OverseerClearCache",
      },
      event = "VeryLazy",
  
      keys = {
        { "<leader>ot",  "<cmd>OverseerToggle<cr>",      desc = "⚙️  Overseer: Toggle"        },
        { "<leader>or",  run_task,                        desc = "⚙️  Overseer: Run task"      },
        { "<leader>oR",  "<cmd>OverseerRun<cr>",          desc = "⚙️  Overseer: Run (picker)"  },
        { "<leader>ob",  "<cmd>OverseerBuild<cr>",        desc = "⚙️  Overseer: Build"         },
        { "<leader>oa",  "<cmd>OverseerTaskAction<cr>",   desc = "⚙️  Overseer: Task action"   },
        { "<leader>oq",  "<cmd>OverseerQuickAction<cr>",  desc = "⚙️  Overseer: Quick action"  },
        { "<leader>oi",  "<cmd>OverseerInfo<cr>",         desc = "⚙️  Overseer: Info"          },
        { "<leader>os",  show_task_status,                desc = "⚙️  Overseer: Status"        },
        { "<leader>oS",  "<cmd>OverseerSaveBundle<cr>",   desc = "⚙️  Overseer: Save bundle"   },
        { "<leader>oL",  "<cmd>OverseerLoadBundle<cr>",   desc = "⚙️  Overseer: Load bundle"   },
        { "<leader>oC",  "<cmd>OverseerClearCache<cr>",   desc = "⚙️  Overseer: Clear cache"   },
      },
  
      opts = {
        -- ── Strategy ────────────────────────────────────────────────────────────
        strategy = {
          "toggleterm",
          use_shell = false,
          direction = "horizontal",
          highlights = nil,
          auto_scroll= true,
          close_on_exit = false,
          open_on_start = true,
          hidden     = false,
          quit_on_exit = "never",
        },
  
        -- ── Templates to load ──────────────────────────────────────────────────
        templates = {
          "builtin",
          "user.run_script",
        },
  
        -- ── Auto detect make / cargo / npm ─────────────────────────────────────
        auto_detect_success_color = true,
  
        -- ── Dap: integrate with nvim-dap ───────────────────────────────────────
        dap  = true,
  
        -- ── Task list ──────────────────────────────────────────────────────────
        task_list = {
          default_detail  = 1,
          max_width       = { 100, 0.2 },
          min_width       = { 40,  0.1 },
          separator       = "─────────────────────────────",
          direction       = "bottom",
          bindings        = {
            ["?"]           = "ShowHelp",
            ["g?"]          = "ShowHelp",
            ["<CR>"]        = "RunAction",
            ["<C-e>"]       = "Edit",
            ["o"]           = "Open",
            ["<C-v>"]       = "OpenVsplit",
            ["<C-s>"]       = "OpenSplit",
            ["<C-f>"]       = "OpenFloat",
            ["<C-q>"]       = "OpenQuickFix",
            ["p"]           = "TogglePreview",
            ["<C-l>"]       = "IncreaseDetail",
            ["<C-h>"]       = "DecreaseDetail",
            ["L"]           = "IncreaseAllDetail",
            ["H"]           = "DecreaseAllDetail",
            ["["]           = "DecreaseWidth",
            ["]"]           = "IncreaseWidth",
            ["{"]           = "PrevTask",
            ["}"]           = "NextTask",
            ["<C-k>"]       = "ScrollOutputUp",
            ["<C-j>"]       = "ScrollOutputDown",
            ["q"]           = "Close",
          },
        },
  
        -- ── Form ───────────────────────────────────────────────────────────────
        form = {
          border     = "rounded",
          zindex     = 40,
          min_width  = 80,
          max_width  = 0.9,
          min_height = 10,
          max_height = 0.9,
          win_opts   = { winblend = 0 },
        },
  
        -- ── Confirm ────────────────────────────────────────────────────────────
        confirm = {
          border   = "rounded",
          zindex   = 40,
          min_width= 20,
          max_width= 0.5,
          min_height=3,
          max_height=0.9,
          win_opts = { winblend = 0 },
        },
  
        -- ── Task editor ────────────────────────────────────────────────────────
        task_editor = {
          bindings = {
            i = {
              ["<CR>"]    = "NextOrSubmit",
              ["<C-s>"]   = "Submit",
              ["<Tab>"]   = "Next",
              ["<S-Tab>"] = "Prev",
              ["<C-c>"]   = "Cancel",
            },
            n = {
              ["<CR>"]    = "NextOrSubmit",
              ["<C-s>"]   = "Submit",
              ["<Tab>"]   = "Next",
              ["<S-Tab>"] = "Prev",
              ["q"]       = "Cancel",
              ["?"]       = "ShowHelp",
            },
          },
        },
  
        -- ── Task win ───────────────────────────────────────────────────────────
        task_win = {
          padding    = 2,
          border     = "rounded",
          win_opts   = { winblend = 0 },
        },
  
        -- ── Help win ───────────────────────────────────────────────────────────
        help_win = {
          border   = "rounded",
          win_opts = {},
        },
  
        -- ── Log ───────────────────────────────────────────────────────────────
        log = {
          {
            type  = "echo",
            level = vim.log.levels.WARN,
          },
          {
            type     = "file",
            filename = vim.fn.stdpath("data") .. "/overseer.log",
            level    = vim.log.levels.DEBUG,
          },
        },
  
        -- ── Components ────────────────────────────────────────────────────────
        component_aliases = {
          default = {
            { "display_duration",   detail_level = 2 },
            "on_output_summarize",
            "on_exit_set_status",
            { "on_complete_notify",
              system     = "unfocused",
              on_change  = true,
            },
            "on_complete_dispose",
          },
          default_vscode = {
            "default",
            "on_result_diagnostics",
            "on_result_diagnostics_quickfix",
          },
        },
  
        -- ── Bundles ───────────────────────────────────────────────────────────
        bundles = {
          save_task_opts = {
            bundleable = true,
          },
          autostart_on_load = false,
        },
  
        -- ── Run template ──────────────────────────────────────────────────────
        run_template_opts = { first_match = false },
  
        -- ── Status column icons ────────────────────────────────────────────────
        -- Customised via highlights above
      },
  
      config = function(_, opts)
        local overseer = require("overseer")
        overseer.setup(opts)
  
        -- Register ASH custom templates
        register_ash_templates(overseer)
  
        setup_highlights()
  
        -- ── Neotest integration ────────────────────────────────────────────────
        -- Allow neotest to use overseer as its executor
        local ok_neo, neotest = pcall(require, "neotest")
        if ok_neo then
          pcall(function()
            neotest.setup({
              consumers = {
                overseer = require("neotest.consumers.overseer"),
              },
            })
          end)
        end
  
        -- ── Expose statusline component ────────────────────────────────────────
        _G.AshOverseerStatus = function()
          local ok, ov = pcall(require, "overseer")
          if not ok then return "" end
  
          local tasks = ov.list_tasks({ unique = false, recent_first = true })
          if #tasks == 0 then return "" end
  
          local counts = { RUNNING = 0, SUCCESS = 0, FAILURE = 0 }
          for _, t in ipairs(tasks) do
            if counts[t.status] ~= nil then
              counts[t.status] = counts[t.status] + 1
            end
          end
  
          local parts = {}
          if counts.RUNNING > 0 then
            table.insert(parts, STATUS_ICONS.RUNNING .. counts.RUNNING)
          end
          if counts.FAILURE > 0 then
            table.insert(parts, STATUS_ICONS.FAILURE .. counts.FAILURE)
          end
          if counts.SUCCESS > 0 then
            table.insert(parts, STATUS_ICONS.SUCCESS .. counts.SUCCESS)
          end
  
          return #parts > 0 and (" " .. table.concat(parts, " ") .. " ") or ""
        end
  
        local aug = vim.api.nvim_create_augroup("AshOverseer", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("⚙️  Overseer highlights synced", vim.log.levels.INFO,
              { title = "ASH Overseer", timeout = 1200 })
          end,
        })
  
        -- Disable mini-plugins in task list pane
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "OverseerList",
          callback = function(ev)
            vim.b[ev.buf].miniindentscope_disable = true
            vim.b[ev.buf].minianimate_disable     = true
            vim.opt_local.number         = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn     = "no"
            vim.opt_local.spell          = false
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify("⚙️  Overseer loaded", vim.log.levels.DEBUG, { title = "ASH Overseer" })
        end
      end,
    },
  }