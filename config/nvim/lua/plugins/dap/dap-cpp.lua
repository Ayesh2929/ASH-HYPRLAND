-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ⚙️  DAP-CPP — ULTRA C/C++ DEBUGGER v5.0 OMEGA                            ║
-- ║   CodeLLDB · cpptools · CMake · Makefile · address sanitizer · core dumps      ║
-- ║   GDB · LLDB · multi-target · remote · ASH theme-synced                        ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
  local hl = vim.api.nvim_set_hl

  hl(0, "DapCppSegfault",       { bold = true, fg = "#f38ba8", bg = "#2d1b1e" })
  hl(0, "DapCppAssertion",      { bold = true, fg = "#f9e2af"                 })
  hl(0, "DapCppUndefined",      { bold = true, fg = "#f38ba8"                 })
  hl(0, "DapCppHeapError",      { bold = true, fg = "#fab387"                 })
  hl(0, "DapCppTemplate",       { italic = true, fg = "#89b4fa"               })
  hl(0, "DapCppPointer",        { fg = "#94e2d5"                              })
  hl(0, "DapCppNullPtr",        { bold = true, fg = "#f38ba8"                 })
  hl(0, "DapCppSanitizerError", { bold = true, fg = "#f38ba8"                 })

  local ok, ash = pcall(require, "ash.theme")
  if ok and ash.palette then
    local p = ash.palette
    if p.red    then
      hl(0, "DapCppSegfault",       { bold = true, fg = p.red, bg = p.surface0 or "#2d1b1e" })
      hl(0, "DapCppUndefined",      { bold = true, fg = p.red })
      hl(0, "DapCppNullPtr",        { bold = true, fg = p.red })
      hl(0, "DapCppSanitizerError", { bold = true, fg = p.red })
    end
    if p.yellow then hl(0, "DapCppAssertion", { bold = true, fg = p.yellow }) end
    if p.peach  then hl(0, "DapCppHeapError", { bold = true, fg = p.peach  }) end
    if p.blue   then hl(0, "DapCppTemplate",  { italic = true, fg = p.blue }) end
    if p.teal   then hl(0, "DapCppPointer",   { fg = p.teal                }) end
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 ENVIRONMENT DETECTION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function find_codelldb()
  local mason_base = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension"
  local adapter    = mason_base .. "/adapter/codelldb"
  local lib        = mason_base .. "/lldb/lib/liblldb"
  local ext        = vim.fn.has("mac") == 1 and ".dylib" or ".so"
  return { adapter = adapter, lib = lib .. ext }
end

local function find_cpptools()
  local cpptools = vim.fn.stdpath("data")
    .. "/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7"
  return vim.fn.executable(cpptools) == 1 and cpptools or nil
end

-- Find CMake build directory
local function find_cmake_build()
  local cwd     = vim.fn.getcwd()
  local builds  = {
    cwd .. "/build",
    cwd .. "/build/Debug",
    cwd .. "/cmake-build-debug",
    cwd .. "/.build",
  }
  for _, dir in ipairs(builds) do
    if vim.fn.isdirectory(dir) == 1 then return dir end
  end
  return cwd .. "/build"
end

