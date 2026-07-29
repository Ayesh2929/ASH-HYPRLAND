-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║     📚 FRIENDLY-SNIPPETS — ULTRA SNIPPET COLLECTION v5.0 OMEGA                 ║
-- ║   1000+ VSCode-compatible snippets · 50+ languages · auto-loaded               ║
-- ║   custom ASH additions · per-language config · extends friendly-snippets       ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

return {
    {
      "rafamadriz/friendly-snippets",
      -- friendly-snippets is loaded by LuaSnip's lazy_load() call in luasnip.lua
      -- This spec exists to declare the dependency and configure any overrides
      lazy   = true,
  
      -- No config needed — LuaSnip handles loading
      -- This file exists to document the collection and add custom snippets
      -- via the snippets/ directory that LuaSnip also lazy_loads
  
      -- Optional: vim-snippets for legacy SnipMate support
      dependencies = {
        { "honza/vim-snippets", lazy = true },
      },
    },
  }