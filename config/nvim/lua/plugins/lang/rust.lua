-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🦀 RUST — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                              ║
-- ║   rustaceanvim · cargo · clippy · expand macros · crates.io · test runner      ║
-- ║   inlay hints · proc-macros · workspace · runnables · ASH theme-synced         ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — Rust-specific semantic tokens
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Semantic token overrides ──────────────────────────────────────────────
    hl(0, "@lsp.type.lifetime.rust",           { italic = true, fg = "#89b4fa"  })
    hl(0, "@lsp.type.typeParameter.rust",      { italic = true, fg = "#94e2d5"  })
    hl(0, "@lsp.type.macro.rust",              { bold = true,   fg = "#cba6f7"  })
    hl(0, "@lsp.type.selfKeyword.rust",        { bold = true,   fg = "#f9e2af"  })
    hl(0, "@lsp.type.builtinType.rust",        { fg = "#89dceb"                 })
    hl(0, "@lsp.type.attributeBracket.rust",   { fg = "#9399b2"                 })
    hl(0, "@lsp.type.attribute.rust",          { italic = true, fg = "#9399b2"  })
    hl(0, "@lsp.type.generic.rust",            { italic = true, fg = "#94e2d5"  })
    hl(0, "@lsp.type.deriveHelper.rust",       { italic = true, fg = "#cba6f7"  })
    hl(0, "@lsp.type.formatSpecifier.rust",    { fg = "#7dcfff"                 })
    hl(0, "@lsp.type.operator.rust",           { fg = "#89b4fa"                 })
    hl(0, "@lsp.type.punctuation.rust",        { fg = "#cdd6f4"                 })
    hl(0, "@lsp.type.constParameter.rust",     { bold = true, fg = "#fab387"    })
    hl(0, "@lsp.type.enumMember.rust",         { fg = "#89dceb"                 })
    hl(0, "@lsp.type.unresolvedReference.rust",{ underline = true, fg = "#f38ba8" })
  
    -- ── Modifiers ────────────────────────────────────────────────────────────
    hl(0, "@lsp.typemod.function.async.rust",      { italic = true, fg = "#89b4fa" })
    hl(0, "@lsp.typemod.method.async.rust",        { italic = true, fg = "#89b4fa" })
    hl(0, "@lsp.typemod.variable.mutable.rust",    { underline = true             })
    hl(0, "@lsp.typemod.variable.consuming.rust",  { bold = true, italic = true   })
    hl(0, "@lsp.typemod.variable.captured.rust",   { italic = true                })
    hl(0, "@lsp.typemod.variable.unsafe.rust",     { bold = true, fg = "#f9e2af"  })
    hl(0, "@lsp.typemod.function.unsafe.rust",     { bold = true, fg = "#f9e2af"  })
    hl(0, "@lsp.typemod.operator.unsafe.rust",     { fg = "#f9e2af"               })
    hl(0, "@lsp.typemod.struct.unsafe.rust",       { bold = true, fg = "#f9e2af"  })
    hl(0, "@lsp.typemod.macro.unsafe.rust",        { bold = true, fg = "#f9e2af"  })
  
    -- ── Cargo / Crates ────────────────────────────────────────────────────────
    hl(0, "CratesNvimLoading",         { fg = "#9399b2"                         })
    hl(0, "CratesNvimVersion",         { fg = "#9ece6a"                         })
    hl(0, "CratesNvimPreRelease",      { fg = "#f9e2af"                         })
    hl(0, "CratesNvimYanked",          { fg = "#f38ba8"                         })
    hl(0, "CratesNvimNoMatch",         { fg = "#f38ba8"                         })
    hl(0, "CratesNvimUpgrade",         { bold = true, fg = "#7aa2f7"            })
    hl(0, "CratesNvimError",           { bold = true, fg = "#f38ba8"            })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "@lsp.type.lifetime.rust",  { italic = true, fg = p.blue })
        hl(0, "@lsp.typemod.function.async.rust", { italic = true, fg = p.blue })
      end
      if p.teal   then hl(0, "@lsp.type.typeParameter.rust", { italic = true, fg = p.teal   }) end
      if p.mauve  then hl(0, "@lsp.type.macro.rust",         { bold = true,   fg = p.mauve  }) end
      if p.yellow then
        hl(0, "@lsp.type.selfKeyword.rust",   { bold = true, fg = p.yellow })
        hl(0, "@lsp.typemod.variable.unsafe.rust", { bold = true, fg = p.yellow })
      end
      if p.green  then hl(0, "CratesNvimVersion", { fg = p.green }) end
      if p.red    then hl(0, "CratesNvimYanked",  { fg = p.red   }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 RUST UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function find_rust_analyzer()
    local mason = vim.fn.stdpath("data") .. "/mason/bin/rust-analyzer"
    if vim.fn.executable(mason) == 1 then return mason end
  
    local rustup = vim.fn.trim(vim.fn.system(
      "rustup which rust-analyzer 2>/dev/null"
    ))
    if rustup ~= "" and vim.fn.executable(rustup) == 1 then return rustup end
  
    return "rust-analyzer"
  end
  
  local function get_rust_edition()
    local cargo = vim.fn.getcwd() .. "/Cargo.toml"
    local f     = io.open(cargo, "r")
    if not f then return "2021" end
  
    local content = f:read("*a")
    f:close()
  
    return content:match('edition%s*=%s*"(%d+)"') or "2021"
  end
  
  local function get_workspace_features()
    local cargo = vim.fn.getcwd() .. "/Cargo.toml"
    local f     = io.open(cargo, "r")
    if not f then return {} end
  
    local content = f:read("*a")
    f:close()
  
    local features = {}
    local in_features = false
    for line in content:gmatch("[^\n]+") do
      if line:match("^%[features%]") then
        in_features = true
      elseif in_features and line:match("^%[") then
        in_features = false
      elseif in_features then
        local feat = line:match("^([%w_%-]+)%s*=")
        if feat then table.insert(features, feat) end
      end
    end
    return features
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- ── rustaceanvim — main Rust IDE plugin ────────────────────────────────────
    {
      "mrcjkb/rustaceanvim",
      version      = "^4",
      ft           = { "rust" },
      dependencies = {
        "neovim/nvim-lspconfig",
        { "nvim-telescope/telescope.nvim", optional = true },
      },
  
      keys = {
        -- ── Runnables ─────────────────────────────────────────────────────────
        {
          "<leader>rr",
          function() vim.cmd.RustLsp("runnables") end,
          ft   = "rust",
          desc = "🦀 Rust: Runnables",
        },
        {
          "<leader>rR",
          function() vim.cmd.RustLsp({ "runnables", bang = true }) end,
          ft   = "rust",
          desc = "🦀 Rust: Run last",
        },
        -- ── Debuggables ───────────────────────────────────────────────────────
        {
          "<leader>rd",
          function() vim.cmd.RustLsp("debuggables") end,
          ft   = "rust",
          desc = "🦀 Rust: Debuggables",
        },
        {
          "<leader>rD",
          function() vim.cmd.RustLsp({ "debuggables", bang = true }) end,
          ft   = "rust",
          desc = "🦀 Rust: Debug last",
        },
        -- ── Testables ─────────────────────────────────────────────────────────
        {
          "<leader>rt",
          function() vim.cmd.RustLsp("testables") end,
          ft   = "rust",
          desc = "🦀 Rust: Testables",
        },
        -- ── Macro expansion ───────────────────────────────────────────────────
        {
          "<leader>rm",
          function() vim.cmd.RustLsp("expandMacro") end,
          ft   = "rust",
          desc = "🦀 Rust: Expand Macro",
        },
        -- ── Move item ─────────────────────────────────────────────────────────
        {
          "<leader>r<up>",
          function() vim.cmd.RustLsp({ "moveItem", "up" }) end,
          ft   = "rust",
          desc = "🦀 Rust: Move item up",
        },
        {
          "<leader>r<down>",
          function() vim.cmd.RustLsp({ "moveItem", "down" }) end,
          ft   = "rust",
          desc = "🦀 Rust: Move item down",
        },
        -- ── Hover actions ─────────────────────────────────────────────────────
        {
          "K",
          function() vim.cmd.RustLsp({ "hover", "actions" }) end,
          ft   = "rust",
          desc = "🦀 Rust: Hover actions",
        },
        {
          "<leader>rk",
          function() vim.cmd.RustLsp({ "hover", "range" }) end,
          ft   = "rust",
          desc = "🦀 Rust: Hover range",
          mode = "v",
        },
        -- ── Code actions ──────────────────────────────────────────────────────
        {
          "<leader>ra",
          function() vim.cmd.RustLsp("codeAction") end,
          ft   = "rust",
          desc = "🦀 Rust: Code Action",
        },
        -- ── Explain error ─────────────────────────────────────────────────────
        {
          "<leader>re",
          function() vim.cmd.RustLsp("explainError") end,
          ft   = "rust",
          desc = "🦀 Rust: Explain Error",
        },
        {
          "<leader>rE",
          function() vim.cmd.RustLsp("renderDiagnostic") end,
          ft   = "rust",
          desc = "🦀 Rust: Render Diagnostic",
        },
        -- ── Reload workspace ──────────────────────────────────────────────────
        {
          "<leader>rw",
          function() vim.cmd.RustLsp("reloadWorkspace") end,
          ft   = "rust",
          desc = "🦀 Rust: Reload Workspace",
        },
        -- ── Crates ────────────────────────────────────────────────────────────
        {
          "<leader>rc",
          function()
            local ok, crates = pcall(require, "crates")
            if ok then crates.show_popup() end
          end,
          ft   = "rust",
          desc = "🦀 Rust: Crates popup",
        },
        {
          "<leader>rC",
          function()
            local ok, crates = pcall(require, "crates")
            if ok then crates.open_crates_io() end
          end,
          ft   = "rust",
          desc = "🦀 Rust: Open crates.io",
        },
        -- ── Join lines ────────────────────────────────────────────────────────
        {
          "<leader>rJ",
          function() vim.cmd.RustLsp("joinLines") end,
          ft   = "rust",
          desc = "🦀 Rust: Join Lines",
        },
        -- ── Structural search / replace ────────────────────────────────────────
        {
          "<leader>rs",
          function() vim.cmd.RustLsp("ssr") end,
          ft   = "rust",
          desc = "🦀 Rust: Structural Search Replace",
        },
        -- ── Open docs ─────────────────────────────────────────────────────────
        {
          "<leader>ro",
          function() vim.cmd.RustLsp("openDocs") end,
          ft   = "rust",
          desc = "🦀 Rust: Open docs.rs",
        },
        -- ── View HIR / MIR ────────────────────────────────────────────────────
        {
          "<leader>rh",
          function() vim.cmd.RustLsp("viewHir") end,
          ft   = "rust",
          desc = "🦀 Rust: View HIR",
        },
        {
          "<leader>ri",
          function() vim.cmd.RustLsp("viewMir") end,
          ft   = "rust",
          desc = "🦀 Rust: View MIR",
        },
        -- ── Flycheck ──────────────────────────────────────────────────────────
        {
          "<leader>rf",
          function() vim.cmd.RustLsp("flyCheck") end,
          ft   = "rust",
          desc = "🦀 Rust: Fly-check",
        },
      },
  
      ---@type rustaceanvim.Config
      opts = {
        -- ── Tools ──────────────────────────────────────────────────────────────
        tools = {
          -- Hover actions
          hover_actions = {
            auto_focus      = true,
            border          = "rounded",
            max_width       = nil,
            max_height      = nil,
          },
  
          -- Code action group
          code_action_group = {
            border = "rounded",
          },
  
          -- Runnables
          runnables = {
            use_telescope = true,
          },
  
          -- Test executor
          test_executor = "background",
  
          -- Macro expansion
          float_win_config = {
            border    = "rounded",
            max_height = 25,
            auto_focus = true,
          },
  
          -- Crate graph
          crate_graph = {
            backend     = "x11",
            output      = nil,
            full        = true,
            enabled_graphviz_backends = {
              "bmp", "cgimage", "canon", "dot", "gv",
              "xdot", "xdot1.2", "xdot1.4", "eps",
              "exr", "fig", "gd", "gd2", "gif", "gtk",
              "ico", "cmap", "ismap", "imap", "cmapx",
              "imap_np", "cmapx_np", "jpg", "jpeg",
              "jpe", "jp2", "json", "json0", "dot_json",
              "xdot_json", "pdf", "pic", "pct", "pict",
              "plain", "plain-ext", "png", "pov", "ps",
              "ps2", "psd", "sgi", "svg", "svgz",
              "tga", "tiff", "tif", "tk", "vml",
              "vmlz", "webp", "xlib", "x11",
            },
          },
  
          -- Open docs
          open_url = function(url)
            local open_cmd = vim.fn.has("mac") == 1 and "open"
              or (vim.fn.executable("xdg-open") == 1 and "xdg-open" or "start")
            vim.fn.system({ open_cmd, url })
          end,
        },
  
        -- ── rust-analyzer server ────────────────────────────────────────────────
        server = {
          on_attach = function(client, bufnr)
            -- Inlay hints
            if client.supports_method("textDocument/inlayHint") then
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            end
  
            -- Format on save using rustfmt
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer   = bufnr,
              callback = function()
                vim.lsp.buf.format({
                  bufnr  = bufnr,
                  async  = false,
                  filter = function(c) return c.name == "rust-analyzer" end,
                })
              end,
            })
  
            -- Delegate to global on_attach if available
            local global = _G.AshLspOnAttach
            if global then global(client, bufnr) end
          end,
  
          capabilities = (function()
            local caps = _G.AshLspCapabilities
            if caps then return caps end
            local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
            if ok then return cmp_lsp.default_capabilities() end
            return vim.lsp.protocol.make_client_capabilities()
          end)(),
  
          cmd = { find_rust_analyzer() },
  
          default_settings = {
            ["rust-analyzer"] = {
              -- ── Cargo ─────────────────────────────────────────────────────
              cargo = {
                allFeatures      = false,
                loadOutDirsFromCheck = true,
                buildScripts     = { enable = true },
                features         = "all",
              },
  
              -- ── Check / Clippy ─────────────────────────────────────────────
              checkOnSave        = true,
              check = {
                command          = "clippy",
                extraArgs        = {
                  "--no-deps",
                  "--",
                  "-W", "clippy::pedantic",
                  "-W", "clippy::nursery",
                  "-A", "clippy::missing_docs_in_private_items",
                },
              },
  
              -- ── Proc macros ────────────────────────────────────────────────
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"]     = { "async_trait"       },
                  ["napi-derive"]     = { "napi"              },
                  ["async-recursion"] = { "async_recursion"   },
                  ["tokio"]           = { "main", "test"      },
                },
              },
  
              -- ── Diagnostics ────────────────────────────────────────────────
              diagnostics = {
                enable           = true,
                experimental     = { enable = true },
                styleLints       = { enable = true },
              },
  
              -- ── Inlay hints ────────────────────────────────────────────────
              inlayHints = {
                bindingModeHints = { enable = true },
                chainingHints    = { enable = true },
                closingBraceHints= { enable = true, minLines = 25 },
                closureReturnTypeHints = { enable = "with_block" },
                lifetimeElisionHints = {
                  enable           = "skip_trivial",
                  useParameterNames= true,
                },
                maxLength        = 25,
                parameterHints   = { enable = true },
                reborrowHints    = { enable = "skip_trivial" },
                renderColons     = true,
                typeHints        = {
                  enable          = true,
                  hideClosureInitialization = false,
                  hideNamedConstructor      = false,
                },
              },
  
              -- ── Completion ─────────────────────────────────────────────────
              completion = {
                callable         = { snippets = "fill_arguments" },
                postfix          = { enable = true },
                privateEditable  = { enable = true },
                limit            = 25,
              },
  
              -- ── Hover ──────────────────────────────────────────────────────
              hover = {
                actions = {
                  enable          = true,
                  debug           = { enable = true },
                  gotoTypeDef     = { enable = true },
                  implementations = { enable = true },
                  references      = { enable = true },
                  run             = { enable = true },
                },
                documentation    = { enable = true, keywords = { enable = true } },
                links            = { enable = true },
                memoryLayout     = { enable = true, alignment = true, offset = true, size = true },
              },
  
              -- ── Imports ────────────────────────────────────────────────────
              imports = {
                granularity     = { group = "module", enforce = false },
                prefix          = "self",
                preferNoStd     = false,
              },
  
              -- ── Lens ───────────────────────────────────────────────────────
              lens = {
                enable          = true,
                debug           = { enable = true },
                implementations = { enable = true },
                references      = {
                  adt             = { enable = true },
                  enumVariant     = { enable = true },
                  method          = { enable = true },
                  trait           = { enable = true },
                },
                run             = { enable = true },
              },
  
              -- ── Semantic highlighting ──────────────────────────────────────
              semanticHighlighting = {
                nonStandardTokens  = true,
                strings = {
                  enable           = "except_in_macros",
                },
              },
  
              -- ── Typing ─────────────────────────────────────────────────────
              typing = {
                autoClosingAngleBrackets = { enable = true },
              },
  
              -- ── Workspace ──────────────────────────────────────────────────
              workspace = {
                symbol = {
                  search = {
                    kind    = "all_symbols",
                    scope   = "workspace_and_dependencies",
                    limit   = 256,
                  },
                },
              },
  
              -- ── Rustfmt ────────────────────────────────────────────────────
              rustfmt = {
                extraArgs       = {
                  "--edition", get_rust_edition(),
                },
                rangeFormatting = { enable = true },
              },
  
              -- ── Assist ─────────────────────────────────────────────────────
              assist = {
                importEnforceGranularity = true,
                importPrefix             = "by_crate",
                importGroup              = true,
                allowMergingIntoGlobImports = false,
              },
            },
          },
        },
  
        -- ── DAP (CodeLLDB) ─────────────────────────────────────────────────────
        dap = {
          adapter = (function()
            local codelldb = vim.fn.stdpath("data")
              .. "/mason/packages/codelldb/extension/adapter/codelldb"
            local liblldb  = vim.fn.stdpath("data")
              .. "/mason/packages/codelldb/extension/lldb/lib/liblldb"
              .. (vim.fn.has("mac") == 1 and ".dylib" or ".so")
  
            if vim.fn.executable(codelldb) == 1 then
              return require("rustaceanvim.config").get_codelldb_adapter(codelldb, liblldb)
            end
            return nil
          end)(),
        },
      },
  
      config = function(_, opts)
        vim.g.rustaceanvim = opts
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshRust", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🦀 Rust highlights synced", vim.log.levels.INFO,
              { title = "ASH Rust", timeout = 1200 })
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("🦀 Rust (rustaceanvim) loaded — edition: %s", get_rust_edition()),
            vim.log.levels.DEBUG,
            { title = "ASH Rust" }
          )
        end
      end,
    },
  
    -- ── crates.nvim — Cargo.toml dependency manager ─────────────────────────────
    {
      "saecki/crates.nvim",
      tag          = "stable",
      event        = "BufRead Cargo.toml",
      dependencies = { "nvim-lua/plenary.nvim" },
  
      keys = {
        { "<leader>rcu", function() require("crates").upgrade_all_crates()    end, ft = "toml", desc = "🦀 Crates: Upgrade all" },
        { "<leader>rcU", function() require("crates").upgrade_crate()         end, ft = "toml", desc = "🦀 Crates: Upgrade current" },
        { "<leader>rca", function() require("crates").add_crate()             end, ft = "toml", desc = "🦀 Crates: Add crate" },
        { "<leader>rcd", function() require("crates").open_documentation()    end, ft = "toml", desc = "🦀 Crates: Open docs" },
        { "<leader>rcr", function() require("crates").open_repository()       end, ft = "toml", desc = "🦀 Crates: Open repo" },
        { "<leader>rcf", function() require("crates").show_features_popup()   end, ft = "toml", desc = "🦀 Crates: Features popup" },
        { "<leader>rcD", function() require("crates").show_dependencies_popup()end, ft = "toml", desc = "🦀 Crates: Dependencies popup" },
        { "<leader>rcv", function() require("crates").show_versions_popup()   end, ft = "toml", desc = "🦀 Crates: Versions popup" },
        { "<leader>rci", function() require("crates").show_crate_popup()      end, ft = "toml", desc = "🦀 Crates: Info popup" },
      },
  
      opts = {
        smart_insert         = true,
        avoid_prerelease     = true,
        autoload             = true,
        autoupdate           = true,
        autoupdate_throttle  = 250,
        loading_indicator    = true,
        date_format          = "%Y-%m-%d",
        thousands_separator  = ".",
        notification_title   = "🦀 Crates",
        curl_args            = { "-sL", "--retry", "1" },
        max_parallel_requests = 80,
  
        src = {
          insert_closing_quote = true,
          plain_label          = false,
          name_col             = false,
          version_col          = true,
          coq                  = { enabled = false },
          cmp                  = { enabled = true },
        },
  
        popup = {
          autofocus  = true,
          style      = "minimal",
          border     = "rounded",
          show_version_date = true,
          show_dependency_version = true,
          max_height = 30,
          min_width  = 30,
          padding    = 1,
          text       = {
            title          = " 🦀 ",
            pill_left      = "",
            pill_right     = "",
            created_label  = "  created      ",
            updated_label  = "  updated      ",
            downloads_label= "  downloads    ",
            homepage_label = "  homepage     ",
            repository_label = " 󰊢 repository   ",
            documentation_label = " 󰧮 documentation",
            crates_io_label= "  crates.io    ",
            categories_label = " 󰙅 categories   ",
            keywords_label = " 󰓁 keywords     ",
            version        = "  %s",
            prerelease     = " 󰀦 %s",
            yanked         = " 󰅗 %s",
            version_date   = "  %s ",
            optional       = " 󰒕 %s",
            loading        = " 󰔟",
          },
          highlight = {
            title     = "CratesNvimPopupTitle",
            pill_text = "CratesNvimPopupPillText",
            pill_border = "CratesNvimPopupPillBorder",
            description = "CratesNvimPopupDescription",
            created_label = "CratesNvimPopupLabel",
            created     = "CratesNvimPopupValue",
            updated_label = "CratesNvimPopupLabel",
            updated     = "CratesNvimPopupValue",
            downloads_label = "CratesNvimPopupLabel",
            downloads   = "CratesNvimPopupValue",
            homepage_label = "CratesNvimPopupLabel",
            homepage    = "CratesNvimPopupUrl",
            repository_label = "CratesNvimPopupLabel",
            repository  = "CratesNvimPopupUrl",
            documentation_label = "CratesNvimPopupLabel",
            documentation = "CratesNvimPopupUrl",
            crates_io_label = "CratesNvimPopupLabel",
            crates_io   = "CratesNvimPopupUrl",
            categories_label = "CratesNvimPopupLabel",
            category    = "CratesNvimPopupCategory",
            keywords_label = "CratesNvimPopupLabel",
            keyword     = "CratesNvimPopupKeyword",
            version     = "CratesNvimPopupVersion",
            prerelease  = "CratesNvimPopupPreRelease",
            yanked      = "CratesNvimPopupYanked",
            version_date = "CratesNvimPopupVersionDate",
            feature     = "CratesNvimPopupFeature",
            enabled     = "CratesNvimPopupEnabled",
            transitive  = "CratesNvimPopupTransitive",
            optional    = "CratesNvimPopupOptional",
            dependency  = "CratesNvimPopupDependency",
            optional_dependency = "CratesNvimPopupOptionalDependency",
          },
          keys = {
            hide               = { "q", "<esc>" },
            open_url           = { "<cr>" },
            select             = { "<cr>", "<2-LeftMouse>" },
            select_alt         = { "s" },
            toggle_feature     = { "<cr>", "<2-LeftMouse>" },
            copy_value         = { "yy" },
            goto_item          = { "gd", "K", "<C-d>" },
            jump_forward       = { "<c-i>" },
            jump_back          = { "<c-o>", "<C-s>" },
          },
        },
  
        completion = {
          insert_closing_quote = true,
          text = {
            prerelease  = "  pre-release  ",
            yanked      = "  yanked       ",
          },
        },
  
        null_ls = {
          enabled = false,
          name    = "crates.nvim",
        },
  
        lsp = {
          enabled          = true,
          name             = "crates.nvim",
          on_attach        = function(client, bufnr)
            local global = _G.AshLspOnAttach
            if global then global(client, bufnr) end
          end,
          actions          = true,
          completion       = true,
          hover            = true,
        },
      },
  
      config = function(_, opts)
        require("crates").setup(opts)
  
        -- Wire crates.nvim as a cmp source
        local ok, cmp = pcall(require, "cmp")
        if ok then
          local ok2, crates_src = pcall(require, "crates.src.cmp")
          if ok2 then
            cmp.setup.buffer({
              sources = cmp.config.sources({
                { name = "crates", priority = 1100 },
              }),
            })
          end
        end
      end,
    },
  }