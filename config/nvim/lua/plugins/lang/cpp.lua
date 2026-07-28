-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ⚙️  C/C++ — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                            ║
-- ║   clangd · clang-format · cmake · make · header/source toggle                 ║
-- ║   sanitizers · conan · vcpkg · ASH theme-synced                               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── clangd semantic tokens ────────────────────────────────────────────────
    hl(0, "@lsp.type.class.cpp",           { bold = true,   fg = "#f9e2af"  })
    hl(0, "@lsp.type.struct.cpp",          { bold = true,   fg = "#f9e2af"  })
    hl(0, "@lsp.type.enum.cpp",            { fg = "#89dceb"                 })
    hl(0, "@lsp.type.enumMember.cpp",      { fg = "#89dceb"                 })
    hl(0, "@lsp.type.function.cpp",        { fg = "#89b4fa"                 })
    hl(0, "@lsp.type.method.cpp",          { fg = "#89b4fa"                 })
    hl(0, "@lsp.type.typeParameter.cpp",   { italic = true, fg = "#94e2d5"  })
    hl(0, "@lsp.type.parameter.cpp",       { italic = true, fg = "#c8c8c8"  })
    hl(0, "@lsp.type.macro.cpp",           { bold = true,   fg = "#cba6f7"  })
    hl(0, "@lsp.type.concept.cpp",         { bold = true,   italic = true, fg = "#94e2d5" })
    hl(0, "@lsp.type.namespace.cpp",       { italic = true, fg = "#89b4fa"  })
    hl(0, "@lsp.type.operator.cpp",        { fg = "#89b4fa"                 })
    hl(0, "@lsp.type.builtinType.cpp",     { fg = "#89dceb"                 })
    hl(0, "@lsp.typemod.function.virtual.cpp",  { italic = true, fg = "#89b4fa" })
    hl(0, "@lsp.typemod.method.virtual.cpp",    { italic = true, fg = "#89b4fa" })
    hl(0, "@lsp.typemod.variable.static.cpp",   { italic = true              })
    hl(0, "@lsp.typemod.type.defaultLibrary.cpp",{ fg = "#89dceb"            })
  
    -- Same for C
    for _, kind in ipairs({ "class", "struct", "function", "method", "macro",
                            "namespace", "parameter", "enumMember", "builtinType" }) do
      local attrs = vim.api.nvim_get_hl(0, { name = "@lsp.type." .. kind .. ".cpp" })
      if next(attrs) then
        hl(0, "@lsp.type." .. kind .. ".c", attrs)
      end
    end
  
    -- ── Template / concept colours ─────────────────────────────────────────────
    hl(0, "CppTemplate",       { italic = true, fg = "#89b4fa" })
    hl(0, "CppConcept",        { bold = true,   fg = "#94e2d5" })
    hl(0, "CppUnsafe",         { bold = true,   fg = "#f9e2af" })
    hl(0, "CppPreprocessor",   { fg = "#cba6f7"                })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.yellow then
        hl(0, "@lsp.type.class.cpp",  { bold = true, fg = p.yellow })
        hl(0, "@lsp.type.struct.cpp", { bold = true, fg = p.yellow })
      end
      if p.blue   then hl(0, "@lsp.type.function.cpp",  { fg = p.blue   }) end
      if p.teal   then
        hl(0, "@lsp.type.typeParameter.cpp", { italic = true, fg = p.teal })
        hl(0, "@lsp.type.concept.cpp",       { bold = true, italic = true, fg = p.teal })
        hl(0, "CppConcept",                  { bold = true, fg = p.teal })
      end
      if p.mauve  then
        hl(0, "@lsp.type.macro.cpp",   { bold = true, fg = p.mauve })
        hl(0, "CppPreprocessor",       { fg = p.mauve })
      end
      if p.blue   then hl(0, "@lsp.type.namespace.cpp", { italic = true, fg = p.blue }) end
      if p.yellow then hl(0, "CppUnsafe", { bold = true, fg = p.yellow }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 C/C++ UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Toggle between header and source file
  local function switch_header_source()
    local file = vim.api.nvim_buf_get_name(0)
    local ext  = file:match("%.([^%.]+)$")
  
    local companions = {
      h   = { "c", "cpp", "cc", "cxx" },
      hpp = { "cpp", "cc", "cxx" },
      hxx = { "cpp", "cc", "cxx" },
      hh  = { "cc", "cpp" },
      c   = { "h" },
      cpp = { "h", "hpp", "hxx" },
      cc  = { "h", "hh", "hpp" },
      cxx = { "h", "hpp", "hxx" },
    }
  
    local stem    = file:match("(.+)%.[^%.]+$")
    local targets = companions[ext]
  
    if not targets then
      vim.notify("⚙️  No companion extension for ." .. ext, vim.log.levels.WARN,
        { title = "C/C++" })
      return
    end
  
    for _, target_ext in ipairs(targets) do
      local candidate = stem .. "." .. target_ext
      if vim.fn.filereadable(candidate) == 1 then
        vim.cmd("edit " .. candidate)
        return
      end
    end
  
    vim.notify("⚙️  No companion file found for " .. vim.fn.fnamemodify(file, ":t"),
      vim.log.levels.WARN, { title = "C/C++" })
  end
  
  -- Get C++ standard from CMakeLists.txt
  local function get_cpp_standard()
    local cmake = vim.fn.getcwd() .. "/CMakeLists.txt"
    local f     = io.open(cmake, "r")
    if not f then return "20" end
  
    local content = f:read("*a")
    f:close()
  
    return content:match("CMAKE_CXX_STANDARD%s+(%d+)")
      or content:match("set%(CXX_STANDARD%s+(%d+)")
      or "20"
  end
  
  -- Build with CMake
  local function cmake_build()
    local build_dir = vim.fn.getcwd() .. "/build"
  
    if vim.fn.isdirectory(build_dir) == 0 then
      vim.notify("⚙️  Creating build directory…", vim.log.levels.INFO,
        { title = "CMake" })
      vim.fn.mkdir(build_dir, "p")
      vim.fn.system("cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
    end
  
    local ok_term, term = pcall(require, "toggleterm.terminal")
    if ok_term then
      term.Terminal:new({
        cmd          = "cmake --build build --parallel $(nproc)",
        direction    = "float",
        display_name = "⚙️  CMake Build",
        float_opts   = { border = "rounded" },
        close_on_exit = false,
      }):toggle()
    else
      vim.cmd("split term://cmake --build build --parallel")
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- ── Treesitter grammars ────────────────────────────────────────────────────────
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        vim.list_extend(opts.ensure_installed, { "c", "cpp", "cmake", "make" })
      end,
    },
  
    -- ── clangd_extensions.nvim ────────────────────────────────────────────────────
    {
      "p00f/clangd_extensions.nvim",
      ft           = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
      dependencies = { "neovim/nvim-lspconfig" },
      lazy         = true,
  
      opts = {
        inlay_hints = {
          inline        = vim.fn.has("nvim-0.10") == 1,
          only_current_line = false,
          only_current_line_autocmd = { "CursorHold" },
          show_parameter_hints     = true,
          parameter_hints_prefix   = "  ",
          other_hints_prefix        = "  ",
          max_len_align            = false,
          max_len_align_padding    = 1,
          right_align              = false,
          right_align_padding      = 7,
          highlight                = "Comment",
          priority                 = 100,
        },
        ast = {
          role_icons = {
            type              = "󰉿",
            declaration       = "󰙠",
            expression        = "󰁔",
            specifier         = "󰌖",
            statement         = "󰅩",
            ["template argument"] = "󰊄",
          },
          kind_icons = {
            Compound     = "󰗚",
            Recovery     = "󰡅",
            TranslationUnit = "󰈙",
            PackExpansion = "󰝮",
            TemplateTypeParm = "󰊄",
            TemplateTemplateParm = "󰊄",
            TemplateParamObject  = "󰊄",
          },
          highlights = {
            detail = "Comment",
          },
        },
        memory_usage = { border = "rounded" },
        symbol_info  = { border = "rounded" },
      },
  
      config = function(_, opts)
        require("clangd_extensions").setup(opts)
  
        -- Setup LSP
        require("lspconfig").clangd.setup({
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--completion-style=detailed",
            "--header-insertion=iwyu",
            "--pch-storage=memory",
            "--suggest-missing-includes",
            "--malloc-trim",
            "--enable-config",
            "--offset-encoding=utf-16",
            string.format("--std=c++%s", get_cpp_standard()),
            "--all-scopes-completion",
            "--fallback-style=llvm",
          },
          on_attach = function(client, bufnr)
            -- Enable inlay hints
            if client.supports_method("textDocument/inlayHint") then
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            end
  
            local global = _G.AshLspOnAttach
            if global then global(client, bufnr) end
          end,
          capabilities = vim.tbl_deep_extend("force",
            _G.AshLspCapabilities or vim.lsp.protocol.make_client_capabilities(),
            { offsetEncoding = { "utf-16" } }
          ),
          init_options = {
            usePlaceholders  = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
          root_dir = require("lspconfig.util").root_pattern(
            "compile_commands.json", "compile_flags.txt",
            ".clangd", "CMakeLists.txt", "Makefile", ".git"
          ),
          single_file_support = true,
        })
      end,
    },
  
    -- ── cmake-tools.nvim ──────────────────────────────────────────────────────────
    {
      "Civitasv/cmake-tools.nvim",
      ft    = { "c", "cpp", "cmake" },
      event = "BufRead CMakeLists.txt",
      dependencies = { "nvim-lua/plenary.nvim" },
  
      opts = {
        cmake_command               = "cmake",
        ctest_command               = "ctest",
        cmake_build_directory       = "build",
        cmake_build_directory_prefix= "cmake_build_",
        cmake_generate_options      = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
        cmake_soft_link_compile_commands = true,
        cmake_compile_commands_from_lsp = false,
        cmake_kits_path             = nil,
        cmake_build_options         = {},
        cmake_console_output_mode   = "toggleterm",
        cmake_runner                = { name = "terminal", opts = {} },
        cmake_notification_mode     = "cmake",
        cmake_virtual_text_support  = true,
        cmake_always_use_terminal   = false,
        cmake_terminal_opts         = {
          name            = "Main Terminal",
          prefix_name     = "[CMakeTools]: ",
          split_direction = "horizontal",
          split_size      = 11,
          single_terminal_per_instance = true,
          single_terminal_per_tab      = true,
          keep_terminal_static_location= true,
          auto_scroll     = true,
        },
        cmake_executor              = {
          name  = "toggleterm",
          opts  = {
            direction         = "float",
            auto_scroll       = true,
            singleton         = true,
          },
        },
      },
  
      keys = {
        { "<leader>cgg", "<cmd>CMakeGenerate<cr>",       ft = { "c", "cpp" }, desc = "⚙️  CMake: Generate"        },
        { "<leader>cgb", cmake_build,                    ft = { "c", "cpp" }, desc = "⚙️  CMake: Build"           },
        { "<leader>cgr", "<cmd>CMakeRun<cr>",            ft = { "c", "cpp" }, desc = "⚙️  CMake: Run"             },
        { "<leader>cgd", "<cmd>CMakeDebug<cr>",          ft = { "c", "cpp" }, desc = "⚙️  CMake: Debug"           },
        { "<leader>cgt", "<cmd>CMakeRunTest<cr>",        ft = { "c", "cpp" }, desc = "⚙️  CMake: Test"            },
        { "<leader>cgc", "<cmd>CMakeClean<cr>",          ft = { "c", "cpp" }, desc = "⚙️  CMake: Clean"           },
        { "<leader>cgs", "<cmd>CMakeTargetSettings<cr>", ft = { "c", "cpp" }, desc = "⚙️  CMake: Target settings" },
        { "<leader>cga", "<cmd>CMakeSelectBuildTarget<cr>", ft = { "c", "cpp" }, desc = "⚙️  CMake: Select target" },
        { "<leader>cgp", "<cmd>CMakeSelectBuildPreset<cr>", ft = { "c", "cpp" }, desc = "⚙️  CMake: Select preset" },
      },
    },
  
    -- ── C/C++ utilities plugin ─────────────────────────────────────────────────────
    {
      "nvim-lua/plenary.nvim",
      ft = { "c", "cpp", "cuda", "objc", "objcpp" },
  
      keys = {
        { "<leader>ch",  switch_header_source, ft = { "c", "cpp" }, desc = "⚙️  C/C++: Toggle header/source" },
        {
          "<leader>ci",
          function()
            local std    = get_cpp_standard()
            local ver    = vim.fn.trim(vim.fn.system("clangd --version 2>/dev/null | head -1"))
            local cmake  = vim.fn.executable("cmake") == 1
              and vim.fn.trim(vim.fn.system("cmake --version 2>/dev/null | head -1")) or "not found"
            vim.notify(
              table.concat({
                "⚙️  C/C++ Environment",
                "──────────────────────────────────",
                string.format("  C++ Std:  C++%s", std),
                string.format("  clangd:   %s", ver),
                string.format("  cmake:    %s", cmake),
                string.format("  make:     %s", vim.fn.executable("make") == 1 and "✅" or "⭕"),
                string.format("  ninja:    %s", vim.fn.executable("ninja") == 1 and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "C/C++ Info" }
            )
          end,
          ft   = { "c", "cpp" },
          desc = "⚙️  C/C++: Environment info",
        },
      },
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshCpp", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "c", "cpp", "cuda", "objc", "objcpp" },
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 4
            vim.opt_local.tabstop     = 4
            vim.opt_local.softtabstop = 4
            vim.opt_local.textwidth   = 100
            vim.opt_local.colorcolumn = "101"
            vim.opt_local.cinoptions  = "g0,N-s"
            -- Auto-create compile_commands symlink
            local ccdb = vim.fn.getcwd() .. "/build/compile_commands.json"
            local link = vim.fn.getcwd() .. "/compile_commands.json"
            if vim.fn.filereadable(ccdb) == 1 and vim.fn.filereadable(link) == 0 then
              vim.fn.system("ln -s " .. ccdb .. " " .. link)
            end
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("⚙️  C/C++ highlights synced", vim.log.levels.INFO,
              { title = "ASH C/C++", timeout = 1200 })
          end,
        })
      end,
    },
  }