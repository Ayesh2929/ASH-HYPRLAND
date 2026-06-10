-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — CUSTOM STATUSLINE                            ║
-- ║           Feature-rich statusline with LSP, git, and mode info            ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎨 MODE DEFINITIONS
-- ═══════════════════════════════════════════════════════════════════════════════

local MODES = {
    n     = { name = "NORMAL",   icon = "󰋜", color = "primary"   },
    i     = { name = "INSERT",   icon = "󰏫", color = "success"   },
    v     = { name = "VISUAL",   icon = "󰕷", color = "warning"   },
    V     = { name = "V-LINE",   icon = "󰕸", color = "warning"   },
    [""] = { name = "V-BLOCK",  icon = "󰹑", color = "warning"   },
    c     = { name = "COMMAND",  icon = "󰘳", color = "info"      },
    s     = { name = "SELECT",   icon = "󰒉", color = "secondary" },
    S     = { name = "S-LINE",   icon = "󰒊", color = "secondary" },
    [""] = { name = "S-BLOCK",  icon = "󰒋", color = "secondary" },
    R     = { name = "REPLACE",  icon = "󰛔", color = "error"     },
    t     = { name = "TERMINAL", icon = "󰰫", color = "tertiary"  },
    ["!"] = { name = "SHELL",    icon = "󱆃", color = "tertiary"  },
    no    = { name = "O-PENDING",icon = "󰋕", color = "primary"   },
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 COMPONENT BUILDERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function mode_component()
    local mode_key = vim.api.nvim_get_mode().mode
    local mode     = MODES[mode_key] or MODES["n"]
    return string.format(" %s %s ", mode.icon, mode.name)
end

local function git_component()
    local ok, gitsigns = pcall(require, "gitsigns")
    if not ok then return "" end

    local head = vim.b.gitsigns_head
    if not head or head == "" then return "" end

    local status = vim.b.gitsigns_status_dict
    local parts  = { "  " .. head }

    if status then
        if (status.added    or 0) > 0 then
            parts[#parts+1] = " +" .. status.added
        end
        if (status.changed  or 0) > 0 then
            parts[#parts+1] = " ~" .. status.changed
        end
        if (status.removed  or 0) > 0 then
            parts[#parts+1] = " -" .. status.removed
        end
    end

    return table.concat(parts) .. " "
end

local function filename_component()
    local fname = vim.fn.expand("%:t")
    if fname == "" then fname = "[No Name]" end

    local modified  = vim.bo.modified and " ●" or ""
    local readonly  = (vim.bo.readonly or not vim.bo.modifiable) and "  " or ""
    local icon      = ""

    -- Try nvim-web-devicons
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if ok then
        local ext = vim.fn.expand("%:e")
        local file_icon = devicons.get_icon(fname, ext, { default = true })
        if file_icon then icon = file_icon .. " " end
    end

    return string.format(" %s%s%s%s ", icon, fname, readonly, modified)
end

local function lsp_component()
    local buf_clients = vim.lsp.get_active_clients({ bufnr = 0 })
    if not buf_clients or #buf_clients == 0 then return "" end

    local client_names = {}
    for _, client in ipairs(buf_clients) do
        if client.name ~= "null-ls" and client.name ~= "copilot" then
            table.insert(client_names, client.name)
        end
    end

    if #client_names == 0 then return "" end

    return "  " .. table.concat(client_names, ", ") .. " "
end

local function diagnostics_component()
    local errors   = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
    local hints    = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
    local info     = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })

    local parts = {}
    if errors   > 0 then parts[#parts+1] = " " .. errors   end
    if warnings > 0 then parts[#parts+1] = " " .. warnings end
    if hints    > 0 then parts[#parts+1] = " " .. hints    end
    if info     > 0 then parts[#parts+1] = " " .. info     end

    if #parts == 0 then return " " end
    return " " .. table.concat(parts, " ") .. " "
end

local function filetype_component()
    local ft = vim.bo.filetype
    if ft == "" then return "" end
    return string.format("  %s ", ft)
end

local function position_component()
    local row, col = table.unpack(vim.api.nvim_win_get_cursor(0))
    local total    = vim.api.nvim_buf_line_count(0)
    local pct      = math.floor(row / total * 100)
    return string.format(" %d:%d  %d%%%% ", row, col + 1, pct)
end

local function encoding_component()
    local enc = (vim.bo.fenc ~= "" and vim.bo.fenc) or vim.o.enc
    local ff  = vim.bo.fileformat
    if enc == "utf-8" and ff == "unix" then return "" end
    return string.format("  %s[%s] ", enc, ff)
end

local function indent_component()
    if vim.bo.expandtab then
        return string.format(" ⎵ %d ", vim.bo.shiftwidth)
    else
        return string.format(" ⇥ %d ", vim.bo.tabstop)
    end
end

local function progress_component()
    local line  = vim.fn.line(".")
    local total = vim.fn.line("$")
    if total == 0 then return "" end

    local icons = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
    local idx   = math.floor(line / total * (#icons - 1)) + 1
    return " " .. icons[idx] .. " "
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🏗️ STATUSLINE BUILDER
-- ═══════════════════════════════════════════════════════════════════════════════

function M.build()
    -- Skip for certain filetypes
    local ft = vim.bo.filetype
    local skip_ft = {
        "NvimTree", "lazy", "mason", "toggleterm", "TelescopePrompt",
        "alpha", "dashboard", "noice", "notify",
    }
    for _, sft in ipairs(skip_ft) do
        if ft == sft then return " " end
    end

    local parts = {}

    -- Left section
    parts[#parts+1] = mode_component()
    parts[#parts+1] = git_component()
    parts[#parts+1] = filename_component()
    parts[#parts+1] = diagnostics_component()

    -- Center spacer
    parts[#parts+1] = "%="

    -- Right section
    parts[#parts+1] = lsp_component()
    parts[#parts+1] = encoding_component()
    parts[#parts+1] = indent_component()
    parts[#parts+1] = filetype_component()
    parts[#parts+1] = position_component()
    parts[#parts+1] = progress_component()

    return table.concat(parts)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔌 SETUP
-- ═══════════════════════════════════════════════════════════════════════════════

function M.setup()
    -- Use lualine instead if available (recommended)
    local ok_lualine, lualine = pcall(require, "lualine")
    if ok_lualine then
        lualine.setup({
            options = {
                icons_enabled        = true,
                theme                = "auto",
                component_separators = { left = "", right = "" },
                section_separators   = { left = "", right = "" },
                disabled_filetypes   = {
                    statusline = { "alpha", "dashboard", "NvimTree" },
                    winbar     = {},
                },
                globalstatus         = true,
                refresh              = { statusline = 1000 },
            },
            sections = {
                lualine_a = {
                    { "mode", separator = { right = "" }, padding = 0 },
                },
                lualine_b = {
                    { "branch", icon = "  " },
                    { "diff",
                        symbols = { added = " ", modified = " ", removed = " " },
                        colored = true,
                    },
                },
                lualine_c = {
                    {
                        "filename",
                        file_status    = true,
                        newfile_status = true,
                        path           = 1,
                        symbols = {
                            modified  = " ●",
                            readonly  = "  ",
                            unnamed   = "[No Name]",
                            newfile   = "[New]",
                        },
                    },
                    {
                        "diagnostics",
                        sources        = { "nvim_lsp" },
                        sections       = { "error", "warn", "info", "hint" },
                        symbols = {
                            error = " ", warn = " ",
                            info  = " ", hint = " ",
                        },
                        colored        = true,
                        update_in_insert = false,
                        always_visible  = false,
                    },
                },
                lualine_x = {
                    {
                        function()
                            local ok, m = pcall(require, "noice")
                            if not ok then return "" end
                            local status = m.api.statusline
                            return status.mode() or ""
                        end,
                        cond = function()
                            local ok, m = pcall(require, "noice")
                            return ok and m.api.statusline.mode.get() ~= nil
                        end,
                        color = { fg = "#89b4fa" },
                    },
                    { "filetype" },
                    { "encoding" },
                    { "fileformat", symbols = { unix = "LF", dos = "CRLF", mac = "CR" } },
                },
                lualine_y = {
                    { "progress", separator = { left = "" }, padding = 0 },
                },
                lualine_z = {
                    { "location", separator = { left = "" }, padding = 0 },
                },
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = { "location" },
                lualine_y = {},
                lualine_z = {},
            },
            tabline       = {},
            winbar        = {},
            inactive_winbar = {},
            extensions    = {
                "nvim-tree", "lazy", "toggleterm", "quickfix", "trouble",
            },
        })
        return
    end

    -- Fallback: use custom statusline
    vim.o.statusline = "%!v:lua.require('ui.statusline').build()"
end

return M