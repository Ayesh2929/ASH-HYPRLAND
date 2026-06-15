-- Neovim Plugins

return {
    -- Telescope
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            require('telescope').setup({
                defaults = {
                    file_ignore_patterns = { "node_modules", ".git" }
                }
            })
        end
    },

    -- Treesitter
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter.configs').setup({
                ensure_installed = { "lua", "vim", "bash", "python", "javascript", "typescript", "json", "yaml", "toml", "markdown" },
                highlight = { enable = true },
                indent = { enable = true }
            })
        end
    },

    -- LSP
    { 'neovim/nvim-lspconfig' },
    { 'williamboman/mason.nvim', config = true },
    { 'williamboman/mason-lspconfig.nvim' },

    -- Completion
    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'L3MON4D3/LuaSnip' },
    { 'saadparwaiz1/cmp_luasnip' },

    -- File explorer
    { 'nvim-tree/nvim-tree.lua', dependencies = { 'nvim-tree/nvim-web-devicons' }, config = true },

    -- Status line
    { 'nvim-lualine/lualine.nvim', config = true },

    -- Git
    { 'lewis6991/gitsigns.nvim', config = true },

    -- Theme
    { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 }
}