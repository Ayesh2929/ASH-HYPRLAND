-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — LSP SERVER CONFIGURATIONS                    ║
-- ║           15+ language server configurations with fine-tuned settings     ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 SHARED SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════════

local function get_root_dir(files)
    return require("lspconfig.util").root_pattern(table.unpack(files))
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📋 SERVER CONFIGURATIONS
-- ═══════════════════════════════════════════════════════════════════════════════

M.servers = {

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🌙 LUA — lua_ls (Neovim config optimized)
    -- ═══════════════════════════════════════════════════════════════════════════
    lua_ls = {
        settings = {
            Lua = {
                runtime    = {
                    version = "LuaJIT",
                    path    = vim.split(package.path, ";"),
                },
                diagnostics = {
                    globals    = {
                        "vim", "require", "print",
                        "pairs", "ipairs", "next", "type",
                        "tostring", "tonumber", "error", "pcall",
                        "setmetatable", "getmetatable", "rawget", "rawset",
                        -- Neovim-specific
                        "describe", "it", "before_each", "after_each",
                    },
                    disable    = { "missing-fields" },
                    unusedLocalExclude = { "_*" },
                },
                workspace  = {
                    library    = {
                        vim.env.VIMRUNTIME,
                        vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua",
                        "${3rd}/luv/library",
                        "${3rd}/busted/library",
                    },
                    checkThirdParty = false,
                    maxPreload      = 1000,
                    preloadFileSize = 1000,
                },
                completion = {
                    callSnippet  = "Replace",
                    keywordSnippet = "Replace",
                    displayContext = 6,
                },
                hint       = {
                    enable      = true,
                    setType     = true,
                    paramType   = true,
                    paramName   = "All",
                    semicolon   = "SameLine",
                    arrayIndex  = "Enable",
                },
                format     = {
                    enable     = true,
                    defaultConfig = {
                        indent_style               = "space",
                        indent_size                = "4",
                        continuation_indent_size   = "4",
                        quote_style                = "AutoPreferDouble",
                        call_arg_parentheses       = "always",
                    },
                },
                telemetry  = { enable = false },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🐍 PYTHON — pyright (full-featured static analysis)
    -- ═══════════════════════════════════════════════════════════════════════════
    pyright = {
        settings = {
            python = {
                analysis = {
                    typeCheckingMode     = "basic",
                    diagnosticMode       = "workspace",
                    autoImportCompletions = true,
                    useLibraryCodeForTypes = true,
                    autoSearchPaths      = true,
                    diagnosticSeverityOverrides = {
                        reportUnknownVariableType    = "none",
                        reportUnknownMemberType      = "none",
                        reportMissingImports         = "warning",
                        reportMissingModuleSource    = "warning",
                        reportUnusedImport           = "information",
                        reportUnusedVariable         = "information",
                        reportPrivateImportUsage     = "information",
                    },
                },
                pythonVersion        = "3.11",
                venvPath             = ".",
                venv                 = ".venv",
            },
        },
        before_init = function(_, config)
            -- Auto-detect virtual environment
            local venv_paths = {
                ".venv/bin/python",
                "venv/bin/python",
                "env/bin/python",
            }
            for _, path in ipairs(venv_paths) do
                local full = config.root_dir and (config.root_dir .. "/" .. path) or ""
                if vim.fn.executable(full) == 1 then
                    config.settings.python.pythonPath = full
                    break
                end
            end
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🌐 WEB — HTML/CSS/JSON/ESLint
    -- ═══════════════════════════════════════════════════════════════════════════
    html = {
        init_options = {
            provideFormatter = true,
        },
        settings = {
            html = {
                format = {
                    enable                   = true,
                    wrapLineLength           = 120,
                    unformatted              = "wbr",
                    contentUnformatted       = "pre,code,textarea",
                    endWithNewline           = true,
                    extraLiners              = "head, body, /html",
                    preserveNewLines         = true,
                    maxPreserveNewLines      = 32786,
                    indentInnerHtml          = false,
                    wrapAttributes           = "auto",
                    wrapAttributesIndentSize = nil,
                    templating               = false,
                    unformattedContentDelimiter = "",
                },
                suggest = {
                    html5 = true,
                },
                validate = {
                    scripts = true,
                    styles   = true,
                },
            },
        },
        filetypes = { "html", "templ", "htmldjango" },
    },

    cssls = {
        settings = {
            css = {
                validate   = true,
                lint       = { unknownAtRules = "ignore" },
            },
            scss = {
                validate   = true,
                lint       = { unknownAtRules = "ignore" },
            },
            less = {
                validate   = true,
                lint       = { unknownAtRules = "ignore" },
            },
        },
    },

    jsonls = {
        settings = {
            json = {
                schemas    = require("schemastore").json.schemas(),
                validate   = { enable = true },
                format     = { enable = true },
                keepLines  = { enable = true },
            },
        },
        setup = function()
            local ok, schemastore = pcall(require, "schemastore")
            if not ok then return end
        end,
    },

    eslint = {
        settings = {
            workingDirectories = { mode = "auto" },
            run                = "onSave",
            validate           = "on",
            debug              = false,
            experimental       = { useFlatConfig = false },
            codeAction = {
                disableRuleComment = {
                    enable   = true,
                    location = "separateLine",
                },
                showDocumentation = { enable = true },
            },
        },
        on_attach = function(client, bufnr)
            -- Auto-fix on save
            vim.api.nvim_create_autocmd("BufWritePre", {
                buffer   = bufnr,
                command  = "EslintFixAll",
            })
        end,
    },

    tailwindcss = {
        settings = {
            tailwindCSS = {
                validate   = true,
                emmetCompletions = false,
                classAttributes = {
                    "class", "className", "class:list", "classList",
                    "ngClass", "styles", "style",
                },
                experimental = {
                    classRegex = {
                        "tw`([^`]*)",
                        "tw\\(([^)]+)\\)",
                        { "clsx\\(([^)]*)\\)",       "(?:'|\"|`)([^']*)(?:'|\"|`)" },
                        { "cva\\(([^)]*)\\)",         "(?:'|\"|`)([^']*)(?:'|\"|`)" },
                        { "cn\\(([^)]*)\\)",          "(?:'|\"|`)([^']*)(?:'|\"|`)" },
                        { "classList\\.(add|remove)\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
                    },
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🐹 GO — gopls
    -- ═══════════════════════════════════════════════════════════════════════════
    gopls = {
        cmd      = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        settings = {
            gopls  = {
                completeUnimported   = true,
                usePlaceholders      = true,
                analyses = {
                    unusedparams     = true,
                    shadow           = true,
                    fieldalignment   = true,
                    nilness          = true,
                    unusedwrite      = true,
                    useany           = true,
                },
                gofumpt              = true,
                staticcheck          = true,
                semanticTokens       = true,
                hints = {
                    assignVariableTypes    = true,
                    compositeLiteralFields = true,
                    compositeLiteralTypes  = true,
                    constantValues         = true,
                    functionTypeParameters = true,
                    parameterNames         = true,
                    rangeVariableTypes     = true,
                },
                codelenses = {
                    gc_details         = false,
                    generate           = true,
                    regenerate_cgo     = true,
                    run_govulncheck    = true,
                    test               = true,
                    tidy               = true,
                    upgrade_dependency = true,
                    vendor             = true,
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🦀 RUST — handled by rustaceanvim plugin (see plugins/lang.lua)
    -- ═══════════════════════════════════════════════════════════════════════════
    -- rust_analyzer = nil,  -- Do NOT configure here

    -- ═══════════════════════════════════════════════════════════════════════════
    -- ⚡ BASH/SHELL
    -- ═══════════════════════════════════════════════════════════════════════════
    bashls = {
        settings = {
            bashIde = {
                backgroundAnalysisMaxFiles  = 500,
                enableSourceErrorDiagnostics = false,
                explainshellEndpoint        = "",
                globPattern                 = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
                includeAllWorkspaceSymbols  = false,
                logLevel                    = "info",
                shellcheckArguments         = "",
                shellcheckPath              = "",
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📋 YAML
    -- ═══════════════════════════════════════════════════════════════════════════
    yamlls = {
        settings = {
            yaml = {
                keyOrdering         = false,
                format              = { enable = true },
                validate            = true,
                schemaStore = {
                    enable = true,
                    url    = "https://www.schemastore.org/api/json/catalog.json",
                },
                schemas             = {
                    ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json"] = "/*.k8s.yaml",
                    ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.{yml,yaml}",
                    ["https://json.schemastore.org/github-action.json"]  = ".github/action.{yml,yaml}",
                    ["https://json.schemastore.org/ansible-playbook.json"] = "*play*.{yml,yaml}",
                    ["https://json.schemastore.org/prettierrc.json"]      = ".prettierrc.{yml,yaml}",
                    ["https://json.schemastore.org/stylelintrc.json"]     = ".stylelintrc.{yml,yaml}",
                    ["https://json.schemastore.org/circleciconfig.json"]  = ".circleci/**/*.{yml,yaml}",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📦 TOML — taplo
    -- ═══════════════════════════════════════════════════════════════════════════
    taplo = {
        settings = {
            evenBetterToml = {
                schema = {
                    enabled   = true,
                    repositoryEnabled = true,
                    repositoryUrl = "https://taplo.tamasfe.dev/schema_index.json",
                    links     = {},
                },
                formatter = {
                    alignEntries         = false,
                    alignComments        = true,
                    arrayTrailingComma   = true,
                    arrayAutoExpand      = true,
                    arrayAutoCollapse    = true,
                    compactArrays        = true,
                    compactInlineTables  = false,
                    compactEntries       = false,
                    columnWidth          = 80,
                    indentTables         = false,
                    indentEntries        = false,
                    reorderKeys          = false,
                    reorderArrays        = false,
                    allowedBlankLines    = 2,
                    trailingNewline      = true,
                    crlf                 = false,
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🐳 DOCKER
    -- ═══════════════════════════════════════════════════════════════════════════
    dockerls = {},

    docker_compose_language_service = {
        filetypes = { "yaml.docker-compose", "yaml" },
        root_dir  = get_root_dir({ "docker-compose.yml", "docker-compose.yaml" }),
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- ☕ JAVA — jdtls
    -- ═══════════════════════════════════════════════════════════════════════════
    jdtls = {
        -- Handled by nvim-jdtls plugin if installed
        -- See: https://github.com/mfussenegger/nvim-jdtls
        filetypes = { "java" },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📄 MARKDOWN — marksman
    -- ═══════════════════════════════════════════════════════════════════════════
    marksman = {
        filetypes = { "markdown", "quarto" },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🌍 LANGUAGE TOOL — ltex (grammar checking)
    -- ═══════════════════════════════════════════════════════════════════════════
    ltex = {
        enabled  = false,  -- Enable for spell/grammar checking in markdown
        settings = {
            ltex = {
                enabled          = { "markdown", "tex", "rst" },
                language         = "en-US",
                diagnosticSeverity = "information",
                sentenceCacheSize  = 2000,
                additionalRules  = {
                    enablePickyRules   = false,
                    motherTongue       = "en",
                },
                trace            = { server = "verbose" },
                disabledRules    = {},
                hiddenFalsePositives = {},
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🎮 LUA (for standalone lua/love2d projects)
    -- ═══════════════════════════════════════════════════════════════════════════
    lua_ls = {
        -- Defined above — this is a placeholder
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔷 GRAPHQL
    -- ═══════════════════════════════════════════════════════════════════════════
    graphql = {
        filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🗄️ SQL — sqls
    -- ═══════════════════════════════════════════════════════════════════════════
    sqls = {
        settings = {
            sqls = {
                connections = {
                    -- { driver = "postgresql", dataSourceName = "host=127.0.0.1 port=5432 user=postgres dbname=mydb sslmode=disable" },
                },
            },
        },
    },
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🚀 SETUP ALL SERVERS
-- ═══════════════════════════════════════════════════════════════════════════════

function M.setup_all(on_attach, capabilities)
    local lspconfig = require("lspconfig")

    for server, config in pairs(M.servers) do
        if config.enabled ~= false then
            local server_config = vim.tbl_deep_extend("force", {
                on_attach    = on_attach,
                capabilities = capabilities,
            }, config)

            -- Remove non-lspconfig keys
            server_config.enabled = nil
            server_config.setup   = nil

            -- Run any custom setup function
            if config.setup then
                config.setup()
            end

            pcall(lspconfig[server].setup, server_config)
        end
    end
end

return M