-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ⚡ NVIM-CMP — ULTRA COMPLETION ENGINE v5.0 OMEGA                          ║
-- ║   20+ sources · custom formatters · ghost text · AI-aware · ASH theme-synced   ║
-- ║   per-filetype rules · fuzzy matching · emoji · cmdline · search completion    ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — premium completion menu colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Completion menu chrome ────────────────────────────────────────────────
    hl(0, "CmpNormal",                { link = "NormalFloat"              })
    hl(0, "CmpBorder",                { link = "FloatBorder"              })
    hl(0, "CmpScrollbar",             { link = "PmenuSbar"                })
    hl(0, "CmpScrollbarThumb",        { link = "PmenuThumb"               })
    hl(0, "CmpCursorLine",            { link = "PmenuSel"                 })
  
    -- ── Item kinds — each kind gets a distinct colour ─────────────────────────
    local kind_colours = {
      Text          = "#cdd6f4",
      Method        = "#89b4fa",
      Function      = "#89b4fa",
      Constructor   = "#f9e2af",
      Field         = "#89dceb",
      Variable      = "#cba6f7",
      Class         = "#f9e2af",
      Interface     = "#94e2d5",
      Module        = "#cba6f7",
      Property      = "#89dceb",
      Unit          = "#fab387",
      Value         = "#a6e3a1",
      Enum          = "#89dceb",
      Keyword       = "#f38ba8",
      Snippet       = "#a6e3a1",
      Color         = "#cba6f7",
      File          = "#89b4fa",
      Reference     = "#94e2d5",
      Folder        = "#89b4fa",
      EnumMember    = "#a6e3a1",
      Constant      = "#fab387",
      Struct        = "#f9e2af",
      Event         = "#f38ba8",
      Operator      = "#89b4fa",
      TypeParameter = "#94e2d5",
      Copilot       = "#6cc644",
      Codeium       = "#09B6A2",
      Supermaven    = "#6f6c99",
      TabNine       = "#ca42f0",
      RG            = "#f7768e",
      Buffer        = "#c0caf5",
      Path          = "#e0af68",
      Emoji         = "#f9e2af",
      Calc          = "#fab387",
      Spell         = "#9ece6a",
      Cmdline       = "#7aa2f7",
    }
  
    for kind, colour in pairs(kind_colours) do
      hl(0, "CmpItemKind" .. kind,    { bold = false, fg = colour         })
      hl(0, "CmpItemKindIcon" .. kind,{ bold = false, fg = colour         })
    end
  
    -- ── Selected item highlight ───────────────────────────────────────────────
    hl(0, "CmpItemAbbrMatch",         {
      bold      = true,
      fg        = "#7aa2f7",
    })
    hl(0, "CmpItemAbbrMatchFuzzy",    {
      bold      = true,
      italic    = true,
      fg        = "#7aa2f7",
    })
    hl(0, "CmpItemAbbr",              { fg = "#cdd6f4"                    })
    hl(0, "CmpItemAbbrDeprecated",    {
      strikethrough = true,
      fg            = "#6e738d",
    })
    hl(0, "CmpItemMenu",              {
      italic = true,
      fg     = "#9399b2",
    })
  
    -- ── Ghost text ────────────────────────────────────────────────────────────
    hl(0, "CmpGhostText",             {
      italic = true,
      fg     = "#6e738d",
    })
  
    -- ── Documentation float ───────────────────────────────────────────────────
    hl(0, "CmpDoc",                   { link = "NormalFloat"              })
    hl(0, "CmpDocBorder",             { link = "FloatBorder"              })
  
    -- ── Source badges ─────────────────────────────────────────────────────────
    hl(0, "CmpSourceLsp",             { bold = true, fg = "#7aa2f7"       })
    hl(0, "CmpSourceSnippet",         { bold = true, fg = "#a6e3a1"       })
    hl(0, "CmpSourceBuffer",          { bold = true, fg = "#c0caf5"       })
    hl(0, "CmpSourcePath",            { bold = true, fg = "#e0af68"       })
    hl(0, "CmpSourceCopilot",         { bold = true, fg = "#6cc644"       })
    hl(0, "CmpSourceCodeium",         { bold = true, fg = "#09B6A2"       })
    hl(0, "CmpSourceSupermaven",      { bold = true, fg = "#6f6c99"       })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue then
        hl(0, "CmpItemAbbrMatch",      { bold = true, fg = p.blue         })
        hl(0, "CmpItemAbbrMatchFuzzy", { bold = true, italic = true, fg = p.blue })
        hl(0, "CmpSourceLsp",          { bold = true, fg = p.blue         })
      end
      if p.text then hl(0, "CmpItemAbbr", { fg = p.text }) end
      local dim = p.overlay0 or p.subtext0 or "#6e738d"
      hl(0, "CmpGhostText",  { italic = true, fg = dim })
      hl(0, "CmpItemMenu",   { italic = true, fg = dim })
      hl(0, "CmpItemAbbrDeprecated", { strikethrough = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎯 KIND ICONS — Nerd Font v3 premium symbol set
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local KIND_ICONS = {
    Text          = "󰉿 ",
    Method        = "󰆧 ",
    Function      = "󰊕 ",
    Constructor   = " ",
    Field         = "󰜢 ",
    Variable      = "󰀫 ",
    Class         = "󰠱 ",
    Interface     = " ",
    Module        = "󰅩 ",
    Property      = "󰖷 ",
    Unit          = "󰑭 ",
    Value         = "󰎠 ",
    Enum          = " ",
    Keyword       = "󰌋 ",
    Snippet       = " ",
    Color         = "󰏘 ",
    File          = "󰈙 ",
    Reference     = " ",
    Folder        = "󰉋 ",
    EnumMember    = " ",
    Constant      = "󰏿 ",
    Struct        = "󱡠 ",
    Event         = " ",
    Operator      = "󰆕 ",
    TypeParameter = "󰊄 ",
    -- AI sources
    Copilot       = " ",
    Codeium       = "󰘦 ",
    Supermaven    = "󱙺 ",
    TabNine       = "󰘦 ",
    -- Other sources
    Buffer        = "󰦨 ",
    Path          = "󰉋 ",
    Emoji         = " ",
    Calc          = "󰃬 ",
    Spell         = "󰓆 ",
    Cmdline       = " ",
    Git           = "󰊢 ",
    Rg            = "󰊄 ",
    Treesitter    = "󰙅 ",
    NvimLua       = " ",
    Luasnip       = " ",
  }
  
  -- Source display labels
  local SOURCE_LABELS = {
    nvim_lsp              = " lsp",
    nvim_lua              = " lua",
    luasnip               = " snip",
    friendly_snippets     = " snip",
    buffer                = " buf",
    path                  = " path",
    calc                  = "󰃬 calc",
    spell                 = "󰓆 spell",
    emoji                 = " emoji",
    copilot               = " copilot",
    codeium               = "󰘦 codeium",
    supermaven            = "󱙺 smaven",
    cmdline               = " cmd",
    rg                    = " rg",
    git                   = "󰊢 git",
    treesitter            = "󰙅 ts",
    ["nvim-cmp-ts-tags"]  = " tags",
    nvim_lsp_document_symbol = " symbol",
    nvim_lsp_signature_help  = " sig",
    ["cmp-dbee"]          = "󰆼 db",
    ["cmp-npm"]           = " npm",
    cmdline_history       = "  hist",
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 CUSTOM FORMATTERS — rich item display
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Format completion items with icons, source labels and truncation
  local function format_item(entry, vim_item)
    local MAX_LABEL_WIDTH = 40
    local MAX_MENU_WIDTH  = 20
  
    -- ── Kind icon & label ─────────────────────────────────────────────────────
    local kind_name = vim_item.kind or "Text"
    local icon      = KIND_ICONS[kind_name] or "  "
  
    -- Detect AI-source overrides
    local source_name = entry.source.name
    if source_name == "copilot"   then icon = KIND_ICONS.Copilot   end
    if source_name == "codeium"   then icon = KIND_ICONS.Codeium   end
    if source_name == "supermaven" then icon = KIND_ICONS.Supermaven end
  
    vim_item.kind = icon .. " " .. kind_name
  
    -- ── Abbreviation (item label) truncation ──────────────────────────────────
    local label = vim_item.abbr or ""
    if #label > MAX_LABEL_WIDTH then
      vim_item.abbr = label:sub(1, MAX_LABEL_WIDTH - 1) .. "…"
    end
  
    -- ── Source menu label ──────────────────────────────────────────────────────
    local source_label = SOURCE_LABELS[source_name] or ("[" .. source_name .. "]")
    if #source_label > MAX_MENU_WIDTH then
      source_label = source_label:sub(1, MAX_MENU_WIDTH - 1) .. "…"
    end
    vim_item.menu = source_label
  
    -- ── Duplicate deduplication ────────────────────────────────────────────────
    vim_item.dup = ({
      nvim_lsp   = 0,
      nvim_lua   = 0,
      luasnip    = 1,
      buffer     = 1,
      path       = 1,
    })[source_name] or 0
  
    return vim_item
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SORTING COMPARATORS — smart item ordering
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function build_comparators(cmp)
    local compare = cmp.config.compare
  
    -- Deprioritise LSP items starting with underscore (private)
    local function deprioritise_underscore(entry1, entry2)
      local _, e1_under = entry1.completion_item.label:find("^_+")
      local _, e2_under = entry2.completion_item.label:find("^_+")
      e1_under = e1_under or 0
      e2_under = e2_under or 0
      if e1_under > e2_under then return false end
      if e1_under < e2_under then return true  end
    end
  
    -- Prioritise exact prefix matches
    local function prefer_prefix(entry1, entry2)
      local input = vim.fn.getcmdline() ~= "" and vim.fn.getcmdline()
        or vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
      local word  = input:match("[%w_]+$") or ""
      if word == "" then return nil end
      local l1 = entry1.completion_item.label:lower()
      local l2 = entry2.completion_item.label:lower()
      local w  = word:lower()
      local p1 = l1:sub(1, #w) == w
      local p2 = l2:sub(1, #w) == w
      if p1 and not p2 then return true  end
      if not p1 and p2 then return false end
    end
  
    return {
      prefer_prefix,
      compare.offset,
      compare.exact,
      compare.score,
      compare.recently_used,
      compare.locality,
      compare.kind,
      deprioritise_underscore,
      compare.sort_text,
      compare.length,
      compare.order,
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "hrsh7th/nvim-cmp",
      version      = false,
      event        = { "InsertEnter", "CmdlineEnter" },
  
      dependencies = {
        -- ── Core sources ─────────────────────────────────────────────────────
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-nvim-lsp-document-symbol",
        "hrsh7th/cmp-nvim-lsp-signature-help",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/cmp-calc",
        "hrsh7th/cmp-emoji",
        "hrsh7th/cmp-nvim-lua",
  
        -- ── Snippet engine ────────────────────────────────────────────────────
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
  
        -- ── Additional sources ────────────────────────────────────────────────
        { "lukas-reineke/cmp-rg",           optional = true },
        { "petertriho/cmp-git",             optional = true },
        { "David-Kunz/cmp-npm",             optional = true },
        { "f3fora/cmp-spell",               optional = true },
        { "ray-x/cmp-treesitter",           optional = true },
        { "bydlw98/cmp-env",                optional = true },
        { "Snikimonkeyc/cmp-vimtex",        ft = { "tex", "latex" } },
  
        -- ── AI completion ─────────────────────────────────────────────────────
        { "zbirenbaum/copilot-cmp",         optional = true },
        { "Exafunction/codeium.nvim",       optional = true },
        { "supermaven-inc/supermaven-nvim", optional = true },
  
        -- ── UI ────────────────────────────────────────────────────────────────
        { "onsails/lspkind.nvim",           optional = true },
        { "windwp/nvim-autopairs",          optional = true },
      },
  
      config = function()
        local cmp     = require("cmp")
        local luasnip = require("luasnip")
  
        setup_highlights()
  
        -- ── Snip helpers ──────────────────────────────────────────────────────
        local function has_words_before()
          local line, col = unpack(vim.api.nvim_win_get_cursor(0))
          return col ~= 0
            and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
                :sub(col, col):match("%s") == nil
        end
  
        local function snip_forward(fallback)
          if luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          elseif cmp.visible() then
            cmp.select_next_item()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end
  
        local function snip_backward(fallback)
          if luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          elseif cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end
  
        -- ── Build source list dynamically ────────────────────────────────────
        local function make_sources(overrides)
          local base = {
            -- Tier 1: highest quality
            { name = "nvim_lsp",              priority = 1000, max_item_count = 20  },
            { name = "luasnip",               priority = 900,  max_item_count = 8   },
            { name = "nvim_lsp_signature_help", priority = 850                      },
            -- Tier 2: AI
            { name = "copilot",               priority = 800,  max_item_count = 5   },
            { name = "codeium",               priority = 800,  max_item_count = 5   },
            { name = "supermaven",            priority = 790,  max_item_count = 5   },
            -- Tier 3: general
            { name = "nvim_lua",              priority = 700                        },
            { name = "path",                  priority = 600                        },
            { name = "buffer",                priority = 500,  max_item_count = 5,
              option = {
                get_bufnrs = function()
                  -- Complete from all visible buffers
                  local bufs = {}
                  for _, win in ipairs(vim.api.nvim_list_wins()) do
                    bufs[vim.api.nvim_win_get_buf(win)] = true
                  end
                  return vim.tbl_keys(bufs)
                end,
              },
            },
            -- Tier 4: extras
            { name = "calc",                  priority = 400                        },
            { name = "emoji",                 priority = 300                        },
            { name = "spell",                 priority = 200,  max_item_count = 5,
              option = { keep_all_entries = false, enable_in_context = function()
                return vim.opt.spell:get()
              end },
            },
          }
  
          -- Conditionally add ripgrep
          if vim.fn.executable("rg") == 1 then
            table.insert(base, {
              name            = "rg",
              priority        = 150,
              max_item_count  = 3,
              keyword_length  = 4,
              option          = { additional_arguments = "--smart-case --hidden" },
            })
          end
  
          -- Conditionally add treesitter
          local ok_ts = pcall(require, "nvim-treesitter")
          if ok_ts then
            table.insert(base, { name = "treesitter", priority = 250 })
          end
  
          if overrides then
            base = vim.list_extend(base, overrides)
          end
  
          return base
        end
  
        -- ── Global setup ──────────────────────────────────────────────────────
        cmp.setup({
          -- ── Snippet ─────────────────────────────────────────────────────────
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
  
          -- ── Completion behaviour ─────────────────────────────────────────────
          completion = {
            completeopt = "menu,menuone,noinsert",
            autocomplete = {
              cmp.TriggerEvent.InsertEnter,
              cmp.TriggerEvent.TextChanged,
            },
            keyword_length  = 1,
            keyword_pattern = [[\%(-\?\d\+\%(\.\d\+\)\?\|\h\w*\%(-\w*\)*\)]],
          },
  
          -- ── Preselect ───────────────────────────────────────────────────────
          preselect = cmp.PreselectMode.None,
  
          -- ── Window styling ───────────────────────────────────────────────────
          window = {
            completion = {
              border          = "rounded",
              winhighlight    = table.concat({
                "Normal:CmpNormal",
                "CursorLine:CmpCursorLine",
                "Search:None",
                "FloatBorder:CmpBorder",
              }, ","),
              scrollbar       = true,
              scrolloff       = 2,
              col_offset      = -3,
              side_padding    = 1,
              -- Fixed width for stable layout
              fixed_width     = 60,
            },
            documentation = {
              border          = "rounded",
              winhighlight    = table.concat({
                "Normal:CmpDoc",
                "FloatBorder:CmpDocBorder",
              }, ","),
              max_width       = 80,
              max_height      = 20,
            },
          },
  
          -- ── Item formatting ───────────────────────────────────────────────────
          formatting = {
            expandable_indicator = true,
            fields               = { "kind", "abbr", "menu" },
            format               = function(entry, vim_item)
              -- Try lspkind first for extra formatting
              local ok_lk, lspkind = pcall(require, "lspkind")
              if ok_lk then
                vim_item = lspkind.cmp_format({
                  mode              = "symbol_text",
                  maxwidth          = 40,
                  ellipsis_char     = "…",
                  symbol_map        = KIND_ICONS,
                  menu              = SOURCE_LABELS,
                  before            = function(e, vi) return format_item(e, vi) end,
                })(entry, vim_item)
              else
                vim_item = format_item(entry, vim_item)
              end
              return vim_item
            end,
          },
  
          -- ── Key mappings ──────────────────────────────────────────────────────
          mapping = cmp.mapping.preset.insert({
            -- Navigation
            ["<C-n>"]      = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
            ["<C-p>"]      = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
            ["<Down>"]     = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
            ["<Up>"]       = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
  
            -- Documentation scroll
            ["<C-d>"]      = cmp.mapping.scroll_docs(4),
            ["<C-u>"]      = cmp.mapping.scroll_docs(-4),
            ["<C-f>"]      = cmp.mapping.scroll_docs(8),
            ["<C-b>"]      = cmp.mapping.scroll_docs(-8),
  
            -- Confirm
            ["<CR>"]       = cmp.mapping.confirm({
              behavior    = cmp.ConfirmBehavior.Replace,
              select      = false,
            }),
            ["<C-y>"]      = cmp.mapping.confirm({
              behavior    = cmp.ConfirmBehavior.Replace,
              select      = true,
            }),
  
            -- Abort / close
            ["<C-e>"]      = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.abort()
              else
                fallback()
              end
            end),
            ["<Esc>"]      = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.close()
              else
                fallback()
              end
            end, { "i" }),
  
            -- Open / force complete
            ["<C-Space>"]  = cmp.mapping(function()
              if cmp.visible() then
                cmp.abort()
              else
                cmp.complete()
              end
            end),
  
            -- Snippet / tab navigation
            ["<Tab>"]      = cmp.mapping(snip_forward,  { "i", "s" }),
            ["<S-Tab>"]    = cmp.mapping(snip_backward, { "i", "s" }),
  
            -- Snippet jump without completion
            ["<C-l>"]      = cmp.mapping(function(fallback)
              if luasnip.jumpable(1) then
                luasnip.jump(1)
              else
                fallback()
              end
            end, { "i", "s" }),
            ["<C-h>"]      = cmp.mapping(function(fallback)
              if luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),
  
            -- Select first AI suggestion
            ["<M-CR>"]     = cmp.mapping(function(fallback)
              -- Dismiss AI virtual text and confirm first item
              for _, source_name in ipairs({ "copilot", "codeium", "supermaven" }) do
                local sources = cmp.get_config().sources or {}
                for _, s in ipairs(sources) do
                  if s.name == source_name then
                    cmp.complete({ config = { sources = { { name = source_name } } } })
                    cmp.confirm({ select = true })
                    return
                  end
                end
              end
              fallback()
            end, { "i" }),
          }),
  
          -- ── Sources ───────────────────────────────────────────────────────────
          sources = cmp.config.sources(make_sources()),
  
          -- ── Sorting ───────────────────────────────────────────────────────────
          sorting = {
            priority_weight  = 2,
            comparators      = build_comparators(cmp),
          },
  
          -- ── Ghost text ────────────────────────────────────────────────────────
          experimental = {
            ghost_text = {
              hl_group = "CmpGhostText",
            },
          },
  
          -- ── Performance ───────────────────────────────────────────────────────
          performance = {
            debounce           = 60,
            throttle           = 30,
            fetching_timeout   = 200,
            confirm_resolve_timeout = 80,
            async_budget       = 1,
            max_view_entries   = 25,
          },
  
          -- ── Match config ──────────────────────────────────────────────────────
          matching = {
            disallow_fuzzy_matching      = false,
            disallow_fullfuzzy_matching  = false,
            disallow_partial_fuzzy_matching = false,
            disallow_partial_matching    = false,
            disallow_prefix_unmatching   = false,
            disallow_symbol_nonprefix_matching = true,
          },
        })
  
        -- ── Filetype-specific configurations ─────────────────────────────────────
  
        -- Git commit: git source
        cmp.setup.filetype({ "gitcommit", "NeogitCommitMessage" }, {
          sources = cmp.config.sources({
            { name = "git",     priority = 1000 },
            { name = "luasnip", priority = 900  },
            { name = "buffer",  priority = 500  },
            { name = "spell",   priority = 300  },
            { name = "emoji",   priority = 200  },
          }),
        })
  
        -- Lua: nvim-lua source
        cmp.setup.filetype("lua", {
          sources = cmp.config.sources(make_sources({
            { name = "nvim_lua", priority = 950 },
          })),
        })
  
        -- LaTeX / TeX: vimtex source
        cmp.setup.filetype({ "tex", "latex" }, {
          sources = cmp.config.sources({
            { name = "vimtex",  priority = 1000 },
            { name = "nvim_lsp", priority = 900 },
            { name = "luasnip", priority = 800  },
            { name = "buffer",  priority = 400  },
            { name = "spell",   priority = 300  },
          }),
        })
  
        -- Markdown / Org: prose-focused
        cmp.setup.filetype({ "markdown", "org", "neorg", "text", "rst" }, {
          sources = cmp.config.sources({
            { name = "luasnip", priority = 900  },
            { name = "spell",   priority = 800  },
            { name = "buffer",  priority = 700  },
            { name = "path",    priority = 600  },
            { name = "emoji",   priority = 500  },
            { name = "calc",    priority = 300  },
          }),
        })
  
        -- SQL: database completion
        cmp.setup.filetype({ "sql", "mysql", "plsql" }, {
          sources = cmp.config.sources({
            { name = "vim-dadbod-completion", priority = 1000 },
            { name = "nvim_lsp",              priority = 900  },
            { name = "buffer",                priority = 500  },
            { name = "luasnip",               priority = 400  },
          }),
        })
  
        -- Shell / Fish: path completion emphasis
        cmp.setup.filetype({ "sh", "bash", "zsh", "fish" }, {
          sources = cmp.config.sources({
            { name = "nvim_lsp", priority = 1000 },
            { name = "luasnip",  priority = 900  },
            { name = "path",     priority = 800  },
            { name = "buffer",   priority = 500  },
          }),
        })
  
        -- ── Cmdline: / and ? search ────────────────────────────────────────────
        cmp.setup.cmdline({ "/", "?" }, {
          mapping = cmp.mapping.preset.cmdline({
            ["<C-n>"] = cmp.mapping(cmp.mapping.select_next_item(), { "c" }),
            ["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "c" }),
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp_document_symbol", priority = 1000 },
          }, {
            { name = "buffer", priority = 500 },
          }),
          formatting = {
            fields = { "abbr", "menu" },
            format = function(entry, vim_item)
              vim_item.menu = SOURCE_LABELS[entry.source.name] or ""
              return vim_item
            end,
          },
        })
  
        -- ── Cmdline: : command completion ────────────────────────────────────────
        cmp.setup.cmdline(":", {
          mapping = cmp.mapping.preset.cmdline({
            ["<C-n>"] = cmp.mapping(cmp.mapping.select_next_item(), { "c" }),
            ["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "c" }),
            ["<Tab>"] = cmp.mapping(cmp.mapping.select_next_item(), { "c" }),
            ["<S-Tab>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "c" }),
          }),
          sources = cmp.config.sources({
            { name = "path",    priority = 1000 },
          }, {
            {
              name             = "cmdline",
              priority         = 900,
              option           = {
                ignore_cmds    = { "Man", "!" },
              },
            },
          }),
          formatting = {
            fields = { "abbr", "menu" },
            format = function(entry, vim_item)
              vim_item.kind = KIND_ICONS[vim_item.kind] or ""
              vim_item.menu = SOURCE_LABELS[entry.source.name] or ""
              return vim_item
            end,
          },
        })
  
        -- ── autopairs integration ──────────────────────────────────────────────
        local ok_ap, autopairs_cmp = pcall(require, "nvim-autopairs.completion.cmp")
        if ok_ap then
          cmp.event:on("confirm_done", autopairs_cmp.on_confirm_done())
        end
  
        -- ── Git source setup ───────────────────────────────────────────────────
        local ok_git, cmp_git = pcall(require, "cmp_git")
        if ok_git then
          cmp_git.setup({
            filetypes          = { "gitcommit", "NeogitCommitMessage", "octo" },
            remotes            = { "upstream", "origin" },
            git                = { commits = { limit = 100 } },
            github             = {
              issues           = { filter = "all", limit = 100, state = "open" },
              mentions         = { limit = 100 },
              pull_requests    = { limit = 100, state = "open" },
            },
            gitlab             = {
              issues           = { limit = 100 },
              mentions         = { limit = 100 },
              merge_requests   = { limit = 100 },
            },
            trigger_actions    = {
              { debug_name = "git_commits", trigger_character = ":",
                action     = function(sources, trigger_char, callback, params, git_info)
                  return sources.git:get_commits(callback, params, trigger_char)
                end,
              },
              { debug_name = "github_issues", trigger_character = "#",
                action     = function(sources, trigger_char, callback, params, git_info)
                  return sources.github:get_issues(callback, git_info, trigger_char)
                end,
              },
              { debug_name = "github_pulls", trigger_character = "!",
                action     = function(sources, trigger_char, callback, params, git_info)
                  return sources.github:get_pull_requests(callback, git_info, trigger_char)
                end,
              },
              { debug_name = "github_mentions", trigger_character = "@",
                action     = function(sources, trigger_char, callback, params, git_info)
                  return sources.github:get_mentions(callback, git_info, trigger_char)
                end,
              },
            },
          })
        end
  
        -- ── Autocmds ──────────────────────────────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshCmp", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify(
              "⚡ nvim-cmp highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH cmp", timeout = 1200 }
            )
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format(
              "⚡ nvim-cmp loaded — %d kind icons, %d sources",
              vim.tbl_count(KIND_ICONS),
              vim.tbl_count(SOURCE_LABELS)
            ),
            vim.log.levels.DEBUG,
            { title = "ASH cmp" }
          )
        end
      end,
    },
  }