-- Find executable in build directory
local function find_executable()
  local build = find_cmake_build()
  local bins  = vim.fn.glob(build .. "/*", false, true)

  bins = vim.tbl_filter(function(f)
    -- Exclude directories and non-executables
    return vim.fn.getfperm(f):sub(3, 3) == "x"
      and vim.fn.isdirectory(f) == 0
  end, bins)

  if #bins == 1 then return bins[1] end
  if #bins > 1 then
    -- Show picker
    local choice
    vim.ui.select(
      vim.tbl_map(function(f) return vim.fn.fnamemodify(f, ":t") end, bins),
      { prompt = "⚙️  Select binary: " },
      function(_, idx) if idx then choice = bins[idx] end end
    )
    return choice
  end

  return vim.fn.input("Binary: ", build .. "/", "file")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📦 PLUGIN SPEC
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  {
    "mfussenegger/nvim-dap",
    ft = { "c", "cpp", "cuda", "objc", "objcpp" },

    keys = {
      {
        "<leader>dcr",
        function()
          local dap = require("dap")
          local bin = find_executable()
          if not bin or bin == "" then return end
          dap.run({
            name    = "⚙️  Run: " .. vim.fn.fnamemodify(bin, ":t"),
            type    = "codelldb",
            request = "launch",
            program = bin,
            cwd     = vim.fn.getcwd(),
            stopOnEntry = false,
          })
        end,
        ft     = { "c", "cpp" },
        desc   = "⚙️  DAP C/C++: Run auto-detected binary",
        silent = true,
      },
      {
        "<leader>dca",
        function()
          local dap = require("dap")
          local bin = find_executable()
          if not bin or bin == "" then return end

          -- Ask for sanitizer
          vim.ui.select(
            { "None", "AddressSanitizer", "UndefinedBehaviorSanitizer", "ThreadSanitizer", "MemorySanitizer" },
            { prompt = "⚙️  Sanitizer: " },
            function(choice)
              if not choice or choice == "None" then return end
              local asan_map = {
                AddressSanitizer         = "ASAN_OPTIONS=detect_leaks=1",
                UndefinedBehaviorSanitizer = "UBSAN_OPTIONS=print_stacktrace=1",
                ThreadSanitizer          = "TSAN_OPTIONS=second_deadlock_stack=1",
                MemorySanitizer          = "MSAN_OPTIONS=poison_in_dtor=1",
              }
              dap.run({
                name    = "⚙️  ASan: " .. vim.fn.fnamemodify(bin, ":t"),
                type    = "codelldb",
                request = "launch",
                program = bin,
                cwd     = vim.fn.getcwd(),
                env     = { [asan_map[choice]:match("^([^=]+)")] = asan_map[choice]:match("=(.+)$") },
                stopOnEntry = false,
              })
            end
          )
        end,
        ft     = { "c", "cpp" },
        desc   = "⚙️  DAP C/C++: Run with sanitizer",
        silent = true,
      },
      {
        "<leader>dci",
        function()
          local codelldb = find_codelldb()
          local cpptools = find_cpptools()
          vim.notify(
            table.concat({
              "⚙️  C/C++ Debug Info",
              "──────────────────────────────────",
              string.format("  CodeLLDB:  %s", codelldb.adapter),
              string.format("  liblldb:   %s", codelldb.lib),
              string.format("  cpptools:  %s", cpptools or "(not installed)"),
              string.format("  Build dir: %s", find_cmake_build()),
              string.format("  Compiler:  %s", vim.fn.trim(vim.fn.system("cc --version 2>/dev/null | head -1"))),
            }, "\n"),
            vim.log.levels.INFO,
            { title = "DAP C/C++" }
          )
        end,
        ft     = { "c", "cpp" },
        desc   = "⚙️  DAP C/C++: Debug info",
        silent = true,
      },
    },

    config = function()
      local dap      = require("dap")
      local codelldb = find_codelldb()
      local cpptools = find_cpptools()

      -- ── Adapters ──────────────────────────────────────────────────────────
      dap.adapters.codelldb = {
        type    = "server",
        port    = "${port}",
        host    = "127.0.0.1",
        executable = {
          command = codelldb.adapter,
          args    = { "--port", "${port}" },
        },
      }

      if cpptools then
        dap.adapters.cppdbg = {
          id   = "cppdbg",
          type = "executable",
          command = cpptools,
        }
      end

      -- ── Launch configs (shared between C and C++) ─────────────────────────
      local common_configs = {
        {
          name    = "⚙️  Launch: auto-detect binary",
          type    = "codelldb",
          request = "launch",
          program = find_executable,
          cwd     = "${workspaceFolder}",
          stopOnEntry = false,
        },
        {
          name    = "⚙️  Launch: manual binary",
          type    = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Binary: ", find_cmake_build() .. "/", "file")
          end,
          cwd     = "${workspaceFolder}",
          stopOnEntry = false,
          args    = function()
            return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
          end,
        },
        {
          name    = "⚙️  Launch: core dump",
          type    = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Binary: ", find_cmake_build() .. "/", "file")
          end,
          coreFile = function()
            return vim.fn.input("Core file: ", "/tmp/core.", "file")
          end,
          cwd  = "${workspaceFolder}",
        },
        {
          name    = "⚙️  Attach: process",
          type    = "codelldb",
          request = "attach",
          pid     = require("dap.utils").pick_process,
          cwd     = "${workspaceFolder}",
        },
        {
          name    = "⚙️  Attach: remote GDB",
          type    = "cppdbg",
          request = "launch",
          MIMode  = "gdb",
          miDebuggerServerAddress = function()
            return vim.fn.input("GDB server [localhost:1234]: ", "localhost:1234")
          end,
          miDebuggerPath = vim.fn.trim(vim.fn.system("which gdb 2>/dev/null")),
          program = function()
            return vim.fn.input("Binary: ", find_cmake_build() .. "/", "file")
          end,
          cwd     = "${workspaceFolder}",
          setupCommands = {
            { text = "-enable-pretty-printing", ignoreFailures = true },
            { text = "set print object on",     ignoreFailures = true },
          },
        },
        {
          name    = "⚙️  Launch: with AddressSanitizer",
          type    = "codelldb",
          request = "launch",
          program = find_executable,
          cwd     = "${workspaceFolder}",
          env     = { ASAN_OPTIONS = "detect_leaks=1:abort_on_error=1" },
          stopOnEntry = false,
        },
      }

      dap.configurations.c   = common_configs
      dap.configurations.cpp = common_configs
      dap.configurations.cuda = vim.list_extend(vim.deepcopy(common_configs), {
        {
          name    = "⚙️  CUDA: launch",
          type    = "cuda-gdb",
          request = "launch",
          program = find_executable,
          cwd     = "${workspaceFolder}",
        },
      })

      setup_highlights()

      local aug = vim.api.nvim_create_augroup("AshDapCpp", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
      vim.api.nvim_create_autocmd("User", {
        group   = aug,
        pattern = "AshThemeChanged",
        callback = function()
          setup_highlights()
          vim.notify("⚙️  DAP C/C++ highlights synced", vim.log.levels.INFO,
            { title = "ASH DAP C/C++", timeout = 1200 })
        end,
      })

      if vim.g.ash_debug then
        vim.notify("⚙️  DAP C/C++ loaded — CodeLLDB + cpptools",
          vim.log.levels.DEBUG, { title = "ASH DAP C/C++" })
      end
    end,
  },
}