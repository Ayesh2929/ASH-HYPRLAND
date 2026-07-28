-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐚 DAP-BASH — ULTRA BASH/SHELL DEBUGGER v5.0 OMEGA                       ║
-- ║   bash-debug-adapter · step debugging · variable watch · trap analysis         ║
-- ║   shellcheck integration · shfmt · multi-shell · ASH theme-synced              ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "DapBashShebang",      { bold = true, fg = "#9ece6a"             })
    hl(0, "DapBashVar",          { fg = "#89b4fa"                          })
    hl(0, "DapBashPipe",         { bold = true, fg = "#cba6f7"             })
    hl(0, "DapBashTrap",         { bold = true, fg = "#f9e2af"             })
    hl(0, "DapBashError",        { bold = true, fg = "#f38ba8"             })
    hl(0, "DapBashSuccess",      { bold = true, fg = "#9ece6a"             })
    hl(0, "DapBashSubshell",     { italic = true, fg = "#94e2d5"           })
    hl(0, "DapBashExpansion",    { fg = "#fab387"                          })
    hl(0, "DapBashFunction",     { bold = true, fg = "#89b4fa"             })
    hl(0, "DapBashBuiltin",      { italic = true, fg = "#cba6f7"           })
    hl(0, "DapBashExitCode",     { bold = true, fg = "#f9e2af"             })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green  then
        hl(0, "DapBashShebang",  { bold = true, fg = p.green })
        hl(0, "DapBashSuccess",  { bold = true, fg = p.green })
      end
      if p.blue   then
        hl(0, "DapBashVar",      { fg = p.blue })
        hl(0, "DapBashFunction", { bold = true, fg = p.blue })
      end
      if p.mauve  then
        hl(0, "DapBashPipe",     { bold = true, fg = p.mauve })
        hl(0, "DapBashBuiltin",  { italic = true, fg = p.mauve })
      end
      if p.yellow then
        hl(0, "DapBashTrap",     { bold = true, fg = p.yellow })
        hl(0, "DapBashExitCode", { bold = true, fg = p.yellow })
      end
      if p.red    then hl(0, "DapBashError",    { bold = true, fg = p.red    }) end
      if p.teal   then hl(0, "DapBashSubshell", { italic = true, fg = p.teal }) end
      if p.peach  then hl(0, "DapBashExpansion",{ fg = p.peach               }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 ENVIRONMENT DETECTION
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function find_bash_debug_adapter()
    local mason_path = vim.fn.stdpath("data")
      .. "/mason/packages/bash-debug-adapter/bash-debug-adapter"
    if vim.fn.executable(mason_path) == 1 then return mason_path end
  
    local which = vim.fn.trim(vim.fn.system("which bash-debug-adapter 2>/dev/null"))
    if which ~= "" then return which end
  
    return nil
  end
  
  local function find_bash_debug_pkg()
    local mason_base = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter"
    if vim.fn.isdirectory(mason_base) == 1 then return mason_base end
    return nil
  end
  
  -- Detect shell type from shebang
  local function detect_shell()
    local buf     = vim.api.nvim_get_current_buf()
    local first   = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    local shebang = first:match("^#!(.+)$")
  
    if not shebang then return "bash" end
  
    if shebang:match("bash")    then return "bash"   end
    if shebang:match("zsh")     then return "zsh"    end
    if shebang:match("sh")      then return "sh"     end
    if shebang:match("ksh")     then return "ksh"    end
    if shebang:match("fish")    then return "fish"   end
    if shebang:match("python")  then return "python" end
  
    return "bash"
  end
  
  -- Get available shells on system
  local function get_available_shells()
    local shells = {}
    local candidates = { "bash", "sh", "zsh", "ksh", "dash" }
    for _, sh in ipairs(candidates) do
      if vim.fn.executable(sh) == 1 then
        table.insert(shells, vim.fn.exepath(sh))
      end
    end
    return shells
  end
  
  -- Validate bash script with shellcheck
  local function run_shellcheck()
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
      vim.notify("🐚 No file to check", vim.log.levels.WARN, { title = "ShellCheck" })
      return
    end
  
    if vim.fn.executable("shellcheck") ~= 1 then
      vim.notify("🐚 shellcheck not found (install via mason)", vim.log.levels.WARN,
        { title = "ShellCheck" })
      return
    end
  
    local result  = vim.fn.system("shellcheck --format=gcc " .. vim.fn.shellescape(file) .. " 2>&1")
    local has_err = vim.v.shell_error ~= 0
  
    if not has_err then
      vim.notify("🐚 ShellCheck: ✅ No issues found!", vim.log.levels.INFO,
        { title = "ShellCheck", timeout = 2000 })
      return
    end
  
    -- Parse results into quickfix
    local qflist = {}
    for line in result:gmatch("[^\n]+") do
      local file2, lnum, col, sev, msg = line:match("^(.+):(%d+):(%d+): (%w+): (.+)$")
      if file2 then
        table.insert(qflist, {
          filename = file2,
          lnum     = tonumber(lnum),
          col      = tonumber(col),
          type     = sev == "error" and "E" or "W",
          text     = msg,
        })
      end
    end
  
    if #qflist > 0 then
      vim.fn.setqflist(qflist)
      vim.cmd("copen")
      vim.notify(
        string.format("🐚 ShellCheck: %d issue(s) found", #qflist),
        vim.log.levels.WARN,
        { title = "ShellCheck" }
      )
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART DEBUG ACTIONS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function debug_current_script()
    local dap  = require("dap")
    local file = vim.api.nvim_buf_get_name(0)
  
    if file == "" then
      vim.notify("🐚 Save file first", vim.log.levels.WARN, { title = "DAP Bash" })
      return
    end
  
    local shell   = detect_shell()
    local adapter = find_bash_debug_adapter()
  
    if not adapter then
      vim.notify(
        "🐚 bash-debug-adapter not found. Install via Mason: :MasonInstall bash-debug-adapter",
        vim.log.levels.ERROR,
        { title = "DAP Bash" }
      )
      return
    end
  
    dap.run({
      name    = "🐚 Debug: " .. vim.fn.fnamemodify(file, ":t"),
      type    = "bash",
      request = "launch",
      program = file,
      cwd     = vim.fn.fnamemodify(file, ":h"),
      pathBashDebug   = find_bash_debug_pkg(),
      pathBash        = vim.fn.exepath(shell) ~= "" and vim.fn.exepath(shell) or shell,
      pathCat         = vim.fn.exepath("cat")    or "cat",
      pathMkfifo      = vim.fn.exepath("mkfifo") or "mkfifo",
      pathPkill       = vim.fn.exepath("pkill")  or "pkill",
      env             = {
        PATH = os.getenv("PATH") or "",
        HOME = os.getenv("HOME") or "",
      },
      args            = {},
      terminalKind    = "integrated",
      showDebugOutput = true,
      trace           = false,
    })
  end
  
  local function debug_with_args()
    local dap  = require("dap")
    local file = vim.api.nvim_buf_get_name(0)
  
    vim.ui.input({ prompt = "🐚 Script args: " }, function(args_str)
      if not args_str then return end
      local shell = detect_shell()
  
      dap.run({
        name    = "🐚 Debug with args: " .. vim.fn.fnamemodify(file, ":t"),
        type    = "bash",
        request = "launch",
        program = file,
        cwd     = vim.fn.fnamemodify(file, ":h"),
        pathBashDebug   = find_bash_debug_pkg(),
        pathBash        = vim.fn.exepath(shell) or shell,
        pathCat         = "cat",
        pathMkfifo      = "mkfifo",
        pathPkill       = "pkill",
        args            = vim.split(args_str, " ", { trimempty = true }),
        terminalKind    = "integrated",
      })
    end)
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "mfussenegger/nvim-dap",
      ft = { "sh", "bash", "zsh" },
  
      keys = {
        {
          "<leader>dbr",
          debug_current_script,
          ft     = { "sh", "bash", "zsh" },
          desc   = "🐚 DAP Bash: Debug current script",
          silent = true,
        },
        {
          "<leader>dba",
          debug_with_args,
          ft     = { "sh", "bash", "zsh" },
          desc   = "🐚 DAP Bash: Debug with args",
          silent = true,
        },
        {
          "<leader>dbs",
          run_shellcheck,
          ft     = { "sh", "bash", "zsh" },
          desc   = "🐚 DAP Bash: Run ShellCheck",
          silent = true,
        },
        {
          "<leader>dbi",
          function()
            local adapter = find_bash_debug_adapter()
            local shells  = get_available_shells()
            local shell   = detect_shell()
            vim.notify(
              table.concat({
                "🐚 Bash Debug Info",
                "──────────────────────────────────",
                string.format("  Adapter:   %s", adapter or "(not installed)"),
                string.format("  Shell:     %s", shell),
                string.format("  Available: %s", table.concat(shells, ", ")),
                string.format("  shellcheck:%s", vim.fn.executable("shellcheck") == 1 and "✅" or "⭕"),
                string.format("  shfmt:     %s", vim.fn.executable("shfmt") == 1 and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "DAP Bash" }
            )
          end,
          ft     = { "sh", "bash", "zsh" },
          desc   = "🐚 DAP Bash: Debug info",
          silent = true,
        },
      },
  
      config = function()
        local dap     = require("dap")
        local adapter = find_bash_debug_adapter()
        local pkg     = find_bash_debug_pkg()
  
        -- ── Register adapter ──────────────────────────────────────────────────
        if adapter then
          dap.adapters.bash = {
            type    = "executable",
            command = adapter,
            args    = {},
          }
          -- Alias for sh files
          dap.adapters.sh = dap.adapters.bash
        else
          vim.notify(
            "🐚 bash-debug-adapter not found. Install: :MasonInstall bash-debug-adapter",
            vim.log.levels.WARN,
            { title = "DAP Bash" }
          )
        end
  
        -- ── Launch configurations ─────────────────────────────────────────────
        local bash_path = vim.fn.exepath("bash") or "bash"
        local sh_path   = vim.fn.exepath("sh")   or "sh"
  
        local function make_config(name, prog, shell_path, extra)
          return vim.tbl_extend("force", {
            name             = name,
            type             = "bash",
            request          = "launch",
            program          = prog,
            cwd              = "${fileDirname}",
            pathBashDebug    = pkg,
            pathBash         = shell_path,
            pathCat          = "cat",
            pathMkfifo       = "mkfifo",
            pathPkill        = "pkill",
            env              = {},
            args             = {},
            terminalKind     = "integrated",
            showDebugOutput  = false,
            trace            = false,
          }, extra or {})
        end
  
        dap.configurations.sh = {
          make_config("🐚 Launch: current file (bash)", "${file}", bash_path, {}),
          make_config("🐚 Launch: current file (sh)",   "${file}", sh_path,   {}),
          make_config("🐚 Launch: with args", "${file}", bash_path, {
            args = function()
              return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
            end,
          }),
          make_config("🐚 Launch: with env", "${file}", bash_path, {
            env = function()
              local envs   = {}
              local env_str = vim.fn.input("Env (KEY=VAL,...): ")
              for pair in env_str:gmatch("[^,]+") do
                local k, v = pair:match("^([^=]+)=(.+)$")
                if k then envs[k] = v end
              end
              return envs
            end,
          }),
          make_config("🐚 Launch: verbose trace", "${file}", bash_path, {
            trace           = true,
            showDebugOutput = true,
          }),
          make_config("🐚 Attach: running process", nil, bash_path, {
            request   = "attach",
            pid       = require("dap.utils").pick_process,
            program   = nil,
          }),
        }
  
        dap.configurations.bash = dap.configurations.sh
  
        -- Zsh uses the same adapter (bash compatibility mode)
        dap.configurations.zsh = vim.tbl_map(function(cfg)
          local c = vim.deepcopy(cfg)
          c.pathBash = vim.fn.exepath("zsh") or "zsh"
          c.name     = c.name:gsub("bash", "zsh"):gsub("sh", "zsh")
          return c
        end, dap.configurations.sh)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshDapBash", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🐚 DAP Bash highlights synced", vim.log.levels.INFO,
              { title = "ASH DAP Bash", timeout = 1200 })
          end,
        })
  
        -- ── Auto-run shellcheck on save ────────────────────────────────────────
        if vim.g.ash_shellcheck_on_save then
          vim.api.nvim_create_autocmd("BufWritePost", {
            group   = aug,
            pattern = { "*.sh", "*.bash" },
            callback = function()
              if vim.fn.executable("shellcheck") == 1 then
                run_shellcheck()
              end
            end,
          })
        end
  
        if vim.g.ash_debug then
          vim.notify(
            string.format(
              "🐚 DAP Bash loaded — adapter: %s",
              adapter and "✅" or "⭕ (not installed)"
            ),
            vim.log.levels.DEBUG,
            { title = "ASH DAP Bash" }
          )
        end
      end,
    },
  }