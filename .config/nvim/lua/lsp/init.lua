-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — LSP INITIALIZATION                           ║
-- ║           Capabilities, diagnostics, handlers setup                        ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎨 DIAGNOSTIC CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════════

M.setup_diagnostics = function()
    local icons = {
        Error = " ",
        Warn  = " ",
        Hint  = " ",
        Info  = " ",
    }

    -- Signs
    for type, icon in pairs(icons) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, {
            text   = icon,
            texthl = hl,
            numhl  = hl,
        })
    end

    vim.diagnostic.config({
        -- Show virtual text
        virtual_text = {
            enabled  = true,
            spacing  = 4,
            source   = "if_many",
            prefix   = "●",
            format   = function(diagnostic)
                local message = diagnostic.message
                if #message > 60 then
                    message = message:sub(1, 60) .. "…"
                end
                return message
            end,
        },
        -- Virtual lines (alternative to virtual text)
        -- virtual_lines = { only_current_line = true },

        -- Signs in gutter
        signs = {
            active   = true,
            severity = { min = vim.diagnostic.severity.HINT },
        },

        -- Underlines
        underline = {
            severity = { min = vim.diagnostic.severity.WARN },
        },

        -- Update on insert
        update_in_insert = false,

        -- Sorting
        severity_sort = true,

        -- Float window
        float = {
            focusable  = true,
            style      = "minimal",
            border     = "rounded",
            source     = "always",
            header     = "",
            prefix     = "",
            format     = function(d)
                local code = d.code and string.format("[%s]", d.code) or ""
                return string.format("%s %s %s", icons[d.severity == 1 and "Error" or
                    d.severity == 2 and "Warn" or d.severity == 3 and "Info" or "Hint"],
                    d.message, code)
            end,
        },
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ⚙️ LSP HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════════

M.setup_handlers = function()
    local hover_opts = {
        border   = "rounded",
        max_width  = 80,
        max_height = 30,
        focusable  = true,
        style      = "minimal",
    }

    -- Override hover handler
    vim.lsp.handlers["textDocument/hover"] =
        vim.lsp.with(vim.lsp.handlers.hover, hover_opts)

    -- Override signature help handler
    vim.lsp.handlers["textDocument/signatureHelp"] =
        vim.lsp.with(vim.lsp.handlers.signature_help, hover_opts)

    -- Override diagnostic handler
    vim.lsp.handlers["textDocument/publishDiagnostics"] =
        vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
            underline      = true,
            update_in_insert = false,
            virtual_text   = {
                spacing = 4,
                source  = "if_many",
                prefix  = "●",
            },
            severity_sort  = true,
        })
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 💪 CAPABILITIES
-- ═══════════════════════════════════════════════════════════════════════════════

M.make_capabilities = function()
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    -- Add nvim-cmp capabilities
    local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok then
        capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
    end

    -- File watching capabilities
    capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true

    -- Folding (for LSP-based folding)
    capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly     = true,
    }

    -- Semantic tokens
    capabilities.textDocument.semanticTokens = {
        dynamicRegistration = false,
    }

    -- Code actions
    capabilities.textDocument.codeAction = {
        dynamicRegistration  = true,
        codeActionLiteralSupport = {
            codeActionKind = {
                valueSet = {
                    "", "quickfix", "refactor", "refactor.extract",
                    "refactor.inline", "refactor.rewrite", "source",
                    "source.organizeImports",
                },
            },
        },
    }

    return capabilities
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔗 ON_ATTACH (per buffer LSP setup)
-- ═══════════════════════════════════════════════════════════════════════════════

M.on_attach = function(client, bufnr)
    -- Enable completion
    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    -- Tagfunc for LSP
    vim.api.nvim_buf_set_option(bufnr, "tagfunc", "v:lua.vim.lsp.tagfunc")

    -- Format on save (via conform)
    -- Handled in after/plugin/format.lua

    -- Inlay hints (Neovim 0.10+)
    if vim.fn.has("nvim-0.10") == 1 then
        if client.supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(bufnr, true)
        end
    end

    -- Code lens
    if client.supports_method("textDocument/codeLens") then
        vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
            buffer   = bufnr,
            callback = vim.lsp.codelens.refresh,
        })
        vim.lsp.codelens.refresh()
    end

    -- Document highlight (highlight word under cursor)
    if client.supports_method("textDocument/documentHighlight") then
        local hl_group = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = false })
        vim.api.nvim_clear_autocmds({ group = hl_group, buffer = bufnr })
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer   = bufnr,
            group    = hl_group,
            callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer   = bufnr,
            group    = hl_group,
            callback = vim.lsp.buf.clear_references,
        })
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🚀 SETUP ALL LSP SERVERS
-- ═══════════════════════════════════════════════════════════════════════════════

function M.setup()
    M.setup_diagnostics()
    M.setup_handlers()

    local capabilities = M.make_capabilities()

    -- Load server configurations
    local servers = require("lsp.servers")

    -- Setup each server
    local lspconfig = require("lspconfig")

    for server_name, server_opts in pairs(servers) do
        local opts = vim.tbl_deep_extend("force", {
            on_attach    = M.on_attach,
            capabilities = capabilities,
        }, server_opts)

        -- Special handling for certain servers
        if server_name == "rust_analyzer" then
            -- Use rust-tools or rustaceanvim instead
            -- Handled in plugins/lang.lua
            goto continue
        end

        lspconfig[server_name].setup(opts)
        ::continue::
    end

    -- Auto-setup via mason-lspconfig
    local ok, mason_lspconfig = pcall(require, "mason-lspconfig")
    if ok then
        mason_lspconfig.setup_handlers({
            -- Default handler
            function(server_name)
                if not servers[server_name] then
                    lspconfig[server_name].setup({
                        on_attach    = M.on_attach,
                        capabilities = capabilities,
                    })
                end
            end,
        })
    end
end

M.setup()
return M