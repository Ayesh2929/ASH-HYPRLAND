-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📐 LATEX — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                             ║
-- ║   vimtex · texlab · latexindent · latexmk · PDF preview · SyncTeX             ║
-- ║   snippets · math · bibliography · ASH theme-synced                            ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── texlab LSP tokens ─────────────────────────────────────────────────────
    hl(0, "@lsp.type.class.latex",       { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.function.latex",    { fg = "#89b4fa"                })
    hl(0, "@lsp.type.variable.latex",    { fg = "#cba6f7"                })
    hl(0, "@lsp.type.string.latex",      { fg = "#a6e3a1"                })
    hl(0, "@lsp.type.keyword.latex",     { bold = true,   fg = "#f38ba8" })
    hl(0, "@lsp.type.comment.latex",     { italic = true, fg = "#9399b2" })
    hl(0, "@lsp.type.macro.latex",       { bold = true,   fg = "#7aa2f7" })
    hl(0, "@lsp.type.operator.latex",    { fg = "#89b4fa"                })
    hl(0, "@lsp.type.number.latex",      { fg = "#fab387"                })
    hl(0, "@lsp.type.parameter.latex",   { italic = true, fg = "#c8c8c8" })
    hl(0, "@lsp.type.environment.latex", { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.math.latex",        { fg = "#9ece6a"                })
  
    -- ── Treesitter LaTeX ──────────────────────────────────────────────────────
    hl(0, "@keyword.latex",          { bold = true,   fg = "#7aa2f7" })
    hl(0, "@function.latex",         { fg = "#89b4fa"                })
    hl(0, "@string.latex",           { fg = "#a6e3a1"                })
    hl(0, "@comment.latex",          { italic = true, fg = "#9399b2" })
    hl(0, "@text.math.latex",        { fg = "#9ece6a"                })
    hl(0, "@text.reference.latex",   { underline = true, fg = "#89b4fa" })
    hl(0, "@text.title.latex",       { bold = true,   fg = "#f9e2af" })
    hl(0, "@text.emphasis.latex",    { italic = true                  })
    hl(0, "@text.strong.latex",      { bold = true                    })
    hl(0, "@operator.latex",         { fg = "#89b4fa"                })
  
    -- ── LaTeX-specific ────────────────────────────────────────────────────────
    hl(0, "LatexMath",         { fg = "#9ece6a"                })
    hl(0, "LatexEnvironment",  { bold = true,   fg = "#f9e2af" })
    hl(0, "LatexCommand",      { bold = true,   fg = "#7aa2f7" })
    hl(0, "LatexSection",      { bold = true,   fg = "#cba6f7" })
    hl(0, "LatexBibRef",       { underline = true, fg = "#89b4fa" })
    hl(0, "LatexLabel",        { italic = true, fg = "#94e2d5" })
    hl(0, "LatexDimension",    { fg = "#fab387"                })
    hl(0, "LatexSpecialChar",  { bold = true,   fg = "#7dcfff" })
    hl(0, "LatexMathOp",       { bold = true,   fg = "#9ece6a" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "@keyword.latex",       { bold = true, fg = p.blue })
        hl(0, "LatexCommand",         { bold = true, fg = p.blue })
      end
      if p.yellow then
        hl(0, "@lsp.type.class.latex",{ bold = true, fg = p.yellow })
        hl(0, "LatexEnvironment",     { bold = true, fg = p.yellow })
      end
      if p.green  then
        hl(0, "LatexMath",            { fg = p.green })
        hl(0, "LatexMathOp",          { bold = true, fg = p.green })
      end
      if p.mauve  then hl(0, "LatexSection", { bold = true, fg = p.mauve }) end
      if p.teal   then hl(0, "LatexLabel",   { italic = true, fg = p.teal }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 LATEX UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function detect_pdf_viewer()
    local viewers = { "zathura", "okular", "evince", "mupdf", "xdg-open", "open" }
    for _, v in ipairs(viewers) do
      if vim.fn.executable(v) == 1 then return v end
    end
    return "xdg-open"
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- ── vimtex — the LaTeX powerhouse ─────────────────────────────────────────────
    {
      "lervag/vimtex",
      ft    = { "tex", "latex", "plaintex", "bib" },
      lazy  = false,
  
      keys = {
        { "<leader>lxc",  "<plug>(vimtex-compile)",         ft = { "tex", "latex" }, desc = "📐 LaTeX: Compile"         },
        { "<leader>lxC",  "<plug>(vimtex-compile-output)",  ft = { "tex", "latex" }, desc = "📐 LaTeX: Compile output"  },
        { "<leader>lxv",  "<plug>(vimtex-view)",            ft = { "tex", "latex" }, desc = "📐 LaTeX: View PDF"        },
        { "<leader>lxt",  "<plug>(vimtex-toc-open)",        ft = { "tex", "latex" }, desc = "📐 LaTeX: TOC"             },
        { "<leader>lxT",  "<plug>(vimtex-toc-toggle)",      ft = { "tex", "latex" }, desc = "📐 LaTeX: Toggle TOC"      },
        { "<leader>lxe",  "<plug>(vimtex-errors)",          ft = { "tex", "latex" }, desc = "📐 LaTeX: Errors"          },
        { "<leader>lxs",  "<plug>(vimtex-stop)",            ft = { "tex", "latex" }, desc = "📐 LaTeX: Stop compilation"},
        { "<leader>lxS",  "<plug>(vimtex-status)",          ft = { "tex", "latex" }, desc = "📐 LaTeX: Status"          },
        { "<leader>lxw",  "<plug>(vimtex-count-words)",     ft = { "tex", "latex" }, desc = "📐 LaTeX: Word count"      },
        { "<leader>lxl",  "<plug>(vimtex-log)",             ft = { "tex", "latex" }, desc = "📐 LaTeX: View log"        },
        { "<leader>lxr",  "<plug>(vimtex-reverse-search)",  ft = { "tex", "latex" }, desc = "📐 LaTeX: Reverse search"  },
        { "<leader>lxo",  "<plug>(vimtex-compile-selected)",ft = { "tex", "latex" }, desc = "📐 LaTeX: Compile selected", mode = "v" },
        {
          "<leader>lxi",
          function()
            local pv      = detect_pdf_viewer()
            local ltx_v   = vim.fn.trim(vim.fn.system("latex --version 2>/dev/null | head -1"))
            local latexmk = vim.fn.trim(vim.fn.system("latexmk --version 2>/dev/null | head -1"))
            vim.notify(
              table.concat({
                "📐 LaTeX Environment",
                "──────────────────────────────────",
                string.format("  LaTeX:      %s", ltx_v),
                string.format("  latexmk:    %s", latexmk),
                string.format("  PDF viewer: %s", pv),
                string.format("  texlab:     %s", vim.fn.executable("texlab")      == 1 and "✅" or "⭕"),
                string.format("  latexindent:%s", vim.fn.executable("latexindent") == 1 and "✅" or "⭕"),
                string.format("  bibtex:     %s", vim.fn.executable("bibtex")      == 1 and "✅" or "⭕"),
                string.format("  biber:      %s", vim.fn.executable("biber")       == 1 and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "LaTeX Info" }
            )
          end,
          ft   = { "tex", "latex" },
          desc = "📐 LaTeX: Environment info",
        },
      },
  
      init = function()
        -- ── Global vimtex settings ────────────────────────────────────────────
        vim.g.vimtex_enabled               = 1
        vim.g.vimtex_view_method           = detect_pdf_viewer() == "zathura" and "zathura"
          or (vim.fn.has("mac") == 1 and "skim" or "zathura")
        vim.g.vimtex_view_forward_search_on_start = 0
        vim.g.vimtex_compiler_method       = "latexmk"
        vim.g.vimtex_compiler_latexmk      = {
          aux_dir        = ".aux",
          out_dir        = "",
          callback       = 1,
          continuous     = 1,
          executable     = "latexmk",
          hooks          = {},
          options        = {
            "-verbose",
            "-file-line-error",
            "-synctex=1",
            "-interaction=nonstopmode",
            "-shell-escape",
          },
        }
        vim.g.vimtex_compiler_latexmk_engines = {
          _                  = "-lualatex",
          pdflatex           = "-pdf",
          lualatex           = "-lualatex",
          xelatex            = "-xelatex",
          context_pdftex     = "-pdf -pdflatex=texexec",
          context_luatex     = "-pdf -pdflatex=context",
          context_xetex      = "-pdf -pdflatex=texexec",
        }
  
        -- ── Parser ────────────────────────────────────────────────────────────
        vim.g.vimtex_syntax_enabled        = 1
        vim.g.vimtex_syntax_conceal        = {
          accents          = 1,
          ligatures        = 1,
          cites            = 1,
          fancy            = 1,
          greek            = 1,
          math_bounds      = 1,
          math_delimiters  = 1,
          math_fracs       = 1,
          math_super_sub   = 1,
          math_symbols     = 1,
          sections         = 0,
          styles           = 1,
        }
        vim.g.vimtex_syntax_custom_cmds     = {}
        vim.g.vimtex_syntax_custom_cmds_with_concealed_delims = {}
  
        -- ── TOC ───────────────────────────────────────────────────────────────
        vim.g.vimtex_toc_config            = {
          fold_enable   = 0,
          layers        = { "content", "todo", "include" },
          show_help     = 0,
          split_pos     = "vert leftabove",
          split_width   = 35,
          tocdepth      = 3,
        }
  
        -- ── Completion ────────────────────────────────────────────────────────
        vim.g.vimtex_complete_enabled      = 1
        vim.g.vimtex_complete_close_braces = 1
  
        -- ── Mappings: use <leader>lx prefix (defined in keys above) ──────────
        vim.g.vimtex_mappings_prefix       = "<localleader>l"
        vim.g.vimtex_mappings_enabled      = 1
  
        -- ── Quickfix ──────────────────────────────────────────────────────────
        vim.g.vimtex_quickfix_mode         = 0
        vim.g.vimtex_quickfix_autoclose_after_keystrokes = 3
        vim.g.vimtex_quickfix_ignore_filters = {
          "Underfull",
          "Overfull",
          "specifier changed to",
          "Token not allowed in a PDF string",
        }
  
        -- ── Imaps (input maps) ─────────────────────────────────────────────────
        vim.g.vimtex_imaps_enabled         = 1
        vim.g.vimtex_imaps_leader          = "`"
  
        -- ── Fold ──────────────────────────────────────────────────────────────
        vim.g.vimtex_fold_enabled          = 1
        vim.g.vimtex_fold_manual           = 0
        vim.g.vimtex_fold_types            = {
          cmd_addplot  = { enabled = 0 },
          cmd_multi    = { enabled = 1 },
          cmd_single   = { enabled = 1 },
          cmd_single_opt = { enabled = 1 },
          comments     = { enabled = 0 },
          env_options  = { enabled = 0 },
          envs         = {
            blacklist  = {},
            enabled    = 1,
            whitelist  = { "abstract", "figure", "table", "thebibliography", "keywords" },
          },
          items        = { enabled = 1 },
          markers      = { enabled = 0 },
          preamble     = { enabled = 1 },
          sections     = { enabled = 1, parse_levels = 0, sections = { "%(sub%(sub%(sub%)?%)?%)?section%*?" } },
        }
  
        -- ── File handling ─────────────────────────────────────────────────────
        vim.g.tex_flavor                   = "latex"
        vim.g.vimtex_include_search_enabled= 1
      end,
    },
  
    -- ── texlab LSP ────────────────────────────────────────────────────────────────
    {
      "neovim/nvim-lspconfig",
      ft   = { "tex", "latex", "plaintex", "bib" },
      opts = {
        servers = {
          texlab = {
            on_attach = function(client, bufnr)
              if client.supports_method("textDocument/inlayHint") then
                vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
              end
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
            settings = {
              texlab = {
                auxDirectory    = ".aux",
                bibtexFormatter = "texlab",
                build           = {
                  args            = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
                  executable      = "latexmk",
                  forwardSearchAfter = false,
                  onSave          = false,
                },
                chktex          = { onOpenAndSave = true, onEdit = false },
                diagnosticsDelay= 300,
                formatterLineLength = 80,
                forwardSearch   = {
                  executable    = detect_pdf_viewer(),
                  args          = (function()
                    local viewer = detect_pdf_viewer()
                    if viewer == "zathura" then
                      return { "--synctex-forward", "%l:1:%f", "%p" }
                    elseif viewer == "okular" then
                      return { "--unique", "file:%p#src:%l%f" }
                    end
                    return {}
                  end)(),
                },
                latexFormatter  = "latexindent",
                latexindent     = {
                  local_          = true,
                  modifyLineBreaks = false,
                },
              },
            },
          },
        },
      },
    },
  
    {
      "nvim-lua/plenary.nvim",
      ft = { "tex", "latex", "plaintex" },
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshLatex", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "tex", "latex", "plaintex" },
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
            vim.opt_local.commentstring= "% %s"
            vim.opt_local.iskeyword:append(":")
            vim.opt_local.iskeyword:append("-")
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("📐 LaTeX highlights synced", vim.log.levels.INFO,
              { title = "ASH LaTeX", timeout = 1200 })
          end,
        })
      end,
    },
  }