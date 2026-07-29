-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📝 MARKDOWN — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                          ║
-- ║   render-markdown · preview · toc · tables · mermaid · math · ASH theme       ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Heading levels — progressive colour ladder ────────────────────────────
    hl(0, "RenderMarkdownH1",        { bold = true,   fg = "#7aa2f7" })
    hl(0, "RenderMarkdownH2",        { bold = true,   fg = "#9ece6a" })
    hl(0, "RenderMarkdownH3",        { bold = true,   fg = "#e0af68" })
    hl(0, "RenderMarkdownH4",        { bold = true,   fg = "#f7768e" })
    hl(0, "RenderMarkdownH5",        { bold = true,   fg = "#bb9af7" })
    hl(0, "RenderMarkdownH6",        { bold = true,   fg = "#73daca" })
  
    -- ── Heading background pills ──────────────────────────────────────────────
    hl(0, "RenderMarkdownH1Bg",      { bg = "#1e2d4a"              })
    hl(0, "RenderMarkdownH2Bg",      { bg = "#1a2b1a"              })
    hl(0, "RenderMarkdownH3Bg",      { bg = "#2d2a1e"              })
    hl(0, "RenderMarkdownH4Bg",      { bg = "#2d1b1e"              })
    hl(0, "RenderMarkdownH5Bg",      { bg = "#25182d"              })
    hl(0, "RenderMarkdownH6Bg",      { bg = "#1a2d2d"              })
  
    -- ── Code blocks ───────────────────────────────────────────────────────────
    hl(0, "RenderMarkdownCode",      { bg = "#1e2030"              })
    hl(0, "RenderMarkdownCodeInline",{ bg = "#1e2030", fg = "#cdd6f4" })
    hl(0, "RenderMarkdownCodeBorder",{ fg = "#414868"              })
  
    -- ── Blockquotes / callouts ────────────────────────────────────────────────
    hl(0, "RenderMarkdownQuote",     { fg = "#9399b2", italic = true })
    hl(0, "RenderMarkdownCalloutNote",    { bold = true, fg = "#7aa2f7" })
    hl(0, "RenderMarkdownCalloutTip",     { bold = true, fg = "#9ece6a" })
    hl(0, "RenderMarkdownCalloutWarn",    { bold = true, fg = "#e0af68" })
    hl(0, "RenderMarkdownCalloutImportant",{ bold = true,fg = "#bb9af7" })
    hl(0, "RenderMarkdownCalloutCaution", { bold = true, fg = "#f7768e" })
  
    -- ── Tables ────────────────────────────────────────────────────────────────
    hl(0, "RenderMarkdownTableHead",  { bold = true,   fg = "#7aa2f7" })
    hl(0, "RenderMarkdownTableRow",   { fg = "#cdd6f4"                })
    hl(0, "RenderMarkdownTableFill",  { fg = "#414868"                })
  
    -- ── List bullets ─────────────────────────────────────────────────────────
    hl(0, "RenderMarkdownBullet",     { bold = true,   fg = "#7aa2f7" })
    hl(0, "RenderMarkdownOrderedList",{ bold = true,   fg = "#9ece6a" })
  
    -- ── Task checkboxes ───────────────────────────────────────────────────────
    hl(0, "RenderMarkdownChecked",   { bold = true, fg = "#9ece6a" })
    hl(0, "RenderMarkdownUnchecked", { fg = "#9399b2"              })
    hl(0, "RenderMarkdownTodo",      { bold = true, fg = "#e0af68" })
  
    -- ── Links ─────────────────────────────────────────────────────────────────
    hl(0, "RenderMarkdownLink",      { underline = true, fg = "#89b4fa" })
    hl(0, "RenderMarkdownWikiLink",  { underline = true, fg = "#cba6f7" })
    hl(0, "RenderMarkdownImage",     { italic = true, fg = "#73daca"    })
  
    -- ── Horizontal rule ───────────────────────────────────────────────────────
    hl(0, "RenderMarkdownDash",      { fg = "#414868"              })
  
    -- ── Math ─────────────────────────────────────────────────────────────────
    hl(0, "RenderMarkdownMath",      { italic = true, fg = "#9ece6a" })
  
    -- ── Native markdown ───────────────────────────────────────────────────────
    hl(0, "@markup.heading.1.markdown", { bold = true, fg = "#7aa2f7", bg = "#1e2d4a" })
    hl(0, "@markup.heading.2.markdown", { bold = true, fg = "#9ece6a", bg = "#1a2b1a" })
    hl(0, "@markup.heading.3.markdown", { bold = true, fg = "#e0af68", bg = "#2d2a1e" })
    hl(0, "@markup.heading.4.markdown", { bold = true, fg = "#f7768e"               })
    hl(0, "@markup.heading.5.markdown", { bold = true, fg = "#bb9af7"               })
    hl(0, "@markup.heading.6.markdown", { bold = true, fg = "#73daca"               })
    hl(0, "@markup.raw.markdown_inline",{ fg = "#7dcfff", bg = "#1e2030"            })
    hl(0, "@markup.link.label.markdown",{ underline = true, fg = "#89b4fa"          })
    hl(0, "@markup.italic.markdown_inline", { italic = true                         })
    hl(0, "@markup.strong.markdown_inline", { bold   = true                         })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "RenderMarkdownH1",       { bold = true, fg = p.blue })
        hl(0, "RenderMarkdownBullet",   { bold = true, fg = p.blue })
        hl(0, "RenderMarkdownTableHead",{ bold = true, fg = p.blue })
      end
      if p.green  then
        hl(0, "RenderMarkdownH2",       { bold = true, fg = p.green })
        hl(0, "RenderMarkdownChecked",  { bold = true, fg = p.green })
      end
      if p.yellow then
        hl(0, "RenderMarkdownH3",       { bold = true, fg = p.yellow })
        hl(0, "RenderMarkdownTodo",     { bold = true, fg = p.yellow })
      end
      if p.surface1 then
        hl(0, "RenderMarkdownCode",     { bg = p.surface1 })
        hl(0, "RenderMarkdownH1Bg",     { bg = p.surface1 })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 MARKDOWN UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Generate / update Table of Contents
  local function generate_toc()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local toc   = { "<!-- toc -->", "" }
    local in_code_block = false
  
    for _, line in ipairs(lines) do
      if line:match("^```") then
        in_code_block = not in_code_block
      end
      if not in_code_block then
        local level, title = line:match("^(#+)%s+(.+)$")
        if level and title then
          local depth  = #level - 1
          local anchor = title:lower()
            :gsub("[^%w%s%-]", "")
            :gsub("%s+", "-")
            :gsub("^%-+", "")
            :gsub("%-+$", "")
          local indent = string.rep("  ", depth)
          table.insert(toc, string.format("%s- [%s](#%s)", indent, title, anchor))
        end
      end
    end
  
    table.insert(toc, "")
    table.insert(toc, "<!-- tocstop -->")
  
    -- Find existing TOC markers
    local toc_start, toc_end
    for i, line in ipairs(lines) do
      if line:match("<!-- toc -->") then toc_start = i end
      if line:match("<!-- tocstop -->") then toc_end = i end
    end
  
    if toc_start and toc_end then
      -- Replace existing TOC
      vim.api.nvim_buf_set_lines(bufnr, toc_start - 1, toc_end, false, toc)
      vim.notify("📝 TOC updated", vim.log.levels.INFO, { title = "Markdown", timeout = 1200 })
    else
      -- Insert at current line
      local row = vim.api.nvim_win_get_cursor(0)[1]
      vim.api.nvim_buf_set_lines(bufnr, row, row, false, toc)
      vim.notify("📝 TOC inserted", vim.log.levels.INFO, { title = "Markdown", timeout = 1200 })
    end
  end
  
  -- Format markdown table under cursor
  local function format_table()
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({ async = true, formatters = { "prettierd", "prettier" } })
    else
      vim.lsp.buf.format({ async = true })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- ── render-markdown.nvim — beautiful inline rendering ─────────────────────────
    {
      "MeanderingProgrammer/render-markdown.nvim",
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
      },
      ft = { "markdown", "norg", "rmd", "org", "codecompanion", "Avante" },
  
      keys = {
        { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>",  ft = { "markdown" }, desc = "📝 Markdown: Toggle render"    },
        { "<leader>mR", "<cmd>RenderMarkdown expand<cr>",  ft = { "markdown" }, desc = "📝 Markdown: Expand"           },
        { "<leader>mC", "<cmd>RenderMarkdown contract<cr>",ft = { "markdown" }, desc = "📝 Markdown: Contract"         },
        { "<leader>mt", generate_toc,                      ft = { "markdown" }, desc = "📝 Markdown: Generate TOC"     },
        { "<leader>mf", format_table,                      ft = { "markdown" }, desc = "📝 Markdown: Format table"     },
        {
          "<leader>mp",
          function()
            local ok, prev = pcall(require, "markdown-preview")
            if ok then
              vim.cmd("MarkdownPreviewToggle")
            else
              vim.notify("📝 markdown-preview not installed", vim.log.levels.WARN,
                { title = "Markdown" })
            end
          end,
          ft   = { "markdown" },
          desc = "📝 Markdown: Preview in browser",
        },
      },
  
      opts = {
        -- ── Enable ────────────────────────────────────────────────────────────
        enabled     = true,
        max_file_size = 10.0,       -- MB
        debounce    = 100,
  
        -- ── File types ────────────────────────────────────────────────────────
        file_types  = { "markdown", "norg", "rmd", "org" },
        render_modes= { "n", "c", "t" },
        anti_conceal= {
          enabled           = true,
          ignore            = {
            code_background = true,
            sign            = true,
          },
          above             = 0,
          below             = 0,
        },
  
        -- ── Padding (before/after) ────────────────────────────────────────────
        padding = {
          highlight = "Normal",
        },
  
        -- ── Headings ──────────────────────────────────────────────────────────
        heading = {
          enabled      = true,
          render_modes = false,
          atx          = true,
          setext       = true,
          sign         = true,
          icons        = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
          signs        = { "󰫎 " },
          width        = "full",
          left_margin  = 0,
          left_pad     = 0,
          right_pad    = 0,
          min_width    = 0,
          border       = false,
          border_virtual = false,
          border_prefix = false,
          above        = "▄",
          below        = "▀",
          backgrounds  = {
            "RenderMarkdownH1Bg",
            "RenderMarkdownH2Bg",
            "RenderMarkdownH3Bg",
            "RenderMarkdownH4Bg",
            "RenderMarkdownH5Bg",
            "RenderMarkdownH6Bg",
          },
          foregrounds = {
            "RenderMarkdownH1",
            "RenderMarkdownH2",
            "RenderMarkdownH3",
            "RenderMarkdownH4",
            "RenderMarkdownH5",
            "RenderMarkdownH6",
          },
        },
  
        -- ── Paragraphs ────────────────────────────────────────────────────────
        paragraph = {
          enabled  = true,
          left_margin = 0,
          min_width= 0,
        },
  
        -- ── Code blocks ───────────────────────────────────────────────────────
        code = {
          enabled         = true,
          render_modes    = false,
          sign            = true,
          style           = "full",
          position        = "left",
          language_pad    = 0,
          language_name   = true,
          disable_background = { "diff" },
          width           = "full",
          left_margin     = 0,
          left_pad        = 1,
          right_pad       = 1,
          min_width       = 0,
          border          = "thin",
          above           = "▄",
          below           = "▀",
          highlight       = "RenderMarkdownCode",
          highlight_inline= "RenderMarkdownCodeInline",
          highlight_language = nil,
        },
  
        -- ── Dash (horizontal rule) ─────────────────────────────────────────────
        dash = {
          enabled  = true,
          render_modes = false,
          icon     = "─",
          width    = "full",
          highlight= "RenderMarkdownDash",
        },
  
        -- ── Bullet list ───────────────────────────────────────────────────────
        bullet = {
          enabled      = true,
          render_modes = false,
          icons        = { "●", "○", "◆", "◇" },
          ordered_icons= function(ctx)
            return string.format("%d.", ctx.index)
          end,
          left_pad     = 0,
          right_pad    = 0,
          highlight    = "RenderMarkdownBullet",
        },
  
        -- ── Checkboxes ────────────────────────────────────────────────────────
        checkbox = {
          enabled      = true,
          render_modes = false,
          position     = "inline",
          unchecked    = { icon = "󰄱 ", highlight = "RenderMarkdownUnchecked", scope_highlight = nil },
          checked      = { icon = "󰱒 ", highlight = "RenderMarkdownChecked",   scope_highlight = nil },
          custom       = {
            todo   = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
            doing  = { raw = "[~]", rendered = "󰑖 ", highlight = "RenderMarkdownTodo" },
          },
        },
  
        -- ── Quotes ────────────────────────────────────────────────────────────
        quote = {
          enabled      = true,
          render_modes = false,
          icon         = "▋",
          repeat_linebreak = false,
          highlight    = "RenderMarkdownQuote",
        },
  
        -- ── Callouts ──────────────────────────────────────────────────────────
        callout = {
          note     = { raw = "[!NOTE]",      rendered = "󰋽 Note",      highlight = "RenderMarkdownCalloutNote"      },
          tip      = { raw = "[!TIP]",       rendered = "󰌶 Tip",       highlight = "RenderMarkdownCalloutTip"       },
          important= { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownCalloutImportant" },
          warning  = { raw = "[!WARNING]",   rendered = "󰀪 Warning",   highlight = "RenderMarkdownCalloutWarn"      },
          caution  = { raw = "[!CAUTION]",   rendered = "󰳦 Caution",   highlight = "RenderMarkdownCalloutCaution"   },
          abstract = { raw = "[!ABSTRACT]",  rendered = "󱙫 Abstract",  highlight = "RenderMarkdownCalloutNote"      },
          summary  = { raw = "[!SUMMARY]",   rendered = "󱙫 Summary",   highlight = "RenderMarkdownCalloutNote"      },
          tldr     = { raw = "[!TLDR]",      rendered = "󱙫 Tldr",      highlight = "RenderMarkdownCalloutNote"      },
          info     = { raw = "[!INFO]",      rendered = "󰋽 Info",      highlight = "RenderMarkdownCalloutNote"      },
          todo     = { raw = "[!TODO]",      rendered = "󰗡 Todo",      highlight = "RenderMarkdownTodo"             },
          hint     = { raw = "[!HINT]",      rendered = "󰌶 Hint",      highlight = "RenderMarkdownCalloutTip"       },
          success  = { raw = "[!SUCCESS]",   rendered = "󰄬 Success",   highlight = "RenderMarkdownCalloutTip"       },
          check    = { raw = "[!CHECK]",     rendered = "󰄬 Check",     highlight = "RenderMarkdownCalloutTip"       },
          done     = { raw = "[!DONE]",      rendered = "󰄬 Done",      highlight = "RenderMarkdownCalloutTip"       },
          question = { raw = "[!QUESTION]",  rendered = "󰘥 Question",  highlight = "RenderMarkdownCalloutWarn"      },
          help     = { raw = "[!HELP]",      rendered = "󰘥 Help",      highlight = "RenderMarkdownCalloutWarn"      },
          faq      = { raw = "[!FAQ]",       rendered = "󰘥 Faq",       highlight = "RenderMarkdownCalloutWarn"      },
          attention= { raw = "[!ATTENTION]", rendered = "󰀪 Attention", highlight = "RenderMarkdownCalloutWarn"      },
          failure  = { raw = "[!FAILURE]",   rendered = "󰅖 Failure",   highlight = "RenderMarkdownCalloutCaution"   },
          fail     = { raw = "[!FAIL]",      rendered = "󰅖 Fail",      highlight = "RenderMarkdownCalloutCaution"   },
          missing  = { raw = "[!MISSING]",   rendered = "󰅖 Missing",   highlight = "RenderMarkdownCalloutCaution"   },
          danger   = { raw = "[!DANGER]",    rendered = "󱐌 Danger",    highlight = "RenderMarkdownCalloutCaution"   },
          error    = { raw = "[!ERROR]",     rendered = "󱐌 Error",     highlight = "RenderMarkdownCalloutCaution"   },
          bug      = { raw = "[!BUG]",       rendered = "󰨰 Bug",       highlight = "RenderMarkdownCalloutCaution"   },
          example  = { raw = "[!EXAMPLE]",   rendered = "󰉹 Example",   highlight = "RenderMarkdownCalloutNote"      },
          quote    = { raw = "[!QUOTE]",     rendered = "󱆨 Quote",     highlight = "RenderMarkdownQuote"            },
          cite     = { raw = "[!CITE]",      rendered = "󱆨 Cite",      highlight = "RenderMarkdownQuote"            },
        },
  
        -- ── Links ─────────────────────────────────────────────────────────────
        link = {
          enabled         = true,
          render_modes    = false,
          footnote        = { superscript = true, prefix = "", suffix = "" },
          image           = "󰥶 ",
          email           = "󰀓 ",
          hyperlink       = "󰌹 ",
          highlight       = "RenderMarkdownLink",
          wiki            = { icon = "󱗖 ", body = nil, highlight = "RenderMarkdownWikiLink" },
          custom          = {
            web  = { pattern = "^http", icon = "󰖟 " },
            git  = { pattern = "^git",  icon = "󰊢 " },
          },
        },
  
        -- ── Signs ─────────────────────────────────────────────────────────────
        sign = {
          enabled   = true,
          highlights= {
            "RenderMarkdownH1",
            "RenderMarkdownH2",
            "RenderMarkdownH3",
            "RenderMarkdownH4",
            "RenderMarkdownH5",
            "RenderMarkdownH6",
          },
        },
  
        -- ── Inline highlights ─────────────────────────────────────────────────
        inline_highlight = {
          enabled   = true,
          highlight = "RenderMarkdownCode",
        },
  
        -- ── Tables ────────────────────────────────────────────────────────────
        pipe_table = {
          enabled    = true,
          render_modes = false,
          preset     = "double",
          style      = "full",
          cell       = "padded",
          padding    = 1,
          min_width  = 0,
          border     = { "┌", "┬", "┐", "├", "┼", "┤", "└", "┴", "┘", "│", "─" },
          alignment_indicator = "━",
          head       = "RenderMarkdownTableHead",
          row        = "RenderMarkdownTableRow",
          filler     = "RenderMarkdownTableFill",
        },
  
        -- ── Math (latex) ──────────────────────────────────────────────────────
        latex = {
          enabled   = vim.fn.executable("latex2text") == 1
            or vim.fn.executable("latex") == 1,
          converter = "latex2text",
          highlight = "RenderMarkdownMath",
          top_pad   = 0,
          bot_pad   = 0,
        },
  
        -- ── Indented code blocks ─────────────────────────────────────────────
        html = {
          enabled = false,
          comment = {
            conceal   = false,
            highlight = "RenderMarkdownHtmlComment",
          },
        },
  
        -- ── Overrides ─────────────────────────────────────────────────────────
        overrides = {
          buftype = {
            nofile = {
              padding = { highlight = "NormalFloat" },
              sign    = { enabled = false },
            },
          },
          filetype = {
            ["codecompanion"] = {
              sign = { enabled = false },
            },
          },
        },
      },
  
      config = function(_, opts)
        require("render-markdown").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshMarkdown", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "markdown", "norg", "org" },
          callback = function()
            vim.opt_local.expandtab    = true
            vim.opt_local.shiftwidth   = 2
            vim.opt_local.tabstop      = 2
            vim.opt_local.softtabstop  = 2
            vim.opt_local.textwidth    = 80
            vim.opt_local.wrap         = true
            vim.opt_local.linebreak    = true
            vim.opt_local.spell        = true
            vim.opt_local.spelllang    = "en_us"
            vim.opt_local.conceallevel = 2
            vim.opt_local.concealcursor= "nc"
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("📝 Markdown highlights synced", vim.log.levels.INFO,
              { title = "ASH Markdown", timeout = 1200 })
          end,
        })
      end,
    },
  
    -- ── markdown-preview.nvim ─────────────────────────────────────────────────────
    {
      "iamcco/markdown-preview.nvim",
      cmd    = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
      ft     = { "markdown" },
      build  = function() vim.fn["mkdp#util#install"]() end,
      keys   = {
        { "<leader>mP", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "📝 Markdown: Preview" },
      },
      init   = function()
        vim.g.mkdp_filetypes   = { "markdown" }
        vim.g.mkdp_auto_close  = 1
        vim.g.mkdp_refresh_slow= 0
        vim.g.mkdp_theme       = "dark"
        vim.g.mkdp_markdown_css= ""
        vim.g.mkdp_highlight_css = ""
        vim.g.mkdp_port          = ""
        vim.g.mkdp_page_title    = '「${name}」'
        vim.g.mkdp_preview_options = {
          mkit              = {},
          katex             = {},
          uml               = {},
          maid              = {},
          disable_sync_scroll = 0,
          sync_scroll_type  = "middle",
          hide_yaml_meta    = 1,
          sequence_diagrams = {},
          flowchart_diagrams= {},
          content_editable  = false,
          disable_filename  = 0,
          toc               = {},
        }
      end,
    },
  }