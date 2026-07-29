-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ☕ JAVA — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                              ║
-- ║   nvim-jdtls · lombok · spring · maven · gradle · test runner                 ║
-- ║   DAP · refactor · organize imports · ASH theme-synced                        ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "@lsp.type.class.java",        { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.interface.java",    { italic = true, fg = "#94e2d5" })
    hl(0, "@lsp.type.enum.java",         { fg = "#89dceb"                })
    hl(0, "@lsp.type.enumMember.java",   { fg = "#89dceb"                })
    hl(0, "@lsp.type.annotation.java",   { italic = true, fg = "#cba6f7" })
    hl(0, "@lsp.type.function.java",     { fg = "#89b4fa"                })
    hl(0, "@lsp.type.method.java",       { fg = "#89b4fa"                })
    hl(0, "@lsp.type.parameter.java",    { italic = true, fg = "#c8c8c8" })
    hl(0, "@lsp.type.typeParameter.java",{ italic = true, fg = "#94e2d5" })
    hl(0, "@lsp.type.variable.java",     { fg = "#cdd6f4"                })
    hl(0, "@lsp.type.namespace.java",    { italic = true, fg = "#89b4fa" })
    hl(0, "@lsp.typemod.method.static.java",  { italic = true            })
    hl(0, "@lsp.typemod.variable.static.java",{ italic = true            })
    hl(0, "@lsp.typemod.variable.final.java", { bold = true              })
    hl(0, "JavaAnnotation",  { italic = true, fg = "#cba6f7"             })
    hl(0, "JavaTestPass",    { bold = true,   fg = "#9ece6a"             })
    hl(0, "JavaTestFail",    { bold = true,   fg = "#f38ba8"             })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.yellow then hl(0, "@lsp.type.class.java",     { bold = true, fg = p.yellow }) end
      if p.teal   then hl(0, "@lsp.type.interface.java", { italic = true, fg = p.teal }) end
      if p.blue   then hl(0, "@lsp.type.function.java",  { fg = p.blue               }) end
      if p.mauve  then hl(0, "@lsp.type.annotation.java",{ italic = true, fg = p.mauve }) end
      if p.green  then hl(0, "JavaTestPass",             { bold = true, fg = p.green  }) end
      if p.red    then hl(0, "JavaTestFail",             { bold = true, fg = p.red    }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 JAVA UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function get_jdtls_paths()
    local mason_base = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
    local launcher   = vim.fn.glob(mason_base .. "/plugins/org.eclipse.equinox.launcher_*.jar", false, true)[1]
    local config_os  = vim.fn.has("mac") == 1 and "mac"
      or (vim.fn.has("win32") == 1 and "win" or "linux")
    local config_dir = mason_base .. "/config_" .. config_os
  
    return {
      launcher   = launcher or "",
      config_dir = config_dir,
      workspace  = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
      lombok     = vim.fn.stdpath("data") .. "/mason/packages/jdtls/lombok.jar",
      java_debug = vim.fn.glob(
        vim.fn.stdpath("data") .. "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
        false, true
      )[1] or "",
      java_test  = vim.fn.glob(
        vim.fn.stdpath("data") .. "/mason/packages/java-test/extension/server/*.jar",
        false, true
      ),
    }
  end
  
  local function get_java_home()
    local candidates = {
      os.getenv("JAVA_HOME") or "",
      "/usr/lib/jvm/default-java",
      "/usr/lib/jvm/java-21-openjdk-amd64",
      "/usr/lib/jvm/java-17-openjdk-amd64",
      "/usr/lib/jvm/java-11-openjdk-amd64",
    }
  
    for _, path in ipairs(candidates) do
      if path ~= "" and vim.fn.executable(path .. "/bin/java") == 1 then
        return path
      end
    end
  
    local which = vim.fn.trim(vim.fn.system("which java 2>/dev/null"))
    if which ~= "" then
      -- Resolve symlink
      local real = vim.fn.trim(vim.fn.system("realpath " .. which .. " 2>/dev/null"))
      return real:match("(.+)/bin/java$") or ""
    end
  
    return ""
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "mfussenegger/nvim-jdtls",
      ft           = { "java" },
      dependencies = {
        "neovim/nvim-lspconfig",
        { "mfussenegger/nvim-dap", optional = true },
      },
  
      keys = {
        { "<leader>jo",  function() require("jdtls").organize_imports()               end, ft = "java", desc = "☕ Java: Organize imports"          },
        { "<leader>jt",  function() require("jdtls").test_class()                     end, ft = "java", desc = "☕ Java: Test class"                },
        { "<leader>jT",  function() require("jdtls").test_nearest_method()            end, ft = "java", desc = "☕ Java: Test nearest method"        },
        { "<leader>jv",  function() require("jdtls").extract_variable()               end, ft = "java", desc = "☕ Java: Extract variable"           },
        { "<leader>jV",  function() require("jdtls").extract_variable(true)           end, ft = "java", desc = "☕ Java: Extract variable (all)",   mode = "v" },
        { "<leader>jc",  function() require("jdtls").extract_constant()               end, ft = "java", desc = "☕ Java: Extract constant"           },
        { "<leader>jm",  function() require("jdtls").extract_method()                 end, ft = "java", desc = "☕ Java: Extract method",            mode = "v" },
        { "<leader>jM",  function() require("jdtls").super_implementation()           end, ft = "java", desc = "☕ Java: Super implementation"       },
        { "<leader>ji",  function() require("jdtls").add_imports()                    end, ft = "java", desc = "☕ Java: Add missing imports"        },
        { "<leader>jJ",  function() require("jdtls").update_project_config()          end, ft = "java", desc = "☕ Java: Update project config"      },
        {
          "<leader>jI",
          function()
            local paths   = get_jdtls_paths()
            local java    = get_java_home()
            local version = vim.fn.trim(vim.fn.system("java -version 2>&1 | head -1"))
            vim.notify(
              table.concat({
                "☕ Java Environment",
                "──────────────────────────────────",
                string.format("  JAVA_HOME:  %s", java ~= "" and java or "(not found)"),
                string.format("  Version:    %s", version),
                string.format("  jdtls:      %s", paths.launcher ~= "" and "✅" or "⭕"),
                string.format("  Lombok:     %s", vim.fn.filereadable(paths.lombok) == 1 and "✅" or "⭕"),
                string.format("  java-debug: %s", paths.java_debug ~= "" and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Java Info" }
            )
          end,
          ft   = "java",
          desc = "☕ Java: Environment info",
        },
      },
  
      config = function()
        local jdtls_ok, jdtls = pcall(require, "jdtls")
        if not jdtls_ok then return end
  
        local paths    = get_jdtls_paths()
        local java_home= get_java_home()
  
        if paths.launcher == "" then
          vim.notify(
            "☕ jdtls launcher not found. Install via Mason: :MasonInstall jdtls",
            vim.log.levels.WARN,
            { title = "Java" }
          )
          return
        end
  
        -- Build bundles (DAP)
        local bundles = {}
        if paths.java_debug ~= "" then
          table.insert(bundles, paths.java_debug)
        end
        vim.list_extend(bundles, paths.java_test)
  
        -- jdtls configuration
        local config = {
          cmd = {
            java_home ~= "" and (java_home .. "/bin/java") or "java",
            "-Declipse.application=org.eclipse.jdt.ls.core.id1",
            "-Dosgi.bundles.defaultStartLevel=4",
            "-Declipse.product=org.eclipse.jdt.ls.core.product",
            "-Dlog.protocol=true",
            "-Dlog.level=ALL",
            "-Xmx4g",
            "--add-modules=ALL-SYSTEM",
            "--add-opens", "java.base/java.util=ALL-UNNAMED",
            "--add-opens", "java.base/java.lang=ALL-UNNAMED",
            -- Lombok support
            vim.fn.filereadable(paths.lombok) == 1
              and ("-javaagent:" .. paths.lombok) or nil,
            "-jar", paths.launcher,
            "-configuration", paths.config_dir,
            "-data", paths.workspace,
          },
  
          root_dir = require("jdtls.setup").find_root({
            ".git", "mvnw", "gradlew", "pom.xml", "build.gradle",
            "build.gradle.kts", ".project",
          }),
  
          settings = {
            java = {
              format = {
                settings = {
                  url      = vim.fn.stdpath("config") .. "/lang-support/java-google-style.xml",
                  profile  = "GoogleStyle",
                },
                enabled  = true,
                comments = true,
                insertSpaces = true,
                tabSize      = 4,
              },
              eclipse     = { downloadSources = true },
              maven       = { downloadSources = true },
              implementationsCodeLens  = { enabled = true },
              referencesCodeLens       = { enabled = true },
              references               = { includeDecompiledSources = true },
              inlayHints = {
                parameterNames = { enabled = "all" },
              },
              signatureHelp    = { enabled = true },
              contentProvider  = { preferred = "fernflower" },
              completion = {
                favoriteStaticMembers = {
                  "org.hamcrest.MatcherAssert.assertThat",
                  "org.hamcrest.Matchers.*",
                  "org.hamcrest.CoreMatchers.*",
                  "org.junit.jupiter.api.Assertions.*",
                  "java.util.Objects.requireNonNull",
                  "java.util.Objects.requireNonNullElse",
                  "org.mockito.Mockito.*",
                },
                importOrder = {
                  "java", "javax", "jakarta", "com", "org",
                },
                filteredTypes = {
                  "com.sun.*", "io.micrometer.shaded.*",
                  "java.awt.*", "jdk.*", "sun.*",
                },
              },
              sources = {
                organizeImports = {
                  starThreshold          = 9999,
                  staticStarThreshold    = 9999,
                },
              },
              codeGeneration = {
                toString = {
                  template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
                },
                useBlocks = true,
              },
              configuration = {
                runtimes = (function()
                  local runtimes = {}
                  local jre_paths = {
                    { name = "JavaSE-21", path = "/usr/lib/jvm/java-21-openjdk-amd64" },
                    { name = "JavaSE-17", path = "/usr/lib/jvm/java-17-openjdk-amd64" },
                    { name = "JavaSE-11", path = "/usr/lib/jvm/java-11-openjdk-amd64" },
                  }
                  for _, rt in ipairs(jre_paths) do
                    if vim.fn.isdirectory(rt.path) == 1 then
                      table.insert(runtimes, rt)
                    end
                  end
                  return runtimes
                end)(),
              },
            },
          },
  
          bundles = bundles,
  
          capabilities = vim.tbl_deep_extend("force",
            _G.AshLspCapabilities or vim.lsp.protocol.make_client_capabilities(),
            require("jdtls").extendedClientCapabilities
          ),
  
          on_attach = function(client, bufnr)
            jdtls.setup_dap({ hotcodereplace = "auto" })
            require("jdtls.dap").setup_dap_main_class_configs()
  
            if client.supports_method("textDocument/inlayHint") then
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            end
  
            local global = _G.AshLspOnAttach
            if global then global(client, bufnr) end
          end,
  
          on_init = function(client, _)
            client.notify("workspace/didChangeConfiguration", {
              settings = client.config.settings,
            })
          end,
        }
  
        -- Remove nil values from cmd
        config.cmd = vim.tbl_filter(function(v) return v ~= nil end, config.cmd)
  
        jdtls.start_or_attach(config)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshJava", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "java",
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 4
            vim.opt_local.tabstop     = 4
            vim.opt_local.softtabstop = 4
            vim.opt_local.textwidth   = 120
            vim.opt_local.colorcolumn = "121"
          end,
          once = true,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("☕ Java highlights synced", vim.log.levels.INFO,
              { title = "ASH Java", timeout = 1200 })
          end,
        })
      end,
    },
  }