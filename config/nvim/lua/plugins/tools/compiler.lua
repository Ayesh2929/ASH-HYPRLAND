-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🏗️  COMPILER — ULTRA BUILD SYSTEM v5.0 OMEGA                             ║
-- ║   compiler.nvim · multi-language build · run · make · cmake · cargo           ║
-- ║   async · quickfix · error parsing · ASH theme-synced                         ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "CompilerNormal",        { link = "NormalFloat"   })
    hl(0, "CompilerBorder",        { link = "FloatBorder"   })
    hl(0, "CompilerTitle",         { bold = true, fg = "#7aa2f7" })
    hl(0, "CompilerSuccess",       { bold = true, fg = "#9ece6a" })
    hl(0, "CompilerError",         { bold = true, fg = "#f38ba8" })
    hl(0, "CompilerWarning",       { bold = true, fg = "#f9e2af" })
    hl(0, "CompilerRunning",       { bold = true, fg = "#f9e2af" })
    hl(0, "CompilerPlay",          { bold = true, fg = "#9ece6a" })
    hl(0, "CompilerStop",          { bold = true, fg = "#f38ba8" })
    hl(0, "CompilerTaskList",      { link = "Normal"         })
    hl(0, "CompilerSelected",      { link = "CursorLine"     })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then hl(0, "CompilerTitle",   { bold = true, fg = p.blue   }) end
      if p.green  then
        hl(0, "CompilerSuccess", { bold = true, fg = p.green })
        hl(0, "CompilerPlay",    { bold = true, fg = p.green })
      end
      if p.red    then
        hl(0, "CompilerError",   { bold = true, fg = p.red })
        hl(0, "CompilerStop",    { bold = true, fg = p.red })
      end
      if p.yellow then hl(0, "CompilerWarning", { bold = true, fg = p.yellow }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 BUILD SYSTEM DETECTION
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function detect_build_system()
    local cwd   = vim.fn.getcwd()
    local files = {
      { "Cargo.toml",      "cargo",  { "cargo", "build" } },
      { "CMakeLists.txt",  "cmake",  { "cmake", "--build", "build" } },
      { "Makefile",        "make",   { "make" } },
      { "build.zig",       "zig",    { "zig", "build" } },
      { "build.gradle",    "gradle", { "gradle", "build" } },
      { "pom.xml",         "maven",  { "mvn", "package" } },
      { "package.json",    "npm",    nil },  -- handled separately
      { "go.mod",          "go",     { "go", "build", "./..." } },
      { "pyproject.toml",  "python", nil },
      { "flake.nix",       "nix",    { "nix", "build" } },
    }
  
    for _, entry in ipairs(files) do
      local fname, name, cmd = entry[1], entry[2], entry[3]
      if vim.fn.filereadable(cwd .. "/" .. fname) == 1 then
        return { name = name, cmd = cmd, file = fname }
      end
    end
  
    return nil
  end
  
  -- Async build with notification
  local function async_build(cmd, label)
    local start_time = os.time()
    vim.notify(
      string.format("🏗️  Building: %s…", label),
      vim.log.levels.INFO,
      { title = "Compiler", timeout = 2000 }
    )
  
    local qflist = {}
    local stderr  = {}
  
    local job_id = vim.fn.jobstart(cmd, {
      cwd             = vim.fn.getcwd(),
      on_stdout       = function(_, data)
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(qflist, { text = line }) end
        end
      end,
      on_stderr       = function(_, data)
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(stderr, line) end
        end
      end,
      on_exit         = function(_, code)
        local elapsed = os.time() - start_time
        local level   = code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
        local icon    = code == 0 and "✅" or "❌"
  
        vim.schedule(function()
          vim.notify(
            string.format(
              "%s Build %s in %ds: %s",
              icon,
              code == 0 and "succeeded" or "FAILED",
              elapsed,
              label
            ),
            level,
            { title = "Compiler" }
          )
  
          if code ~= 0 and #stderr > 0 then
            -- Send errors to quickfix
            local qf = vim.tbl_map(function(l)
              return { text = l, type = "E" }
            end, stderr)
            vim.fn.setqflist(qf)
            vim.cmd("copen")
          elseif #qflist > 0 then
            vim.fn.setqflist(qflist)
          end
        end)
      end,
    })
  
    if job_id <= 0 then
      vim.notify("🏗️  Failed to start: " .. table.concat(cmd, " "), vim.log.levels.ERROR,
        { title = "Compiler" })
    end
  
    return job_id
  end
  
  -- Smart build: detect and run
  local function smart_build()
    local bs = detect_build_system()
    if not bs then
      vim.notify("🏗️  No build system detected", vim.log.levels.WARN, { title = "Compiler" })
      return
    end
  
    if not bs.cmd then
      -- For npm / python, show options
      if bs.name == "npm" then
        local pm = vim.fn.filereadable(vim.fn.getcwd() .. "/pnpm-lock.yaml") == 1 and "pnpm"
          or (vim.fn.filereadable(vim.fn.getcwd() .. "/yarn.lock") == 1 and "yarn" or "npm")
        vim.ui.select(
          { "build", "test", "lint", "format", "start", "dev" },
          { prompt = string.format("🏗️  %s script: ", pm) },
          function(script)
            if script then
              async_build({ pm, "run", script }, pm .. " " .. script)
            end
          end
        )
      end
      return
    end
  
    async_build(bs.cmd, bs.name)
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "Zeioth/compiler.nvim",
      cmd          = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
      dependencies = { "stevearc/overseer.nvim", "nvim-telescope/telescope.nvim" },
      event        = "VeryLazy",
  
      keys = {
        { "<leader>co",  "<cmd>CompilerOpen<cr>",           desc = "🏗️  Compiler: Open"           },
        { "<leader>ct",  "<cmd>CompilerToggleResults<cr>",  desc = "🏗️  Compiler: Toggle results"  },
        { "<leader>cr",  "<cmd>CompilerRedo<cr>",           desc = "🏗️  Compiler: Redo"            },
        { "<leader>cb",  smart_build,                       desc = "🏗️  Compiler: Smart build"     },
        {
          "<leader>ci",
          function()
            local bs = detect_build_system()
            if bs then
              vim.notify(
                table.concat({
                  "🏗️  Build System",
                  "──────────────────────────────────",
                  string.format("  Detected:  %s (%s)", bs.name, bs.file),
                  string.format("  Command:   %s", bs.cmd and table.concat(bs.cmd, " ") or "(auto)"),
                }, "\n"),
                vim.log.levels.INFO,
                { title = "Compiler" }
              )
            else
              vim.notify("🏗️  No build system detected", vim.log.levels.WARN,
                { title = "Compiler" })
            end
          end,
          desc = "🏗️  Compiler: Info",
        },
      },
  
      opts = {
        -- ── Default mode ──────────────────────────────────────────────────────
        -- "window" | "quickfix"
        output = "window",
  
        -- ── Tasks to load ─────────────────────────────────────────────────────
        -- All overseer templates tagged "compiler" are loaded
        task_props = {
          name   = "compiler",
          params = {
            filetype = { optional = true },
          },
        },
      },
  
      config = function(_, opts)
        require("compiler").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshCompiler", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🏗️  Compiler highlights synced", vim.log.levels.INFO,
              { title = "ASH Compiler", timeout = 1200 })
          end,
        })
  
        -- Quick build keymaps per filetype
        local build_maps = {
          rust       = { "cargo", "build" },
          go         = { "go",    "build", "./..." },
          zig        = { "zig",   "build" },
          c          = { "make"            },
          cpp        = { "make"            },
          python     = { "python", "-c", "import py_compile, sys; py_compile.compile(sys.argv[1])", vim.fn.expand("%") },
        }
  
        for ft, cmd in pairs(build_maps) do
          vim.api.nvim_create_autocmd("FileType", {
            group   = aug,
            pattern = ft,
            callback = function()
              vim.keymap.set("n", "<leader>cB", function()
                async_build(cmd, ft)
              end, { buffer = true, desc = "🏗️  Build (" .. ft .. ")", silent = true })
            end,
          })
        end
      end,
    },
  }