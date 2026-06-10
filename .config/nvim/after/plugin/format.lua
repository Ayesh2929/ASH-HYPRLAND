-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — FORMAT ON SAVE CONFIGURATION                 ║
-- ║           Per-filetype format configuration with conform.nvim              ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

-- Format on save is configured in plugins/lsp.lua (conform.nvim)
-- This file adds extra format-related configuration

local ok, conform = pcall(require, "conform")
if not ok then return end

-- ── Format command ─────────────────────────────────────────────────────────────
vim.api.nvim_create_user_command("Format", function(args)
    local range = nil
    if args.count ~= -1 then
        local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
        range = {
            start   = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
        }
    end
    conform.format({
        async        = true,
        lsp_fallback = true,
        range        = range,
    })
end, { range = true })

-- ── Format info command ────────────────────────────────────────────────────────
vim.api.nvim_create_user_command("FormatInfo", function()
    conform.format_info()
end, {})

-- ── Toggle format on save ──────────────────────────────────────────────────────
vim.api.nvim_create_user_command("FormatDisable", function(args)
    if args.bang then
        -- Disable globally
        vim.g.disable_autoformat = true
        vim.notify("Format on save: disabled (global)", vim.log.levels.INFO)
    else
        -- Disable for buffer
        vim.b.disable_autoformat = true
        vim.notify("Format on save: disabled (buffer)", vim.log.levels.INFO)
    end
end, { desc = "Disable autoformat on save", bang = true })

vim.api.nvim_create_user_command("FormatEnable", function()
    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
    vim.notify("Format on save: enabled", vim.log.levels.INFO)
end, { desc = "Enable autoformat on save" })

-- Keymaps
vim.keymap.set("n", "<leader>cf",  "<cmd>Format<CR>",        { desc = "Format file" })
vim.keymap.set("v", "<leader>cf",  "<cmd>Format<CR>",        { desc = "Format selection" })
vim.keymap.set("n", "<leader>uF",  "<cmd>FormatDisable<CR>", { desc = "Disable format on save" })
vim.keymap.set("n", "<leader>uFg", "<cmd>FormatDisable!<CR>", { desc = "Disable format globally" })
vim.keymap.set("n", "<leader>uf",  "<cmd>FormatEnable<CR>",  { desc = "Enable format on save" })