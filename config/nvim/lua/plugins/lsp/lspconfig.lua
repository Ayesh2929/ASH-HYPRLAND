-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔧 LSPCONFIG — ULTRA LANGUAGE SERVER ENGINE v5.0 OMEGA                   ║
-- ║   40+ language servers · smart defaults · per-server tweaks                     ║
-- ║   inlay hints · semantic tokens · codelens · ASH theme-synced diagnostics      ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 DIAGNOSTIC ICONS & HIGHLIGHTS — ASH premium sign column
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local DIAGNOSTIC_ICONS = {
    Error = " ",
    Warn  = " ",
    Info  = " ",
    Hint  = "󰌵 ",
  }
  
  local function setup_diagnostic_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Sign column glyphs ────────────────────────────────────────────────────
    hl(0, "DiagnosticSignError",       { bold = true, fg = "#f38ba8" })
    hl(0, "DiagnosticSignWarn",        { bold = true, fg = "#f9e2af" })
    hl(0, "DiagnosticSignInfo",        { bold = true, fg = "#89b4fa" })
    hl(0, "DiagnosticSignHint",        { bold = true, fg = "#94e2d5" })
  
    -- ── Diagnostic text in buffer ─────────────────────────────────────────────
    hl(0, "DiagnosticError",           { fg = "#f38ba8"              })
    hl(0, "DiagnosticWarn",            { fg = "#f9e2af"              })
    hl(0, "DiagnosticInfo",            { fg = "#89b4fa"              })
    hl(0, "DiagnosticHint",            { fg = "#94e2d5"              })
  
    -- ── Underlines ────────────────────────────────────────────────────────────
    hl(0, "DiagnosticUnderlineError",  { undercurl = true, sp = "#f38ba8" })
    hl(0, "DiagnosticUnderlineWarn",   { undercurl = true, sp = "#f9e2af" })
    hl(0, "DiagnosticUnderlineInfo",   { undercurl = true, sp = "#89b4fa" })
    hl(0, "DiagnosticUnderlineHint",   { undercurl = true, sp = "#94e2d5" })
  
    -- ── Virtual text ──────────────────────────────────────────────────────────
    hl(0, "DiagnosticVirtualTextError",{ italic = true, fg = "#f38ba8", bg = "#2d1b1e" })
    hl(0, "DiagnosticVirtualTextWarn", { italic = true, fg = "#f9e2af", bg = "#2d2a1e" })
    hl(0, "DiagnosticVirtualTextInfo", { italic = true, fg = "#89b4fa", bg = "#1e2340" })
    hl(0, "DiagnosticVirtualTextHint", { italic = true, fg = "#94e2d5", bg = "#1e2d2d" })
  
    -- ── Floating diagnostic window ────────────────────────────────────────────
    hl(0, "DiagnosticFloatingError",   { link = "DiagnosticError"    })
    hl(0, "DiagnosticFloatingWarn",    { link = "DiagnosticWarn"     })
    hl(0, "DiagnosticFloatingInfo",    { link = "DiagnosticInfo"     })
    hl(0, "DiagnosticFloatingHint",    { link = "DiagnosticHint"     })
  
    -- ── LSP reference highlights ─────────────────────────────────────────────
    hl(0, "LspReferenceText",          { bg = "#2a3158",             })
    hl(0, "LspReferenceRead",          { bg = "#1e3a2a",             })
    hl(0, "LspReferenceWrite",         { bg = "#3a1e1e", bold = true })
  
    -- ── Inlay hints ───────────────────────────────────────────────────────────
    hl(0, "LspInlayHint",              { italic = true, fg = "#6e738d", bg = "#1e1e2e" })
  
    -- ── Code lens ─────────────────────────────────────────────────────────────
    hl(0, "LspCodeLens",               { italic = true, fg = "#6e738d" })
    hl(0, "LspCodeLensSeparator",      { fg = "#3b4261"               })
  
    -- ── Signature help ────────────────────────────────────────────────────────
    hl(0, "LspSignatureActiveParameter",{ bold = true, underline = true, sp = "#7aa2f7" })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.red    then
        hl(0, "DiagnosticSignError",      { bold = true, fg = p.red   })
        hl(0, "DiagnosticError",          { fg = p.red                })
        hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = p.red })
      end
      if p.yellow then
        hl(0, "DiagnosticSignWarn",       { bold = true, fg = p.yellow })
        hl(0, "DiagnosticWarn",           { fg = p.yellow              })
        hl(0, "DiagnosticUnderlineWarn",  { undercurl = true, sp = p.yellow })
      end
      if p.blue   then
        hl(0, "DiagnosticSignInfo",       { bold = true, fg = p.blue  })
        hl(0, "DiagnosticInfo",           { fg = p.blue               })
      end
      if p.teal   then
        hl(0, "DiagnosticSignHint",       { bold = true, fg = p.teal  })
        hl(0, "DiagnosticHint",           { fg = p.teal               })
      end
      if p.blue   then
        hl(0, "LspReferenceText",  { bg = p.surface1 or "#2a3158" })
        hl(0, "LspSignatureActiveParameter", { bold = true, underline = true, sp = p.blue })
      end
      local overlay = p.overlay0 or "#6e738d"
      hl(0, "LspInlayHint",   { italic = true, fg = overlay })
      hl(0, "LspCodeLens",    { italic = true, fg = overlay })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🗺️  GLOBAL ON_ATTACH — capabilities registered for every server
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  ---@param client vim.lsp.Client
  ---@param bufnr  integer
  local function on_attach(client, bufnr)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, {
        buffer  = bufnr,
        silent  = true,
        noremap = true,
        desc    = "🔧 LSP: " .. desc,
      })
    end
  
    -- ── Navigation ─────────────────────────────────────────────────────────────
    map("n", "gd",         vim.lsp.buf.definition,          "Go to definition")
    map("n", "gD",         vim.lsp.buf.declaration,         "Go to declaration")
    map("n", "gi",         vim.lsp.buf.implementation,      "Go to implementation")
    map("n", "gt",         vim.lsp.buf.type_definition,     "Go to type definition")
    map("n", "gr",         vim.lsp.buf.references,          "References")
    map("n", "gR",         vim.lsp.buf.rename,              "Rename symbol")
    map("n", "K",          vim.lsp.buf.hover,               "Hover docs")
    map("n", "<C-k>",      vim.lsp.buf.signature_help,      "Signature help")
    map("i", "<C-k>",      vim.lsp.buf.signature_help,      "Signature help")
  
    -- ── Code actions ──────────────────────────────────────────────────────────
    map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action,    "Code action")
    map("n",          "<leader>lf", function()
      vim.lsp.buf.format({ async = true })
    end, "Format buffer")
    map("v",          "<leader>lf", function()
      vim.lsp.buf.format({ async = true, range = {
        ["start"] = vim.api.nvim_buf_get_mark(0, "<"),
        ["end"]   = vim.api.nvim_buf_get_mark(0, ">"),
      }})
    end, "Format selection")
  
    -- ── Workspace ─────────────────────────────────────────────────────────────
    map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder,    "Add workspace folder")
    map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
    map("n", "<leader>lwl", function()
      vim.notify(
        vim.inspect(vim.lsp.buf.list_workspace_folders()),
        vim.log.levels.INFO,
        { title = "LSP Workspaces" }
      )
    end, "List workspace folders")
  
    -- ── Diagnostics ───────────────────────────────────────────────────────────
    map("n", "<leader>ld", function()
      vim.diagnostic.open_float({ border = "rounded", source = "always" })
    end, "Show diagnostics (float)")
    map("n", "]d", function()
      vim.diagnostic.goto_next({
        float = { border = "rounded", source = "always" },
      })
    end, "Next diagnostic")
    map("n", "[d", function()
      vim.diagnostic.goto_prev({
        float = { border = "rounded", source = "always" },
      })
    end, "Prev diagnostic")
    map("n", "<leader>lq", vim.diagnostic.setqflist, "Diagnostics → quickfix")
    map("n", "<leader>lQ", vim.diagnostic.setloclist,"Diagnostics → loclist")
  
    -- ── Inlay hints ───────────────────────────────────────────────────────────
    if client.supports_method("textDocument/inlayHint") then
      map("n", "<leader>lh", function()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
        vim.notify(
          string.format("🔧 Inlay hints %s", not enabled and " on" or " off"),
          vim.log.levels.INFO,
          { title = "LSP", timeout = 1200 }
        )
      end, "Toggle inlay hints")
  
      -- Enable inlay hints by default (user can toggle off)
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end
  
    -- ── Codelens ──────────────────────────────────────────────────────────────
    if client.supports_method("textDocument/codeLens") then
      map("n", "<leader>lc", vim.lsp.codelens.run,     "Run codelens")
      map("n", "<leader>lC", vim.lsp.codelens.refresh, "Refresh codelens")
  
      local cl_aug = vim.api.nvim_create_augroup(
        "AshLspCodelens_" .. bufnr, { clear = true }
      )
      vim.api.nvim_create_autocmd(
        { "BufEnter", "CursorHold", "InsertLeave" },
        {
          group    = cl_aug,
          buffer   = bufnr,
          callback = function() pcall(vim.lsp.codelens.refresh) end,
        }
      )
    end
  
    -- ── Semantic tokens ───────────────────────────────────────────────────────
    if client.supports_method("textDocument/semanticTokens") then
      -- Semantic tokens are enabled by default; this toggle disables them
      map("n", "<leader>lt", function()
        client.server_capabilities.semanticTokensProvider = nil
        vim.notify(
          "🔧 Semantic tokens disabled for " .. client.name,
          vim.log.levels.INFO,
          { title = "LSP", timeout = 1500 }
        )
      end, "Disable semantic tokens")
    end
  
    -- ── Document highlight (illuminate references) ────────────────────────────
    if client.supports_method("textDocument/documentHighlight") then
      local dhl_aug = vim.api.nvim_create_augroup(
        "AshLspDocHighlight_" .. bufnr, { clear = true }
      )
      vim.api.nvim_create_autocmd("CursorHold", {
        group    = dhl_aug,
        buffer   = bufnr,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group    = dhl_aug,
        buffer   = bufnr,
        callback = vim.lsp.buf.clear_references,
      })
    end
  
    -- ── Status line component (expose server name) ────────────────────────────
    vim.b[bufnr].lsp_client_name = client.name
  
    -- ── Notify on attach (debug) ──────────────────────────────────────────────
    if vim.g.ash_debug then
      vim.notify(
        string.format("🔧 LSP attached: %s (buf %d)", client.name, bufnr),
        vim.log.levels.DEBUG,
        { title = "ASH LSP" }
      )
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔌 CAPABILITIES — merged with nvim-cmp & blink
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function build_capabilities()
    local caps = vim.lsp.protocol.make_client_capabilities()
  
    -- nvim-cmp snippet support
    local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok_cmp then
      caps = vim.tbl_deep_extend("force", caps, cmp_lsp.default_capabilities())
    end
  
    -- blink.cmp support (alternative to nvim-cmp)
    local ok_blink, blink = pcall(require, "blink.cmp")
    if ok_blink then
      caps = vim.tbl_deep_extend("force", caps, blink.get_lsp_capabilities())
    end
  
    -- Additional capabilities
    caps.textDocument.completion.completionItem = {
      documentationFormat   = { "markdown", "plaintext" },
      snippetSupport        = true,
      preselectSupport      = true,
      insertReplaceSupport  = true,
      labelDetailsSupport   = true,
      deprecatedSupport     = true,
      commitCharactersSupport = true,
      tagSupport            = { valueSet = { 1 } },
      resolveSupport        = {
        properties = { "documentation", "detail", "additionalTextEdits" },
      },
    }
  
    -- Folding support (nvim-ufo / treesitter folds)
    caps.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly     = true,
    }
  
    return caps
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌐 SERVER CONFIGURATIONS — per-server custom settings
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Each entry: [server_name] = { settings, filetypes, on_attach_extra, ... }
  local SERVERS = {
  
    -- ── 🦀 Rust ────────────────────────────────────────────────────────────────
    rust_analyzer = {
      settings = {
        ["rust-analyzer"] = {
          cargo = {
            allFeatures      = true,
            loadOutDirsFromCheck = true,
            buildScripts     = { enable = true },
          },
          checkOnSave        = true,
          check              = {
            command          = "clippy",
            extraArgs        = { "--no-deps" },
          },
          procMacro          = {
            enable           = true,
            ignored          = {
              ["async-trait"] = { "async_trait" },
              ["napi-derive"] = { "napi" },
              ["async-recursion"] = { "async_recursion" },
            },
          },
          inlayHints         = {
            bindingModeHints = { enable = false },
            chainingHints    = { enable = true },
            closingBraceHints= { enable = true, minLines = 25 },
            closureReturnTypeHints = { enable = "with_block" },
            lifetimeElisionHints   = { enable = "skip_trivial", useParameterNames = true },
            maxLength        = 25,
            parameterHints   = { enable = true },
            reborrowHints    = { enable = "skip_trivial" },
            renderColons     = true,
            typeHints        = { enable = true, hideClosureInitialization = false, hideNamedConstructor = false },
          },
          lens               = {
            enable           = true,
            run              = { enable = true },
            debug            = { enable = true },
            implementations  = { enable = true },
            references       = {
              adt              = { enable = true },
              enumVariant      = { enable = true },
              method           = { enable = true },
              trait            = { enable = true },
            },
          },
          completion         = {
            callable         = { snippets = "fill_arguments" },
            postfix          = { enable = true },
          },
          diagnostics        = {
            enable           = true,
            experimental     = { enable = true },
          },
          hover              = {
            actions          = {
              enable         = true,
              debug          = { enable = true },
              gotoTypeDef    = { enable = true },
              implementations = { enable = true },
              references     = { enable = true },
              run            = { enable = true },
            },
            documentation    = { enable = true, keywords = { enable = true } },
            links            = { enable = true },
          },
          semanticHighlighting = { strings = { enable = "except_in_macros" } },
          typing             = { autoClosingAngleBrackets = { enable = true } },
        },
      },
    },
  
    -- ── 🐍 Python ───────────────────────────────────────────────────────────────
    pyright = {
      settings = {
        python = {
          analysis = {
            typeCheckingMode         = "strict",
            autoSearchPaths          = true,
            useLibraryCodeForTypes   = true,
            diagnosticMode           = "workspace",
            autoImportCompletions    = true,
            completeFunctionParens   = true,
            inlayHints               = {
              variableTypes          = true,
              functionReturnTypes    = true,
              callArgumentNames      = true,
              pytestParameters       = true,
            },
          },
        },
      },
      before_init = function(_, config)
        -- Auto-detect virtualenv
        local venv_paths = {
          vim.fn.getcwd() .. "/.venv",
          vim.fn.getcwd() .. "/venv",
          vim.fn.expand("~/.local/share/pyenv/versions/"),
        }
        for _, path in ipairs(venv_paths) do
          if vim.fn.isdirectory(path) == 1 then
            config.settings.python.pythonPath = path .. "/bin/python"
            break
          end
        end
      end,
    },
  
    -- Alternative Python: ruff_lsp (fast, rust-based)
    ruff_lsp = {
      init_options = {
        settings = {
          args             = {},
          lint             = {
            enable         = true,
            select         = { "E", "F", "I", "N", "W", "UP", "RUF" },
          },
          format           = { preview = true },
        },
      },
      on_attach = function(client, bufnr)
        -- Disable ruff hover (defer to pyright)
        client.server_capabilities.hoverProvider = false
        on_attach(client, bufnr)
      end,
    },
  
    -- ── 🐹 Go ────────────────────────────────────────────────────────────────
    gopls = {
      settings = {
        gopls = {
          gofumpt          = true,
          codelenses       = {
            gc_details     = false,
            generate       = true,
            regenerate_cgo = true,
            run_govulncheck= true,
            test           = true,
            tidy           = true,
            upgrade_dependency = true,
            vendor         = true,
          },
          hints            = {
            assignVariableTypes    = true,
            compositeLiteralFields = true,
            compositeLiteralTypes  = true,
            constantValues         = true,
            functionTypeParameters = true,
            parameterNames         = true,
            rangeVariableTypes     = true,
          },
          analyses         = {
            fieldalignment = false,
            nilness        = true,
            unusedparams   = true,
            unusedwrite    = true,
            useany         = true,
          },
          usePlaceholders  = true,
          completeUnimported = true,
          staticcheck      = true,
          directoryFilters = {
            "-.git", "-.vscode", "-.idea", "-.venv",
            "-node_modules", "-vendor",
          },
          semanticTokens   = true,
        },
      },
    },
  
    -- ── 📘 TypeScript / JavaScript ─────────────────────────────────────────────
    ts_ls = {
      settings = {
        typescript = {
          inlayHints = {
            includeInlayParameterNameHints         = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints          = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = false,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints       = true,
          },
          suggest = {
            completeFunctionCalls = true,
          },
          tsserver = {
            maxTsServerMemory = 4096,
          },
        },
        javascript = {
          inlayHints = {
            includeInlayParameterNameHints         = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints          = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints       = true,
          },
          suggest = {
            completeFunctionCalls = true,
          },
        },
      },
      filetypes = {
        "javascript", "javascriptreact", "javascript.jsx",
        "typescript", "typescriptreact", "typescript.tsx",
      },
    },
  
    -- ── 🌙 Lua ──────────────────────────────────────────────────────────────────
    lua_ls = {
      settings = {
        Lua = {
          runtime        = {
            version      = "LuaJIT",
            path         = vim.split(package.path, ";"),
          },
          workspace      = {
            checkThirdParty = false,
            library        = {
              vim.fn.expand("$VIMRUNTIME/lua"),
              vim.fn.stdpath("config") .. "/lua",
              -- Include lazy-loaded plugin paths
              unpack(vim.api.nvim_get_runtime_file("", true)),
            },
            maxPreload     = 100000,
            preloadFileSize= 10000,
          },
          diagnostics    = {
            globals      = {
              "vim", "describe", "it", "before_each", "after_each",
              "assert", "require", "pcall", "xpcall",
            },
            disable      = { "missing-fields" },
          },
          completion     = {
            callSnippet  = "Replace",
            keywordSnippet = "Replace",
          },
          hint           = {
            enable       = true,
            arrayIndex   = "Disable",
            await        = true,
            paramName    = "Disable",
            paramType    = true,
            semicolon    = "Disable",
            setType      = false,
          },
          format         = {
            enable       = false,  -- handled by stylua via conform.nvim
          },
          telemetry      = { enable = false },
        },
      },
    },
  
    -- ── ⚙️  C / C++ ─────────────────────────────────────────────────────────────
    clangd = {
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--clang-tidy-checks=*",
        "--all-scopes-completion",
        "--completion-style=detailed",
        "--header-insertion-decorators",
        "--header-insertion=iwyu",
        "--pch-storage=memory",
        "--suggest-missing-includes",
        "--malloc-trim",
        "--enable-config",
        "--offset-encoding=utf-16",
        "--fallback-style=llvm",
        "--pretty",
      },
      init_options = {
        usePlaceholders  = true,
        completeUnimported = true,
        clangdFileStatus = true,
      },
      capabilities = {
        offsetEncoding = { "utf-16" },
      },
    },
  
    -- ── 🔶 Java ──────────────────────────────────────────────────────────────────
    jdtls = {
      -- jdtls is managed by nvim-jdtls plugin; skip auto-setup
      mason = false,
    },
  
    -- ── 🦩 Kotlin ────────────────────────────────────────────────────────────────
    kotlin_language_server = {
      settings = {
        kotlin = {
          compiler    = { jvm = { target = "17" } },
          debugAdapter= { enabled = true },
          hints       = { typeHints = true, parameterHints = true },
          completion  = { snippets = { enabled = true } },
          formatting  = { formatter = "ktfmt" },
        },
      },
    },
  
    -- ── 🏗️  Zig ──────────────────────────────────────────────────────────────────
    zls = {
      settings = {
        zls = {
          enable_inlay_hints       = true,
          enable_snippets          = true,
          warn_style               = true,
          highlight_global_var_declarations = true,
        },
      },
    },
  
    -- ── 🌟 Gleam ─────────────────────────────────────────────────────────────────
    gleam = {},
  
    -- ── 🧬 Elixir ────────────────────────────────────────────────────────────────
    elixirls = {
      settings = {
        elixirLS = {
          dialyzerEnabled      = true,
          fetchDeps            = false,
          enableTestLenses     = true,
          suggestSpecs         = true,
          signatureAfterComplete = true,
          mixEnv               = "dev",
        },
      },
    },
  
    -- ── λ Haskell ────────────────────────────────────────────────────────────────
    hls = {
      settings = {
        haskell = {
          cabalFormattingProvider = "cabalfmt",
          formattingProvider      = "fourmolu",
          checkProject            = true,
          plugin = {
            alternateNumberFormat = { globalOn = true },
            callHierarchy         = { globalOn = true },
            changeTypeSignature   = { globalOn = true },
            class                 = { codeLensOn = true, globalOn = true },
            eval                  = { globalOn = true },
            importLens            = { globalOn = true },
            moduleName            = { globalOn = true },
            refineImports         = { globalOn = true },
            rename                = { globalOn = true },
            retrie                = { globalOn = true },
            splice                = { globalOn = true },
            tactics               = { globalOn = true, hoverOn = true },
          },
        },
      },
      filetypes = { "haskell", "lhaskell", "cabal" },
    },
  
    -- ── 🐉 OCaml ─────────────────────────────────────────────────────────────────
    ocamllsp = {
      settings = {
        codelens      = { enable = true },
        inlayHints    = { enable = true },
        syntaxDocumentation = { enable = true },
      },
      get_language_id = function(_, ftype)
        local lang_ids = {
          menhir       = "text.menhir",
          ocamlinterface = "ocaml.interface",
          ocamllex     = "text.ocamllex",
        }
        return lang_ids[ftype]
      end,
    },
  
    -- ── 🐚 Bash / Fish / Shell ───────────────────────────────────────────────────
    bashls = {
      settings = {
        bashIde = {
          backgroundAnalysisMaxFiles = 500,
          enableSourceErrorDiagnostics = true,
          explainshellEndpoint       = "",
          globPattern                = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
          includeAllWorkspaceSymbols = false,
          logLevel                   = "info",
          shellcheckArguments        = "",
        },
      },
      filetypes = { "sh", "bash", "zsh" },
    },
  
    -- ── 🐠 Fish (via fish-lsp) ───────────────────────────────────────────────────
    fish_lsp = {
      filetypes = { "fish" },
    },
  
    -- ── 🌐 HTML ──────────────────────────────────────────────────────────────────
    html = {
      settings = {
        html = {
          validate = { scripts = true, styles = true },
          hover    = { documentation = true, references = true },
        },
      },
      filetypes = { "html", "heex", "htmldjango", "handlebars" },
    },
  
    -- ── 🎨 CSS / SCSS ────────────────────────────────────────────────────────────
    cssls = {
      settings = {
        css        = { validate = true, lint = { unknownAtRules = "ignore" } },
        scss       = { validate = true, lint = { unknownAtRules = "ignore" } },
        less       = { validate = true, lint = { unknownAtRules = "ignore" } },
      },
    },
  
    -- CSS modules
    cssmodules_ls = {},
  
    -- ── 🌈 Tailwind CSS ──────────────────────────────────────────────────────────
    tailwindcss = {
      settings = {
        tailwindCSS = {
          classAttributes        = { "class", "className", "class:list", "classList", "ngClass" },
          includeLanguages       = {
            elixir               = "html-eex",
            eelixir              = "html-eex",
            heex                 = "html-heex",
            rust                 = "html",
            rescript             = "javascriptreact",
          },
          lint                   = {
            cssConflict          = "warning",
            invalidApply         = "error",
            invalidConfigPath    = "error",
            invalidScreen        = "error",
            invalidTailwindDirective = "error",
            invalidVariant       = "error",
            recommendedVariantOrder = "warning",
          },
          validate               = true,
          experimental           = {
            classRegex           = {
              { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
              { "cx\\(([^)]*)\\)",  "(?:'|\"|`)([^']*)(?:'|\"|`)" },
            },
          },
        },
      },
      filetypes = {
        "aspnetcorerazor", "astro", "astro-markdown", "blade",
        "clojure", "django-html", "htmldjango", "edge", "eelixir",
        "elixir", "ejs", "erb", "eruby", "gohtml", "gohtmltmpl",
        "haml", "handlebars", "hbs", "html", "html-eex", "heex",
        "jade", "leaf", "liquid", "markdown", "mdx", "mustache",
        "njk", "nunjucks", "php", "razor", "slim", "twig",
        "css", "less", "postcss", "sass", "scss", "stylus",
        "sugarss", "javascript", "javascriptreact", "reason",
        "rescript", "typescript", "typescriptreact", "vue", "svelte",
        "templ",
      },
    },
  
    -- ── 🔷 GraphQL ────────────────────────────────────────────────────────────────
    graphql = {
      filetypes = { "graphql", "gql", "typescriptreact", "javascriptreact", "typescript" },
    },
  
    -- ── 📄 JSON ───────────────────────────────────────────────────────────────────
    jsonls = {
      settings = {
        json = {
          validate     = { enable = true },
          format       = { enable = true },
          schemas      = (function()
            local ok, schemastore = pcall(require, "schemastore")
            if ok then
              return schemastore.json.schemas({
                extra = {
                  { fileMatch = { "*.schema.json" }, url = "" },
                },
              })
            end
            return {}
          end)(),
        },
      },
      setup = {
        commands = {
          Format = {
            function()
              vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line("$"), 0 })
            end,
          },
        },
      },
    },
  
    -- ── 📋 YAML ────────────────────────────────────────────────────────────────────
    yamlls = {
      capabilities = {
        textDocument = { foldingRange = { dynamicRegistration = false, lineFoldingOnly = true } },
      },
      settings = {
        redhat       = { telemetry = { enabled = false } },
        yaml         = {
          keyOrdering = false,
          format      = { enable = true },
          validate    = true,
          schemaStore = {
            enable    = false,
            url       = "",
          },
          schemas     = (function()
            local ok, schemastore = pcall(require, "schemastore")
            if ok then return schemastore.yaml.schemas() end
            return {}
          end)(),
        },
      },
    },
  
    -- ── 📦 TOML ────────────────────────────────────────────────────────────────────
    taplo = {
      settings = {
        evenBetterToml = {
          schema         = { enabled = true, repositoryEnabled = true },
          formatter      = {
            alignEntries = false,
            arrayTrailingComma = true,
            arrayAutoExpand = true,
            arrayAutoCollapse = true,
            compactArrays  = true,
            compactInlineTables = false,
            compactEntries = false,
            columnWidth    = 80,
            indentTables   = false,
            indentEntries  = false,
            indentString   = "  ",
            reorderKeys    = false,
            reorderArrays  = false,
            allowedBlankLines = 2,
            trailingNewline = true,
            crlf           = false,
          },
        },
      },
    },
  
    -- ── 🐳 Docker ────────────────────────────────────────────────────────────────
    dockerls       = {},
    docker_compose_language_service = {
      filetypes = { "yaml.docker-compose" },
    },
  
    -- ── 🏗️  Terraform ─────────────────────────────────────────────────────────────
    terraformls    = {},
    tflint         = {},
  
    -- ── ❄️  Nix ────────────────────────────────────────────────────────────────────
    nil_ls = {
      settings = {
        ["nil"] = {
          formatting  = { command = { "nixfmt" } },
          nix         = {
            binary    = "nix",
            maxMemoryMB = 2560,
            flake     = {
              autoArchive    = false,
              autoEvalInputs = false,
            },
          },
        },
      },
    },
  
    -- ── 🗄️  SQL ────────────────────────────────────────────────────────────────────
    sqls = {
      settings = {
        sqls = {
          connections = {},   -- populated from project config
        },
      },
    },
  
    -- ── 📝 Markdown / MDX ─────────────────────────────────────────────────────────
    marksman       = {},
    mdx_analyzer   = { filetypes = { "mdx" } },
  
    -- ── 📐 LaTeX ──────────────────────────────────────────────────────────────────
    texlab = {
      settings = {
        texlab = {
          auxDirectory  = ".aux",
          bibtexFormatter = "texlab",
          build         = {
            args         = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
            executable   = "latexmk",
            forwardSearchAfter = false,
            onSave       = false,
          },
          chktex         = { onOpenAndSave = false, onEdit = false },
          diagnosticsDelay = 300,
          formatterLineLength = 80,
          forwardSearch  = { args = {} },
          latexFormatter = "latexindent",
          latexindent    = { modifyLineBreaks = false },
        },
      },
    },
  
    -- ── 🎮 GLSL ───────────────────────────────────────────────────────────────────
    glsl_analyzer  = {
      filetypes = { "glsl", "vert", "frag", "geom", "tesc", "tese", "comp", "wgsl" },
    },
  
    -- ── 🖥️  Hyprland ─────────────────────────────────────────────────────────────
    hyprls = {
      filetypes = { "hypr" },
    },
  
    -- ── 🔍 Protobuf ───────────────────────────────────────────────────────────────
    pbls           = {},
  
    -- ── 📊 R ──────────────────────────────────────────────────────────────────────
    r_language_server = {
      settings = {
        r = {
          lsp         = {
            diagnostics   = true,
            rich_documentation = true,
          },
        },
      },
    },
  
    -- ── 🌊 Svelte ─────────────────────────────────────────────────────────────────
    svelte = {
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        -- Svelte needs to be notified when TS files change
        vim.api.nvim_create_autocmd("BufWritePost", {
          pattern  = { "*.js", "*.ts" },
          callback = function(ctx)
            client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
          end,
        })
      end,
      settings = {
        svelte = {
          ["enable-ts-plugin"] = false,
          plugin = {
            svelte = { defaultScriptLanguage = "ts" },
          },
        },
      },
    },
  
    -- ── 🌐 Vue ────────────────────────────────────────────────────────────────────
    volar = {
      filetypes = { "vue" },
      init_options = {
        typescript = {
          tsdk = (function()
            local tsdk = vim.fn.expand("$MASON") .. "/packages/typescript-language-server/node_modules/typescript/lib"
            if vim.fn.isdirectory(tsdk) == 1 then return tsdk end
            return ""
          end)(),
        },
      },
    },
  
    -- ── ✨ Astro ──────────────────────────────────────────────────────────────────
    astro = {
      filetypes = { "astro" },
    },
  
    -- ── 🎯 Emmet ─────────────────────────────────────────────────────────────────
    emmet_language_server = {
      filetypes = {
        "css", "eruby", "html", "htmldjango", "javascriptreact",
        "less", "pug", "sass", "scss", "typescriptreact", "vue",
        "heex", "svelte",
      },
      init_options = {
        showexpandedabbreviation = "always",
        showabbreviationsuggestions = true,
        showsuggestionsassnippets = false,
      },
    },
  
    -- ── 🔏 ESLint ─────────────────────────────────────────────────────────────────
    eslint = {
      settings = {
        codeActionOnSave  = { enable = false, mode = "all" },
        format            = false,  -- use prettier instead
        nodePath          = "",
        onIgnoredFiles    = "off",
        packageManager    = "npm",
        quiet             = false,
        rulesCustomizations = {},
        run               = "onType",
        useESLintClass    = false,
        validate          = "on",
        workingDirectory  = { mode = "auto" },
      },
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer   = bufnr,
          callback = function() vim.cmd("EslintFixAll") end,
        })
      end,
    },
  
    -- ── 🏁 Prisma ────────────────────────────────────────────────────────────────
    prismals       = {},
  
    -- ── 🔵 PHP ───────────────────────────────────────────────────────────────────
    intelephense = {
      settings = {
        intelephense = {
          stubs         = {
            "bcmath", "bz2", "calendar", "Core", "curl",
            "date", "dba", "dom", "enchant", "fileinfo",
            "filter", "ftp", "gd", "gettext", "hash",
            "iconv", "imap", "intl", "json", "ldap",
            "libxml", "mbstring", "mcrypt", "mysql", "mysqli",
            "password", "pcntl", "pcre", "PDO", "pdo_mysql",
            "Phar", "readline", "recode", "Reflection",
            "regex", "session", "SimpleXML", "sockets",
            "sodium", "SPL", "standard", "superglobals",
            "tokenizer", "xml", "xdebug", "xmlreader",
            "xmlwriter", "yaml", "zip", "zlib",
            "wordpress", "woocommerce",
          },
          environment   = { includePaths = {} },
          files         = { maxSize = 5000000 },
        },
      },
    },
  
    -- ── 🔵 C# ────────────────────────────────────────────────────────────────────
    omnisharp = {
      cmd         = { "dotnet", vim.fn.stdpath("data") .. "/mason/packages/omnisharp/libexec/OmniSharp.dll" },
      settings    = {
        FormattingOptions = {
          EnableEditorConfigSupport = true,
          OrganizeImports           = nil,
        },
        MsBuild    = { LoadProjectsOnDemand = nil },
        RoslynExtensionsOptions = {
          EnableAnalyzersSupport   = nil,
          EnableImportCompletion   = nil,
          AnalyzeOpenDocumentsOnly = nil,
        },
        Sdk        = { IncludePrereleases = true },
      },
      enable_editorconfig_support = true,
      enable_ms_build_load_projects_on_demand = false,
      enable_roslyn_analyzers     = false,
      organize_imports_on_format  = false,
      enable_import_completion    = false,
    },
  
    -- ── ☕ Scala ────────────────────────────────────────────────────────────────
    metals = {
      -- Managed by scalameta/nvim-metals plugin
      mason = false,
    },
  
    -- ── 🛸 Solidity ───────────────────────────────────────────────────────────────
    solidity_ls_nomicfoundation = {},
  
    -- ── 🌿 TOML Nix configs ───────────────────────────────────────────────────────
    denols = {
      root_dir = (function()
        local lspconfig = require("lspconfig")
        return lspconfig.util.root_pattern("deno.json", "deno.jsonc")
      end)(),
      settings = {
        deno = {
          enable          = true,
          suggest         = {
            imports       = {
              autoDiscover = true,
              hosts        = { ["https://deno.land"] = true },
            },
          },
          inlayHints      = {
            enumMemberValues            = { enabled = true },
            functionLikeReturnTypes     = { enabled = true },
            parameterNames              = { enabled = "all", suppressWhenArgumentMatchesName = true },
            parameterTypes              = { enabled = true },
            propertyDeclarationTypes    = { enabled = true },
            variableTypes               = { enabled = false },
          },
        },
      },
    },
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 DIAGNOSTIC CONFIGURATION — global vim.diagnostic settings
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function setup_diagnostics()
    -- Register sign icons
    for severity, icon in pairs(DIAGNOSTIC_ICONS) do
      local sign_name = "DiagnosticSign" .. severity
      vim.fn.sign_define(sign_name, {
        text   = icon,
        texthl = sign_name,
        numhl  = sign_name .. "Nr",
        linehl = "",
      })
    end
  
    vim.diagnostic.config({
      -- ── Virtual text ──────────────────────────────────────────────────────
      virtual_text     = {
        enabled        = true,
        severity       = { min = vim.diagnostic.severity.WARN },
        source         = "if_many",
        prefix         = function(diagnostic)
          local icons = {
            [vim.diagnostic.severity.ERROR] = DIAGNOSTIC_ICONS.Error,
            [vim.diagnostic.severity.WARN]  = DIAGNOSTIC_ICONS.Warn,
            [vim.diagnostic.severity.INFO]  = DIAGNOSTIC_ICONS.Info,
            [vim.diagnostic.severity.HINT]  = DIAGNOSTIC_ICONS.Hint,
          }
          return icons[diagnostic.severity] or "● "
        end,
        spacing        = 4,
        format         = function(d)
          local max_width = 60
          local msg = d.message
          if #msg > max_width then
            msg = msg:sub(1, max_width) .. "…"
          end
          return msg
        end,
      },
  
      -- ── Signs ─────────────────────────────────────────────────────────────
      signs            = {
        active         = true,
        priority       = 10,
      },
  
      -- ── Underlines ────────────────────────────────────────────────────────
      underline        = {
        severity       = { min = vim.diagnostic.severity.WARN },
      },
  
      -- ── Float window ──────────────────────────────────────────────────────
      float            = {
        enabled        = true,
        source         = "always",
        border         = "rounded",
        header         = { " 🔧 Diagnostics", "DiagnosticSignInfo" },
        prefix         = function(diagnostic, i, _total)
          local icon = DIAGNOSTIC_ICONS[vim.diagnostic.severity[diagnostic.severity]] or "● "
          local hl   = ({
            [vim.diagnostic.severity.ERROR] = "DiagnosticError",
            [vim.diagnostic.severity.WARN]  = "DiagnosticWarn",
            [vim.diagnostic.severity.INFO]  = "DiagnosticInfo",
            [vim.diagnostic.severity.HINT]  = "DiagnosticHint",
          })[diagnostic.severity] or "Normal"
          return string.format("%d. %s", i, icon), hl
        end,
        suffix         = function(diagnostic)
          if diagnostic.code then
            return string.format(" [%s]", diagnostic.code), "Comment"
          end
          return "", ""
        end,
        format         = function(d)
          local source = d.source and ("[" .. d.source .. "] ") or ""
          return source .. d.message
        end,
        max_width      = 80,
        max_height     = 20,
      },
  
      -- ── Update behaviour ──────────────────────────────────────────────────
      update_in_insert = false,
      severity_sort    = true,
  
      -- ── Jump settings ─────────────────────────────────────────────────────
      jump             = {
        float          = true,
        severity       = { min = vim.diagnostic.severity.HINT },
      },
    })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "neovim/nvim-lspconfig",
      event        = { "BufReadPre", "BufNewFile" },
      dependencies = {
        -- Mason integration
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
  
        -- Schema stores
        { "b0o/schemastore.nvim", lazy = true },
  
        -- Completion
        { "hrsh7th/cmp-nvim-lsp",  optional = true },
  
        -- Folding
        { "kevinhwang91/nvim-ufo", optional = true },
  
        -- Progress UI
        { "j-hui/fidget.nvim",     optional = true },
      },
  
      config = function()
        -- ── 1. Highlights & diagnostics ──────────────────────────────────────
        setup_diagnostic_highlights()
        setup_diagnostics()
  
        local lspconfig    = require("lspconfig")
        local capabilities = build_capabilities()
  
        -- ── 2. Setup each server ─────────────────────────────────────────────
        for server_name, server_cfg in pairs(SERVERS) do
          -- Skip servers managed by specialised plugins
          if server_cfg.mason == false then goto continue end
  
          local config = vim.tbl_deep_extend("force", {
            capabilities = capabilities,
            on_attach    = server_cfg.on_attach or on_attach,
          }, server_cfg)
  
          -- Remove non-lspconfig keys
          config.mason = nil
  
          lspconfig[server_name].setup(config)
  
          ::continue::
        end
  
        -- ── 3. Expose server config for mason-lspconfig ───────────────────────
        -- Store for use by mason-lspconfig.lua
        _G.AshLspServers        = SERVERS
        _G.AshLspCapabilities   = capabilities
        _G.AshLspOnAttach       = on_attach
  
        -- ── 4. Autocmds ──────────────────────────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshLspConfig", { clear = true })
  
        -- Re-apply highlights on colorscheme change
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_diagnostic_highlights,
        })
  
        -- ASH hot-reload
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_diagnostic_highlights()
            vim.notify(
              "🔧 LSP diagnostic highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH LSP", timeout = 1200 }
            )
          end,
        })
  
        -- Auto-enable inlay hints for new LSP buffers
        vim.api.nvim_create_autocmd("LspAttach", {
          group    = aug,
          callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client and client.supports_method("textDocument/inlayHint") then
              vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
            end
          end,
        })
  
        -- Refresh codelens on attach
        vim.api.nvim_create_autocmd("LspAttach", {
          group    = aug,
          callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client and client.supports_method("textDocument/codeLens") then
              vim.lsp.codelens.refresh()
            end
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("🔧 LSP: %d servers configured", vim.tbl_count(SERVERS)),
            vim.log.levels.DEBUG,
            { title = "ASH LSP" }
          )
        end
      end,
    },
  }