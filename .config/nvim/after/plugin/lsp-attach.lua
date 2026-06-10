-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — LSP ON-ATTACH CONFIGURATION                  ║
-- ║           Buffer-local LSP keymaps and features activated per buffer       ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

vim.api.nvim_create_autocmd("LspAttach", {
    group    = vim.api.nvim_create_augroup("AshLspAttach", { clear = true }),
    callback = function(event)
        local buf    = event.buf
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then return end

        -- ── Helper ────────────────────────────────────────────────────────────
        local function map(mode, keys, func, desc)
            vim.keymap.set(mode, keys, func, {
                buffer  = buf,
                silent  = true,
                noremap = true,
                desc    = "LSP: " .. desc,
            })
        end

        -- ── Navigation ────────────────────────────────────────────────────────
        map("n", "gd",          "<cmd>Telescope lsp_definitions<CR>",         "Go to Definition")
        map("n", "gD",          vim.lsp.buf.declaration,                       "Go to Declaration")
        map("n", "gr",          "<cmd>Telescope lsp_references<CR>",          "Go to References")
        map("n", "gi",          "<cmd>Telescope lsp_implementations<CR>",     "Go to Implementation")
        map("n", "gy",          "<cmd>Telescope lsp_type_definitions<CR>",    "Go to Type Definition")
        map("n", "K",           vim.lsp.buf.hover,                             "Hover Documentation")
        map("n", "<C-k>",       vim.lsp.buf.signature_help,                   "Signature Help")
        map("i", "<C-k>",       vim.lsp.buf.signature_help,                   "Signature Help")

        -- ── Actions ───────────────────────────────────────────────────────────
        map("n",           "<leader>ca",  vim.lsp.buf.code_action,            "Code Action")
        map({ "n", "v" },  "<leader>ca",  vim.lsp.buf.code_action,            "Code Action")
        map("n",           "<leader>cr",  vim.lsp.buf.rename,                 "Rename Symbol")
        map("n",           "<leader>cf",  function()
            require("conform").format({
                async        = true,
                lsp_fallback = true,
            })
        end,                                                                    "Format Buffer")
        map("v",           "<leader>cf",  function()
            require("conform").format({
                async        = true,
                lsp_fallback = true,
            })
        end,                                                                    "Format Selection")

        -- ── Diagnostics ───────────────────────────────────────────────────────
        map("n", "[d",          vim.diagnostic.goto_prev,                     "Previous Diagnostic")
        map("n", "]d",          vim.diagnostic.goto_next,                     "Next Diagnostic")
        map("n", "<leader>cd",  vim.diagnostic.open_float,                   "Show Diagnostic")
        map("n", "<leader>cD",  "<cmd>Telescope diagnostics<CR>",            "All Diagnostics")

        -- ── Workspace ─────────────────────────────────────────────────────────
        map("n", "<leader>ws",  "<cmd>Telescope lsp_document_symbols<CR>",   "Document Symbols")
        map("n", "<leader>wS",  "<cmd>Telescope lsp_workspace_symbols<CR>",  "Workspace Symbols")

        -- ── Inlay Hints (Neovim 0.10+) ────────────────────────────────────────
        if vim.fn.has("nvim-0.10") == 1 and client.supports_method("textDocument/inlayHint") then
            map("n", "<leader>uh", function()
                local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
                vim.lsp.inlay_hint.enable(not enabled, { bufnr = buf })
                vim.notify(
                    "Inlay hints " .. (not enabled and "enabled" or "disabled"),
                    vim.log.levels.INFO, { title = "LSP" }
                )
            end, "Toggle Inlay Hints")
        end

        -- ── Document Highlight ────────────────────────────────────────────────
        if client.supports_method("textDocument/documentHighlight") then
            local hl_group = vim.api.nvim_create_augroup(
                "AshDocHighlight_" .. buf, { clear = true }
            )
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer   = buf,
                group    = hl_group,
                callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer   = buf,
                group    = hl_group,
                callback = vim.lsp.buf.clear_references,
            })
        end

        -- ── Code Lens ─────────────────────────────────────────────────────────
        if client.supports_method("textDocument/codeLens") then
            vim.lsp.codelens.refresh()
            vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
                buffer   = buf,
                callback = vim.lsp.codelens.refresh,
            })
            map("n", "<leader>cl", vim.lsp.codelens.run, "Run Code Lens")
        end

        -- ── Format on Save ────────────────────────────────────────────────────
        if client.supports_method("textDocument/formatting") then
            vim.api.nvim_create_autocmd("BufWritePre", {
                buffer   = buf,
                callback = function()
                    -- Only format if not large file
                    if not vim.b.large_file then
                        pcall(require("conform").format, {
                            bufnr        = buf,
                            async        = false,
                            lsp_fallback = true,
                            timeout_ms   = 3000,
                        })
                    end
                end,
            })
        end

        -- ── Notify on attach ──────────────────────────────────────────────────
        vim.notify(
            string.format(" %s attached", client.name),
            vim.log.levels.DEBUG,
            { title = "LSP", timeout = 1000 }
        )
    end,
})