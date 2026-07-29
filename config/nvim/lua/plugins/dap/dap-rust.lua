-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🦀 DAP-RUST — ULTRA RUST DEBUGGER v5.0 OMEGA                             ║
-- ║   CodeLLDB · rustaceanvim · cargo test · cargo run · macro expansion           ║
-- ║   features · workspace members · proc-macro · ASH theme-synced                 ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "DapRustCrate",       { bold = true, italic = true, fg = "#ff9e64" })
    hl(0, "DapRustTest",        { bold = true, fg = "#9ece6a"                })
    hl(0, "DapRustTestFail",    { bold = true, fg = "#f38ba8"                })
    hl(0, "DapRustBench",       { bold = true, fg = "#89b4fa"                })
    hl(0, "DapRustPanic",       { bold = true, fg = "#f38ba8", bg = "#2d1b1e" })
    hl(0, "DapRustUnsafe",      { bold = true, fg = "#f9e2af"                })
    hl(0, "DapRustMacro",       { italic = true, fg = "#cba6f7"              })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.orange then hl(0, "DapRustCrate",    { bold = true, italic = true, fg = p.orange }) end
      if p.green  then hl(0, "DapRustTest",     { bold = true, fg = p.green   }) end
      if p.red    then
        hl(0, "DapRustTestFail", { bold = true, fg = p.red })
        hl(0, "DapRustPanic",    { bold = true, fg = p.red, bg = p.surface0 or "#2d1b1e" })
      end
      if p.blue   then hl(0, "DapRustBench",   { bold = true, fg = p.blue    }) end
      if p.yellow then hl(0, "DapRustUnsafe",  { bold = true, fg = p.yellow  }) end
      if p.mauve  then hl(0, "DapRustMacro",   { italic = true, fg = p.mauve }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 RUST ENVIRONMENT DETECTION
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function find_codelldb()
    local mason_base = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension"
    local lldb_path  = mason_base .. "/adapter/codelldb"
    local lib_path   = mason_base .. "/lldb/lib/liblldb"
    local ext        = vim.fn.has("mac") == 1 and ".dylib" or ".so"
  
    return {
      codelldb  = vim.fn.executable(lldb_path)  == 1 and lldb_path  or "codelldb",
      liblldb   = lib_path .. ext,
    }
  end
  
  -- Parse Cargo.toml to get workspace members / binary targets
  local function get_cargo_targets()
    local cwd    = vim.fn.getcwd()
    local toml   = cwd .. "/Cargo.toml"
    local f      = io.open(toml, "r")
    if not f then return {} end
  
    local targets  = {}
    local content  = f:read("*a")
    f:close()
  
    -- Extract [[bin]] names
    for name in content:gmatch('%[%[bin%]%].-name%s*=%s*"([^"]+)"') do
      table.insert(targets, name)
    end
  
    -- If no explicit [[bin]], check package.name
    if #targets == 0 then
      local pkg = content:match('%[package%].-name%s*=%s*"([^"]+)"')
      if pkg then table.insert(targets, pkg) end
    end
  
    return targets
  end
  
  -- Get test function name under cursor
  local function get_test_name_at_cursor()
    local node = vim.treesitter.get_node()
    while node do
      if node:type() == "function_item" then
        -- Check for #[test] attribute in siblings
        local parent = node:parent()
        if parent then
          for child in parent:iter_children() do
            if child:type() == "attribute_item" then
              local attr_text = vim.treesitter.get_node_text(child, 0)
              if attr_text:match("#%[test%]") or attr_text:match("#%[tokio::test%]") then
                -- Get function name
                for fn_child in node:iter_children() do
                  if fn_child:type() == "identifier" then
                    return vim.treesitter.get_node_text(fn_child, 0)
                  end
                end
              end
            end
          end
        end
      end
      node = node:parent()
    end
    return nil
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART DEBUG ACTIONS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function debug_rust_test_at_cursor()
    local test = get_test_name_at_cursor()
    if not test then
      vim.notify("🦀 No #[test] function at cursor", vim.log.levels.WARN, { title = "DAP Rust" })
      return
    end
  
    -- Build the test binary first
    vim.notify(
      string.format("🦀 Building test binary for: %s", test),
      vim.log.levels.INFO,
      { title = "DAP Rust", timeout = 2000 }
    )
  
    -- Use cargo test --no-run to get binary path
    local result = vim.fn.system(
      "cargo test --no-run --message-format=json 2>/dev/null"
        .. " | jq -r 'select(.profile.test == true) | .executable' 2>/dev/null"
        .. " | head -1"
    )
    local binary = vim.fn.trim(result)
  
    if binary == "" or binary == "null" then
      -- Fallback: try to find in target/debug/deps
      binary = vim.fn.glob(
        vim.fn.getcwd() .. "/target/debug/deps/*-*[!.d]",
        false,
        true
      )[1] or ""
    end
  
    if binary == "" then
      vim.notify("🦀 Could not find test binary. Run `cargo test --no-run` first.",
        vim.log.levels.ERROR, { title = "DAP Rust" })
      return
    end
  
    require("dap").run({
      name    = "🦀 Test: " .. test,
      type    = "codelldb",
      request = "launch",
      program = binary,
      args    = { test, "--nocapture" },
      cwd     = vim.fn.getcwd(),
      stopOnEntry = false,
    })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- This file configures DAP for Rust without requiring a separate plugin.
    -- Rust DAP support is built into nvim-dap via the codelldb adapter.
    -- rustaceanvim handles the DAP config when present.
    {
      "mfussenegger/nvim-dap",
      ft = { "rust" },
  
      keys = {
        {
          "<leader>drt",
          debug_rust_test_at_cursor,
          ft     = "rust",
          desc   = "🦀 DAP Rust: Debug test at cursor",
          silent = true,
        },
        {
          "<leader>drr",
          function()
            local dap     = require("dap")
            local targets = get_cargo_targets()
            local binary
  
            if #targets == 1 then
              binary = vim.fn.getcwd() .. "/target/debug/" .. targets[1]
            elseif #targets > 1 then
              vim.ui.select(targets, { prompt = "🦀 Select binary: " }, function(choice)
                if choice then
                  binary = vim.fn.getcwd() .. "/target/debug/" .. choice
                end
              end)
            else
              binary = vim.fn.input("Binary path: ",
                vim.fn.getcwd() .. "/target/debug/", "file")
            end
  
            if not binary or binary == "" then return end
  
            dap.run({
              name    = "🦀 Run: " .. vim.fn.fnamemodify(binary, ":t"),
              type    = "codelldb",
              request = "launch",
              program = binary,
              args    = function()
                return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
              end,
              cwd     = vim.fn.getcwd(),
              stopOnEntry = false,
            })
          end,
          ft     = "rust",
          desc   = "🦀 DAP Rust: Run binary",
          silent = true,
        },
        {
          "<leader>dri",
          function()
            local paths = find_codelldb()
            local ver   = vim.fn.trim(vim.fn.system("rustc --version 2>/dev/null"))
            local cargo = vim.fn.trim(vim.fn.system("cargo --version 2>/dev/null"))
            vim.notify(
              table.concat({
                "🦀 Rust Debug Info",
                "──────────────────────────────────",
                string.format("  codelldb:  %s", paths.codelldb),
                string.format("  liblldb:   %s", paths.liblldb),
                string.format("  rustc:     %s", ver),
                string.format("  cargo:     %s", cargo),
                string.format("  RUSTUP:    %s", os.getenv("RUSTUP_HOME") or "default"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "DAP Rust" }
            )
          end,
          ft     = "rust",
          desc   = "🦀 DAP Rust: Debug info",
          silent = true,
        },
      },
  
      config = function()
        local dap   = require("dap")
        local paths = find_codelldb()
  
        -- ── Register codelldb adapter ─────────────────────────────────────────
        dap.adapters.codelldb = {
          type    = "server",
          port    = "${port}",
          host    = "127.0.0.1",
          executable = {
            command = paths.codelldb,
            args    = { "--port", "${port}" },
          },
        }
  
        -- ── Rust launch configurations ────────────────────────────────────────
        dap.configurations.rust = {
          {
            name    = "🦀 Launch: auto-detect binary",
            type    = "codelldb",
            request = "launch",
            program = function()
              local cwd     = vim.fn.getcwd()
              local targets = get_cargo_targets()
  
              -- Build first
              vim.notify("🦀 Building…", vim.log.levels.INFO,
                { title = "DAP Rust", timeout = 30000 })
              vim.fn.system("cargo build 2>&1")
  
              if vim.v.shell_error ~= 0 then
                vim.notify("🦀 Build failed", vim.log.levels.ERROR, { title = "DAP Rust" })
                return vim.fn.input("Binary path: ", cwd .. "/target/debug/", "file")
              end
  
              if #targets == 1 then
                return cwd .. "/target/debug/" .. targets[1]
              end
  
              return vim.fn.input("Binary path: ", cwd .. "/target/debug/", "file")
            end,
            cwd         = "${workspaceFolder}",
            stopOnEntry = false,
            args        = {},
          },
          {
            name    = "🦀 Launch: manual binary",
            type    = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input(
                "Binary: ",
                vim.fn.getcwd() .. "/target/debug/",
                "file"
              )
            end,
            cwd         = "${workspaceFolder}",
            stopOnEntry = false,
            args        = function()
              return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
            end,
          },
          {
            name    = "🦀 Launch: with env",
            type    = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input("Binary: ", vim.fn.getcwd() .. "/target/debug/", "file")
            end,
            cwd     = "${workspaceFolder}",
            env     = function()
              local envs = {}
              local env_str = vim.fn.input("Env vars (KEY=VAL,...): ")
              for pair in env_str:gmatch("[^,]+") do
                local k, v = pair:match("^([^=]+)=(.+)$")
                if k then envs[k] = v end
              end
              return envs
            end,
            stopOnEntry = false,
          },
          {
            name    = "🦀 Attach: local process",
            type    = "codelldb",
            request = "attach",
            pid     = require("dap.utils").pick_process,
            cwd     = "${workspaceFolder}",
          },
          {
            name    = "🦀 Attach: remote",
            type    = "codelldb",
            request = "attach",
            connect = {
              url  = function() return vim.fn.input("URL [tcp://localhost:12345]: ", "tcp://localhost:12345") end,
            },
            cwd     = "${workspaceFolder}",
          },
        }
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshDapRust", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🦀 DAP Rust highlights synced", vim.log.levels.INFO,
              { title = "ASH DAP Rust", timeout = 1200 })
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("🦀 DAP Rust loaded — CodeLLDB: %s", paths.codelldb),
            vim.log.levels.DEBUG,
            { title = "ASH DAP Rust" }
          )
        end
      end,
    },
  }