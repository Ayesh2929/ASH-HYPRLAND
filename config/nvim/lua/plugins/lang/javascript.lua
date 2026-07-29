-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ⚡ JAVASCRIPT — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                         ║
-- ║   eslint · biome · prettier · JSDoc · package.json · node debugging            ║
-- ║   npm scripts · import resolution · JSX · ASH theme-synced                    ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── JavaScript-specific tokens ────────────────────────────────────────────
    hl(0, "@lsp.type.class.javascript",        { bold = true,   fg = "#f9e2af"  })
    hl(0, "@lsp.type.function.javascript",     { fg = "#89b4fa"                 })
    hl(0, "@lsp.type.method.javascript",       { fg = "#89b4fa"                 })
    hl(0, "@lsp.type.variable.javascript",     { fg = "#cdd6f4"                 })
    hl(0, "@lsp.type.parameter.javascript",    { italic = true, fg = "#c8c8c8"  })
    hl(0, "@lsp.type.property.javascript",     { fg = "#cdd6f4"                 })
    hl(0, "@lsp.typemod.function.async.javascript",{ italic = true, fg = "#89b4fa" })
  
    -- ── JSDoc ─────────────────────────────────────────────────────────────────
    hl(0, "@comment.documentation.javascript", { italic = true, fg = "#9399b2"  })
    hl(0, "@lsp.type.comment.documentation",   { italic = true, fg = "#9399b2"  })
  
    -- ── JSX ───────────────────────────────────────────────────────────────────
    hl(0, "@tag.jsx",              { bold = true, fg = "#89b4fa"    })
    hl(0, "@tag.attribute.jsx",    { italic = true, fg = "#9399b2"  })
    hl(0, "@tag.delimiter.jsx",    { fg = "#6e738d"                 })
  
    -- ── package.json / node ───────────────────────────────────────────────────
    hl(0, "JsPackageOutdated",     { bold = true, fg = "#f9e2af"    })
    hl(0, "JsPackageCurrent",      { bold = true, fg = "#9ece6a"    })
    hl(0, "JsPackageError",        { bold = true, fg = "#f38ba8"    })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.yellow then hl(0, "@lsp.type.class.javascript", { bold = true, fg = p.yellow }) end
      if p.blue   then
        hl(0, "@lsp.type.function.javascript", { fg = p.blue })
        hl(0, "@tag.jsx", { bold = true, fg = p.blue })
        hl(0, "@lsp.typemod.function.async.javascript", { italic = true, fg = p.blue })
      end
      if p.green  then hl(0, "JsPackageCurrent",  { bold = true, fg = p.green  }) end
      if p.yellow then hl(0, "JsPackageOutdated", { bold = true, fg = p.yellow }) end
      if p.red    then hl(0, "JsPackageError",    { bold = true, fg = p.red    }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 JAVASCRIPT UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function detect_package_manager()
    local cwd = vim.fn.getcwd()
    if vim.fn.filereadable(cwd .. "/pnpm-lock.yaml") == 1 then return "pnpm" end
    if vim.fn.filereadable(cwd .. "/yarn.lock")      == 1 then return "yarn" end
    if vim.fn.filereadable(cwd .. "/bun.lockb")      == 1 then return "bun"  end
    return "npm"
  end
  
  local function get_package_scripts()
    local pkg_file = vim.fn.getcwd() .. "/package.json"
    local f = io.open(pkg_file, "r")
    if not f then return {} end
  
    local content = f:read("*a")
    f:close()
  
    local ok, data = pcall(vim.fn.json_decode, content)
    if not ok or not data.scripts then return {} end
  
    local scripts = {}
    for name, cmd in pairs(data.scripts) do
      table.insert(scripts, { name = name, cmd = cmd })
    end
    table.sort(scripts, function(a, b) return a.name < b.name end)
    return scripts
  end
  
  -- Run npm/yarn/pnpm script from telescope picker
  local function run_package_script()
    local scripts = get_package_scripts()
    if #scripts == 0 then
      vim.notify("⚡ No scripts in package.json", vim.log.levels.WARN,
        { title = "JavaScript" })
      return
    end
  
    local pm = detect_package_manager()
  
    vim.ui.select(
      vim.tbl_map(function(s)
        return string.format("%-20s %s", s.name, s.cmd)
      end, scripts),
      { prompt = string.format("⚡ Run %s script: ", pm) },
      function(choice, idx)
        if not choice or not idx then return end
        local script = scripts[idx]
        local cmd    = string.format("%s run %s", pm, script.name)
  
        local ok_term, term = pcall(require, "toggleterm.terminal")
        if ok_term then
          local t = term.Terminal:new({
            cmd          = cmd,
            direction    = "float",
            display_name = "⚡ " .. pm .. " " .. script.name,
            float_opts   = { border = "rounded" },
            close_on_exit = false,
          })
          t:toggle()
        else
          vim.cmd("split term://" .. cmd)
        end
      end
    )
  end
  
  -- Open package.json in current directory
  local function open_package_json()
    local pkg = vim.fn.getcwd() .. "/package.json"
    if vim.fn.filereadable(pkg) == 1 then
      vim.cmd("edit " .. pkg)
    else
      vim.notify("⚡ No package.json found", vim.log.levels.WARN,
        { title = "JavaScript" })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- ── Treesitter: JS grammars ────────────────────────────────────────────────────
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        vim.list_extend(opts.ensure_installed, {
          "javascript", "jsdoc", "json", "jsonc",
          "tsx", "html", "css",
        })
      end,
    },
  
    -- ── package-info.nvim — package.json version display ─────────────────────────
    {
      "vuki656/package-info.nvim",
      dependencies = { "MunifTanjim/nui.nvim" },
      event        = "BufRead package.json",
  
      keys = {
        { "<leader>jpt", "<cmd>lua require('package-info').toggle()<cr>",          desc = "⚡ JS: Toggle package versions" },
        { "<leader>jpu", "<cmd>lua require('package-info').update()<cr>",          desc = "⚡ JS: Update package"          },
        { "<leader>jpd", "<cmd>lua require('package-info').delete()<cr>",          desc = "⚡ JS: Delete package"          },
        { "<leader>jpi", "<cmd>lua require('package-info').install()<cr>",         desc = "⚡ JS: Install new package"     },
        { "<leader>jpv", "<cmd>lua require('package-info').change_version()<cr>",  desc = "⚡ JS: Change version"          },
      },
  
      opts = {
        colors = {
          up_to_date    = "#9ece6a",
          outdated      = "#f9e2af",
          invalid       = "#f38ba8",
        },
        icons = {
          enable        = true,
          style         = {
            up_to_date  = "|  ",
            outdated    = "|  ",
            invalid     = "|  ",
          },
        },
        autostart         = true,
        hide_up_to_date   = false,
        hide_unstable_versions = false,
        package_manager   = detect_package_manager(),
      },
    },
  
    -- ── JS/TS keymap group + utilities ────────────────────────────────────────────
    {
      "nvim-lua/plenary.nvim",  -- dependency placeholder
      ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  
      keys = {
        -- ── Package scripts ──────────────────────────────────────────────────
        { "<leader>jsr", run_package_script, desc = "⚡ JS: Run npm script"         },
        { "<leader>jsp", open_package_json,  desc = "⚡ JS: Open package.json"       },
  
        -- ── Node.js utilities ─────────────────────────────────────────────────
        {
          "<leader>jnn",
          function()
            local file = vim.api.nvim_buf_get_name(0)
            local pm   = detect_package_manager()
            local ok_term, term = pcall(require, "toggleterm.terminal")
            if ok_term then
              term.Terminal:new({
                cmd          = "node " .. vim.fn.shellescape(file),
                direction    = "float",
                display_name = "⚡ node " .. vim.fn.fnamemodify(file, ":t"),
                float_opts   = { border = "rounded" },
                close_on_exit = false,
              }):toggle()
            else
              vim.cmd("split term://node " .. vim.fn.shellescape(file))
            end
          end,
          ft   = { "javascript", "javascriptreact" },
          desc = "⚡ JS: Run file with node",
        },
  
        -- ── Info ──────────────────────────────────────────────────────────────
        {
          "<leader>jii",
          function()
            local pm       = detect_package_manager()
            local scripts  = get_package_scripts()
            local node_ver = vim.fn.trim(vim.fn.system("node --version 2>/dev/null"))
            local pm_ver   = vim.fn.trim(vim.fn.system(pm .. " --version 2>/dev/null"))
  
            vim.notify(
              table.concat({
                "⚡ JavaScript Environment",
                "──────────────────────────────────",
                string.format("  Node:    %s", node_ver),
                string.format("  PM:      %s %s", pm, pm_ver),
                string.format("  Scripts: %d defined", #scripts),
                string.format("  Biome:   %s",
                  vim.fn.filereadable(vim.fn.getcwd() .. "/biome.json") == 1
                    and "✅ biome.json found" or "⭕"),
                string.format("  ESLint:  %s",
                  vim.fn.filereadable(vim.fn.getcwd() .. "/eslint.config.js") == 1
                    or vim.fn.filereadable(vim.fn.getcwd() .. "/.eslintrc.js") == 1
                    and "✅ config found" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "JavaScript" }
            )
          end,
          ft   = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          desc = "⚡ JS: Environment info",
        },
      },
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshJavaScript", { clear = true })
  
        -- Set JS filetype options
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "javascript", "javascriptreact" },
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.textwidth   = 100
            vim.opt_local.colorcolumn = "101"
  
            -- Fold by treesitter
            vim.opt_local.foldmethod = "expr"
            vim.opt_local.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
            vim.opt_local.foldlevel  = 99
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("⚡ JavaScript highlights synced", vim.log.levels.INFO,
              { title = "ASH JS", timeout = 1200 })
          end,
        })
  
        -- Auto-open package-info on package.json
        vim.api.nvim_create_autocmd("BufRead", {
          group   = aug,
          pattern = "package.json",
          callback = function()
            vim.defer_fn(function()
              local ok, pi = pcall(require, "package-info")
              if ok then pi.show({ force = true }) end
            end, 300)
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("⚡ JavaScript loaded — PM: %s", detect_package_manager()),
            vim.log.levels.DEBUG,
            { title = "ASH JavaScript" }
          )
        end
      end,
    },
  }