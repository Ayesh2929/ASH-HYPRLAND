-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔧 LSP SERVER REGISTRY — ASH CONFIG v5.0 OMEGA                           ║
-- ║   40+ language servers · per-server settings · capability overrides            ║
-- ║   mason auto-install · custom on_attach · ASH integration                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 SHARED UTILITIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Resolve python executable from active venv
local function python_path()
  local venv_paths = {
    os.getenv("VIRTUAL_ENV"),
    os.getenv("CONDA_PREFIX"),
    vim.fn.getcwd() .. "/.venv",
    vim.fn.getcwd() .. "/venv",
  }
  for _, v in ipairs(venv_paths) do
    if v and v ~= "" then
      local py = v .. "/bin/python"
      if vim.fn.executable(py) == 1 then return py end
    end
  end
  return vim.fn.exepath("python3") or "python3"
end

-- Resolve TypeScript server path from Mason or node_modules
local function ts_server_path()
  local mason = vim.fn.stdpath("data") ..
    "/mason/packages/typescript-language-server/node_modules/typescript/lib"
  if vim.fn.isdirectory(mason) == 1 then return mason end

  local local_ts = vim.fn.getcwd() .. "/node_modules/typescript/lib"
  if vim.fn.isdirectory(local_ts) == 1 then return local_ts end

  return ""
end

-- Check if a root pattern file exists
local function has_file(patterns)
  local cwd = vim.fn.getcwd()
  for _, p in ipairs(patterns) do
    if vim.fn.filereadable(cwd .. "/" .. p) == 1 or
       vim.fn.isdirectory(cwd .. "/" .. p) == 1 then
      return true
    end
  end
  return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📋 SERVER DEFINITIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@type table<string, table>
