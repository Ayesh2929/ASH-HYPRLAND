-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📝 MARKDOWN-PREVIEW — ULTRA MD BROWSER PREVIEW v5.0 OMEGA               ║
-- ║   Live browser preview · math · mermaid · plantuml · custom CSS               ║
-- ║   sync scroll · dark/light · ASH theme export · GitHub flavour               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "MarkdownPreviewNormal",  { link = "NormalFloat"  })
    hl(0, "MarkdownPreviewBorder",  { link = "FloatBorder"  })
    hl(0, "MarkdownPreviewActive",  { bold = true, fg = "#9ece6a" })
    hl(0, "MarkdownPreviewInactive",{ fg = "#9399b2"              })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green then hl(0, "MarkdownPreviewActive", { bold = true, fg = p.green }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 CUSTOM CSS GENERATOR — ASH palette → browser CSS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function generate_css()
    local ok, ash = pcall(require, "ash.theme")
    local p = (ok and ash.palette) or {}
  
    local base     = p.base    or "#1a1b26"
    local surface  = p.surface0 or "#1e2030"
    local text     = p.text    or "#cdd6f4"
    local subtext  = p.subtext1 or "#a6adc8"
    local overlay  = p.overlay0 or "#6e738d"
    local blue     = p.blue    or "#89b4fa"
    local green    = p.green   or "#a6e3a1"
    local red      = p.red     or "#f38ba8"
    local yellow   = p.yellow  or "#f9e2af"
    local mauve    = p.mauve   or "#cba6f7"
    local teal     = p.teal    or "#94e2d5"
    local border   = p.surface2 or "#585b70"
  
    local css = string.format([[
  /* ASH OMEGA v5.0 — Markdown Preview Theme */
  :root {
    --color-canvas-default:     %s;
    --color-canvas-subtle:      %s;
    --color-fg-default:         %s;
    --color-fg-muted:           %s;
    --color-fg-subtle:          %s;
    --color-border-default:     %s;
    --color-border-muted:       %s;
    --color-accent-fg:          %s;
    --color-accent-emphasis:    %s;
    --color-success-fg:         %s;
    --color-danger-fg:          %s;
    --color-attention-fg:       %s;
    --color-done-fg:            %s;
  }
  
  body {
    background-color: var(--color-canvas-default);
    color:            var(--color-fg-default);
    font-family:      -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
    font-size:        16px;
    line-height:      1.7;
    max-width:        860px;
    margin:           0 auto;
    padding:          2rem;
  }
  
  /* Headings */
  h1, h2, h3, h4, h5, h6 {
    color:       var(--color-fg-default);
    font-weight: 700;
    margin-top:  1.5rem;
    margin-bottom: 0.75rem;
    border-bottom: 1px solid var(--color-border-muted);
    padding-bottom: 0.3rem;
  }
  h1 { color: %s; font-size: 2em; }
  h2 { color: %s; font-size: 1.5em; }
  h3 { color: %s; font-size: 1.25em; border-bottom: none; }
  h4, h5, h6 { border-bottom: none; }
  
  /* Code */
  pre, code {
    background: var(--color-canvas-subtle);
    border-radius: 6px;
    font-family: 'JetBrains Mono', 'Fira Code', monospace;
    font-size: 0.9em;
  }
  code {
    padding:   0.2em 0.4em;
    color:     %s;
  }
  pre {
    padding:   1rem;
    overflow-x: auto;
    border:    1px solid var(--color-border-default);
  }
  pre code {
    padding:   0;
    background: none;
    color:     var(--color-fg-default);
  }
  
  /* Links */
  a {
    color:           var(--color-accent-fg);
    text-decoration: none;
  }
  a:hover {
    text-decoration: underline;
    color:           %s;
  }
  
  /* Blockquotes */
  blockquote {
    margin:           0;
    padding:          0.5rem 1rem;
    color:            var(--color-fg-muted);
    border-left:      4px solid var(--color-border-default);
    background:       var(--color-canvas-subtle);
    border-radius:    0 6px 6px 0;
  }
  
  /* Tables */
  table {
    border-collapse: collapse;
    width:           100%%;
    margin:          1rem 0;
  }
  th, td {
    padding:        0.5rem 1rem;
    border:         1px solid var(--color-border-default);
    text-align:     left;
  }
  th {
    background:     var(--color-canvas-subtle);
    font-weight:    700;
    color:          var(--color-accent-fg);
  }
  tr:nth-child(even) { background: var(--color-canvas-subtle); }
  
  /* Lists */
  ul, ol { padding-left: 2rem; }
  li + li { margin-top: 0.25rem; }
  li::marker { color: var(--color-accent-fg); }
  
  /* Task lists */
  input[type="checkbox"] {
    margin-right: 0.5rem;
    accent-color: var(--color-success-fg);
  }
  
  /* HR */
  hr {
    border:     none;
    border-top: 2px solid var(--color-border-default);
    margin:     2rem 0;
  }
  
  /* Images */
  img {
    max-width:    100%%;
    border-radius:6px;
    border:       1px solid var(--color-border-default);
  }
  
  /* Callouts (GitHub-style) */
  .markdown-alert {
    border-left:  4px solid var(--color-border-default);
    padding:      0.5rem 1rem;
    margin:       1rem 0;
    border-radius:0 6px 6px 0;
  }
  .markdown-alert-note    { border-color: %s; background: %s22; }
  .markdown-alert-tip     { border-color: %s; background: %s22; }
  .markdown-alert-warning { border-color: %s; background: %s22; }
  .markdown-alert-caution { border-color: %s; background: %s22; }
  
  /* Scrollbar */
  ::-webkit-scrollbar       { width: 8px; height: 8px; }
  ::-webkit-scrollbar-track { background: var(--color-canvas-default); }
  ::-webkit-scrollbar-thumb { background: var(--color-border-default); border-radius: 4px; }
  ::-webkit-scrollbar-thumb:hover { background: var(--color-fg-subtle); }
  ]], base, surface, text, subtext, overlay, border, border,
      blue, blue, green, red, yellow, mauve,
      blue, green, mauve,   -- h1, h2, h3
      teal,                 -- inline code colour
      blue,                 -- link hover
      blue, blue, green, green, yellow, yellow, red, red)
  
    local css_path = vim.fn.stdpath("data") .. "/markdown_preview_ash.css"
    local f = io.open(css_path, "w")
    if f then
      f:write(css)
      f:close()
    end
    return css_path
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "iamcco/markdown-preview.nvim",
      cmd    = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
      ft     = { "markdown" },
      build  = function()
        -- Install dependencies via Node
        vim.fn["mkdp#util#install"]()
      end,
  
      keys = {
        { "<leader>mp",  "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "📝 MD Preview: Toggle"      },
        { "<leader>mP",  "<cmd>MarkdownPreview<cr>",       ft = "markdown", desc = "📝 MD Preview: Open"        },
        { "<leader>mX",  "<cmd>MarkdownPreviewStop<cr>",   ft = "markdown", desc = "📝 MD Preview: Stop"        },
        {
          "<leader>mT",
          function()
            -- Toggle between dark and light theme CSS
            local current = vim.g.mkdp_highlight_css or ""
            if current:find("ash") then
              -- Switch to built-in (light)
              vim.g.mkdp_highlight_css = ""
              vim.g.mkdp_theme         = "light"
              vim.notify("📝 Preview: Light theme", vim.log.levels.INFO,
                { title = "MD Preview", timeout = 1000 })
            else
              local css = generate_css()
              vim.g.mkdp_highlight_css = css
              vim.g.mkdp_theme         = "dark"
              vim.notify("📝 Preview: ASH dark theme", vim.log.levels.INFO,
                { title = "MD Preview", timeout = 1000 })
            end
          end,
          ft   = "markdown",
          desc = "📝 MD Preview: Toggle ASH theme",
        },
      },
  
      init = function()
        -- Generate the ASH CSS immediately so it's ready on first open
        local css_path = generate_css()
  
        -- ── Core settings ───────────────────────────────────────────────────────
        vim.g.mkdp_filetypes         = { "markdown" }
        vim.g.mkdp_theme             = "dark"
        vim.g.mkdp_auto_close        = 1
        vim.g.mkdp_refresh_slow      = 0
        vim.g.mkdp_open_to_the_world = 0
        vim.g.mkdp_open_ip           = ""
        vim.g.mkdp_port              = ""
        vim.g.mkdp_page_title        = "【${name}】"
        vim.g.mkdp_preview_options   = {
          mkit                      = {},
          katex                     = {},
          uml                       = {},
          maid                      = {},
          disable_sync_scroll       = 0,
          sync_scroll_type          = "middle",
          hide_yaml_meta            = 1,
          sequence_diagrams         = {},
          flowchart_diagrams        = {},
          content_editable          = false,
          disable_filename          = 0,
          toc                       = {},
        }
  
        -- ── Custom CSS (ASH theme) ────────────────────────────────────────────
        vim.g.mkdp_markdown_css   = css_path
        vim.g.mkdp_highlight_css  = css_path
  
        -- ── Browser command ───────────────────────────────────────────────────
        local browsers = { "xdg-open", "open", "firefox", "chromium", "google-chrome" }
        for _, b in ipairs(browsers) do
          if vim.fn.executable(b) == 1 then
            vim.g.mkdp_browser = b
            break
          end
        end
  
        -- ── Echo URL when server starts ───────────────────────────────────────
        vim.g.mkdp_echo_preview_url = 1
  
        -- ── Combine markdown / highlight CSS ──────────────────────────────────
        vim.g.mkdp_combine_preview   = 0
        vim.g.mkdp_auto_preview      = 0
      end,
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshMarkdownPreview", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            -- Regenerate CSS with new palette
            local css_path = generate_css()
            vim.g.mkdp_markdown_css  = css_path
            vim.g.mkdp_highlight_css = css_path
            vim.notify("📝 MD Preview CSS synced with ASH theme", vim.log.levels.INFO,
              { title = "ASH MD Preview", timeout = 1500 })
          end,
        })
      end,
    },
  }