M.servers = {

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🦀 RUST
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  rust_analyzer = {
    -- Managed by rustaceanvim — skip lspconfig setup
    mason = false,
    settings = {
      ["rust-analyzer"] = {
        cargo = {
          allFeatures      = true,
          loadOutDirsFromCheck = true,
          buildScripts     = { enable = true },
        },
        checkOnSave  = true,
        check        = {
          command    = "clippy",
          extraArgs  = { "--no-deps", "--", "-W", "clippy::pedantic" },
        },
        procMacro = {
          enable  = true,
          ignored = {
            ["async-trait"] = { "async_trait" },
            ["napi-derive"] = { "napi" },
          },
        },
        inlayHints = {
          chainingHints          = { enable = true },
          closureReturnTypeHints = { enable = "with_block" },
          lifetimeElisionHints   = { enable = "skip_trivial", useParameterNames = true },
          parameterHints         = { enable = true },
          reborrowHints          = { enable = "skip_trivial" },
          renderColons           = true,
          typeHints              = { enable = true },
        },
        lens = {
          enable          = true,
          run             = { enable = true },
          debug           = { enable = true },
          implementations = { enable = true },
          references      = {
            adt        = { enable = true },
            enumVariant= { enable = true },
            method     = { enable = true },
            trait      = { enable = true },
          },
        },
        completion       = {
          callable         = { snippets = "fill_arguments" },
          postfix          = { enable = true },
        },
        diagnostics      = { enable = true, experimental = { enable = true } },
        semanticHighlighting = { strings = { enable = "except_in_macros" } },
        rustfmt          = { extraArgs = { "--edition=2021" } },
        workspace        = {
          symbol = { search = { kind = "all_symbols", limit = 256 } },
        },
      },
    },
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🐍 PYTHON
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  pyright = {
    before_init = function(_, config)
      config.settings.python.pythonPath = python_path()
    end,
    settings = {
      python = {
        analysis = {
          typeCheckingMode       = "strict",
          autoSearchPaths        = true,
          useLibraryCodeForTypes = true,
          diagnosticMode         = "workspace",
          autoImportCompletions  = true,
          completeFunctionParens = true,
          inlayHints             = {
            variableTypes         = true,
            functionReturnTypes   = true,
            callArgumentNames     = true,
            pytestParameters      = true,
          },
        },
      },
    },
  },

  ruff_lsp = {
    on_attach = function(client, bufnr)
      -- Disable ruff hover; defer to pyright
      client.server_capabilities.hoverProvider = false
      local g = _G.AshLspOnAttach
      if g then g(client, bufnr) end
    end,
    init_options = {
      settings = {
        args   = {},
        lint   = { enable = true, select = { "E","F","I","N","W","UP","RUF" } },
        format = { preview = true },
      },
    },
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🐹 GO
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  gopls = {
    settings = {
      gopls = {
        gofumpt     = true,
        codelenses  = {
          gc_details     = false,
          generate       = true,
          regenerate_cgo = true,
          run_govulncheck= true,
          test           = true,
          tidy           = true,
          upgrade_dependency = true,
          vendor         = true,
        },
        hints = {
          assignVariableTypes    = true,
          compositeLiteralFields = true,
          compositeLiteralTypes  = true,
          constantValues         = true,
          functionTypeParameters = true,
          parameterNames         = true,
          rangeVariableTypes     = true,
        },
        analyses = {
          fieldalignment = false,
          nilness        = true,
          unusedparams   = true,
          unusedwrite    = true,
          useany         = true,
        },
        usePlaceholders    = true,
        completeUnimported = true,
        staticcheck        = true,
        semanticTokens     = true,
        directoryFilters   = {
          "-.git", "-.vscode", "-.idea", "-node_modules", "-vendor",
        },
      },
    },
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📘 TYPESCRIPT / JAVASCRIPT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ts_ls = {
    on_attach = function(client, bufnr)
      -- Disable tsserver formatting (use prettier)
      client.server_capabilities.documentFormattingProvider      = false
      client.server_capabilities.documentRangeFormattingProvider = false
      local g = _G.AshLspOnAttach
      if g then g(client, bufnr) end
    end,
    root_dir = function(fname)
      local util = require("lspconfig.util")
      -- Don't attach if Deno project
      if util.root_pattern("deno.json", "deno.jsonc")(fname) then return nil end
      return util.root_pattern(
        "tsconfig.json", "package.json", "jsconfig.json", ".git"
      )(fname)
    end,
    settings = {
      typescript = {
        inlayHints = {
          includeInlayParameterNameHints           = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints   = true,
          includeInlayVariableTypeHints            = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints  = true,
          includeInlayEnumMemberValueHints         = true,
        },
        tsserver = { maxTsServerMemory = 4096 },
        suggest  = { completeFunctionCalls = true },
      },
      javascript = {
        inlayHints = {
          includeInlayParameterNameHints           = "all",
          includeInlayFunctionParameterTypeHints   = true,
          includeInlayVariableTypeHints            = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints  = true,
          includeInlayEnumMemberValueHints         = true,
        },
        suggest = { completeFunctionCalls = true },
      },
    },
    filetypes = {
      "javascript", "javascriptreact", "javascript.jsx",
      "typescript", "typescriptreact", "typescript.tsx",
    },
  },

  denols = {
    root_dir = function(fname)
      return require("lspconfig.util").root_pattern(
        "deno.json", "deno.jsonc"
      )(fname)
    end,
    settings = {
      deno = {
        enable  = true,
        suggest = {
          imports = {
            autoDiscover = true,
            hosts = { ["https://deno.land"] = true },
          },
        },
        inlayHints = {
          enumMemberValues         = { enabled = true },
          functionLikeReturnTypes  = { enabled = true },
          parameterNames           = { enabled = "all", suppressWhenArgumentMatchesName = true },
          parameterTypes           = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          variableTypes            = { enabled = false },
        },
      },
    },
  },

  eslint = {
    settings = {
      format            = false,
      run               = "onType",
      validate          = "on",
      workingDirectory  = { mode = "auto" },
      codeActionOnSave  = { enable = false, mode = "all" },
    },
    on_attach = function(client, bufnr)
      local g = _G.AshLspOnAttach
      if g then g(client, bufnr) end
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer   = bufnr,
        callback = function() vim.cmd("EslintFixAll") end,
      })
    end,
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌙 LUA
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  lua_ls = {
    settings = {
      Lua = {
        runtime  = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          library         = {
            vim.fn.expand("$VIMRUNTIME/lua"),
            vim.fn.stdpath("config") .. "/lua",
          },
          maxPreload      = 100000,
          preloadFileSize = 10000,
        },
        diagnostics = {
          globals  = { "vim", "describe", "it", "before_each", "after_each", "assert" },
          disable  = { "missing-fields" },
        },
        completion = {
          callSnippet  = "Replace",
          keywordSnippet = "Replace",
        },
        hint = {
          enable      = true,
          arrayIndex  = "Disable",
          await       = true,
          paramType   = true,
          semicolon   = "Disable",
        },
        format   = { enable = false },
        telemetry= { enable = false },
      },
    },
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ⚙️  C / C++
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  clangd = {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--completion-style=detailed",
      "--header-insertion=iwyu",
      "--pch-storage=memory",
      "--suggest-missing-includes",
      "--enable-config",
      "--offset-encoding=utf-16",
      "--all-scopes-completion",
      "--fallback-style=llvm",
    },
    capabilities = {
      offsetEncoding = { "utf-16" },
    },
    init_options = {
      usePlaceholders    = true,
      completeUnimported = true,
      clangdFileStatus   = true,
    },
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ☕ JAVA (managed by nvim-jdtls)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  jdtls   = { mason = false },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎯 KOTLIN
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  kotlin_language_server = {
    settings = {
      kotlin = {
        compiler        = { jvm = { target = "21" } },
        debugAdapter    = { enabled = true },
        hints           = { typeHints = true, parameterHints = true },
        completion      = { snippets = { enabled = true } },
        formatting      = { formatter = "ktfmt" },
      },
    },
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ⚡ ZIG
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  zls = {
    settings = {
      zls = {
        enable_inlay_hints                    = true,
        enable_snippets                        = true,
        warn_style                             = true,
        highlight_global_var_declarations      = true,
        enable_autofix                         = true,
        zig_exe_path                           = vim.fn.exepath("zig"),
      },
    },
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ✨ GLEAM
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  gleam = {},

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- λ HASKELL (managed by haskell-tools.nvim)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hls = { mason = false },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌿 ELIXIR (managed by elixir-tools.nvim)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  elixirls = { mason = false },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🦩 OCAML
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ocamllsp = {
    settings = {
      codelens   = { enable = true },
      inlayHints = { enable = true },
      syntaxDocumentation = { enable = true },
    },
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌐 WEB
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  html = {
    settings  = { html = { validate = { scripts = true, styles = true } } },
    filetypes = { "html", "heex", "htmldjango", "handlebars" },
  },

  cssls = {
    settings = {
      css  = { validate = true, lint = { unknownAtRules = "ignore" } },
      scss = { validate = true, lint = { unknownAtRules = "ignore" } },
      less = { validate = true, lint = { unknownAtRules = "ignore" } },
    },
  },

  cssmodules_ls = {},

  tailwindcss = {
    settings = {
      tailwindCSS = {
        classAttributes = { "class", "className", "class:list", "classList", "ngClass" },
        validate        = true,
        experimental    = {
          classRegex = {
            { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
            { "cx\\(([^)]*)\\)",  "(?:'|\"|`)([^']*)(?:'|\"|`)" },
          },
        },
      },
    },
    filetypes = {
      "html", "css", "scss", "javascript", "javascriptreact",
      "typescript", "typescriptreact", "vue", "svelte", "astro",
      "heex", "elixir", "eelixir",
    },
  },

  graphql = {
    filetypes = {
      "graphql", "gql", "typescriptreact", "javascriptreact",
      "typescript", "javascript",
    },
  },

  svelte = {
    on_attach = function(client, bufnr)
      local g = _G.AshLspOnAttach
      if g then g(client, bufnr) end
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern  = { "*.js", "*.ts" },
        callback = function(ctx)
          client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
        end,
      })
    end,
    settings = {
      svelte = { ["enable-ts-plugin"] = false },
    },
  },

  volar = {
    filetypes = { "vue" },
    init_options = {
      typescript = { tsdk = ts_server_path() },
    },
  },

  astro = { filetypes = { "astro" } },

  emmet_language_server = {
    filetypes = {
      "css", "eruby", "html", "htmldjango", "javascriptreact",
      "less", "pug", "sass", "scss", "typescriptreact",
      "vue", "heex", "svelte",
    },
    init_options = {
      showexpandedabbreviation     = "always",
      showabbreviationsuggestions  = true,
      showsuggestionsassnippets    = false,
    },
  },

  prismals = {},

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📄 DATA / CONFIG
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  jsonls = {
    settings = {
      json = {
        validate = { enable = true },
        format   = { enable = true },
        schemas  = function()
          local ok, ss = pcall(require, "schemastore")
          return ok and ss.json.schemas() or {}
        end,
      },
    },
  },

  yamlls = {
    settings = {
      redhat = { telemetry = { enabled = false } },
      yaml   = {
        keyOrdering = false,
        format      = { enable = true },
        validate    = true,
        schemaStore = { enable = false, url = "" },
        schemas     = function()
          local ok, ss = pcall(require, "schemastore")
          return ok and ss.yaml.schemas() or {}
        end,
      },
    },
  },

  taplo = {
    settings = {
      evenBetterToml = {
        schema    = { enabled = true, repositoryEnabled = true },
        formatter = {
          arrayTrailingComma  = true,
          arrayAutoExpand     = true,
          columnWidth         = 80,
          indentString        = "  ",
          trailingNewline     = true,
        },
      },
    },
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🐳 INFRASTRUCTURE
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  dockerls = {},
  docker_compose_language_service = {
    filetypes = { "yaml.docker-compose" },
  },

  terraformls = {},
  tflint      = {},

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ❄️  NIX
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  nil_ls = {
    settings = {
      ["nil"] = {
        formatting = {
          command = (function()
            if vim.fn.executable("alejandra") == 1 then return { "alejandra" } end
            if vim.fn.executable("nixfmt")    == 1 then return { "nixfmt" }    end
            return nil
          end)(),
        },
        nix = {
          binary     = "nix",
          maxMemoryMB= 2560,
          flake      = { autoArchive = false, autoEvalInputs = false },
        },
      },
    },
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🗄️  DATABASE / QUERY
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  sqls     = {},
  marksman = {},

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📐 LATEX
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  texlab = {
    settings = {
      texlab = {
        auxDirectory = ".aux",
        build = {
          args       = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
          executable = "latexmk",
          onSave     = false,
        },
        chktex         = { onOpenAndSave = true, onEdit = false },
        diagnosticsDelay = 300,
        formatterLineLength = 80,
        latexFormatter = "latexindent",
        latexindent    = { modifyLineBreaks = false },
      },
    },
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🐚 SHELL
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  bashls = {
    settings = {
      bashIde = {
        backgroundAnalysisMaxFiles       = 500,
        enableSourceErrorDiagnostics     = true,
        globPattern                      = "*@(.sh|.inc|.bash|.command)",
      },
    },
    filetypes = { "sh", "bash", "zsh" },
  },

  -- fish_lsp: uncomment if available
  -- fish_lsp = { filetypes = { "fish" } },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🖥️  HYPRLAND
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  hyprls = { filetypes = { "hypr" } },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎮 SHADER / GRAPHICS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  glsl_analyzer = {
    filetypes = { "glsl", "vert", "frag", "geom", "tesc", "tese", "comp", "wgsl" },
  },

  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔷 MISC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  pbls            = {},  -- Protobuf
  r_language_server = {},
  mdx_analyzer    = { filetypes = { "mdx" } },
  solidity_ls_nomicfoundation = {},

  -- .NET
  omnisharp = {
    cmd = {
      "dotnet",
      vim.fn.stdpath("data") .. "/mason/packages/omnisharp/libexec/OmniSharp.dll",
    },
    enable_import_completion   = true,
    organize_imports_on_format = false,
    enable_roslyn_analyzers    = false,
  },

  -- PHP
  intelephense = {
    settings = {
      intelephense = {
        stubs   = { "bcmath","bz2","calendar","Core","curl","date","dom","filter",
                    "gd","hash","iconv","imap","intl","json","ldap","mbstring",
                    "mcrypt","mysql","mysqli","pcntl","pcre","PDO","pdo_mysql",
                    "Phar","readline","Reflection","regex","session","SimpleXML",
                    "sockets","SPL","standard","superglobals","tokenizer","xml",
                    "xdebug","xmlreader","xmlwriter","yaml","zip","zlib",
                    "wordpress","woocommerce" },
        environment = { includePaths = {} },
        files       = { maxSize = 5000000 },
      },
    },
  },

  -- Ruby
  -- solargraph = {},   -- uncomment if using Ruby

  -- Dart
  -- dartls = {},       -- uncomment if using Dart/Flutter

  -- Swift
  -- sourcekit = {},    -- uncomment if using Swift
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📦 MASON ENSURE INSTALLED (LSP subset)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

M.mason_lsp_ensure = {
  "pyright",       "ruff_lsp",    "gopls",
  "ts_ls",         "eslint",      "lua_ls",
  "clangd",        "kotlin_language_server",
  "zls",           "gleam",       "ocamllsp",
  "html",          "cssls",       "cssmodules_ls",
  "tailwindcss",   "graphql",     "svelte",
  "volar",         "astro",       "emmet_language_server",
  "prismals",      "jsonls",      "yamlls",
  "taplo",         "dockerls",    "docker_compose_language_service",
  "terraformls",   "tflint",      "nil_ls",
  "sqls",          "marksman",    "texlab",
  "bashls",        "hyprls",      "glsl_analyzer",
  "pbls",          "omnisharp",   "intelephense",
  "denols",        "mdx_analyzer",
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔌 PUBLIC API
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---Get config for a specific server
---@param name string
---@return table|nil
function M.get(name)
  return M.servers[name]
end

---Iterate servers that should be auto-set up (mason == false excluded)
---@param fn fun(name:string, cfg:table)
function M.each(fn)
  for name, cfg in pairs(M.servers) do
    if cfg.mason ~= false then
      fn(name, cfg)
    end
  end
end

return M