-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🌐 REST.NVIM — ULTRA HTTP CLIENT v5.0 OMEGA                              ║
-- ║   .http file support · curl · jq · response preview · env vars               ║
-- ║   history · cURL export · GraphQL · ASH theme-synced                          ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Response window ───────────────────────────────────────────────────────
    hl(0, "RestNvimNormal",       { link = "NormalFloat"   })
    hl(0, "RestNvimBorder",       { link = "FloatBorder"   })
  
    -- ── Method colours ────────────────────────────────────────────────────────
    hl(0, "RestNvimMethodGET",    { bold = true, fg = "#9ece6a" })
    hl(0, "RestNvimMethodPOST",   { bold = true, fg = "#7aa2f7" })
    hl(0, "RestNvimMethodPUT",    { bold = true, fg = "#f9e2af" })
    hl(0, "RestNvimMethodPATCH",  { bold = true, fg = "#fab387" })
    hl(0, "RestNvimMethodDELETE", { bold = true, fg = "#f38ba8" })
    hl(0, "RestNvimMethodHEAD",   { bold = true, fg = "#94e2d5" })
    hl(0, "RestNvimMethodOPTIONS",{ bold = true, fg = "#cba6f7" })
  
    -- ── Status codes ──────────────────────────────────────────────────────────
    hl(0, "RestNvimStatus2xx",    { bold = true, fg = "#9ece6a" })
    hl(0, "RestNvimStatus3xx",    { bold = true, fg = "#7aa2f7" })
    hl(0, "RestNvimStatus4xx",    { bold = true, fg = "#f9e2af" })
    hl(0, "RestNvimStatus5xx",    { bold = true, fg = "#f38ba8" })
  
    -- ── Header / URL ─────────────────────────────────────────────────────────
    hl(0, "RestNvimHeader",       { italic = true, fg = "#89b4fa" })
    hl(0, "RestNvimURL",          { underline = true, fg = "#89b4fa" })
    hl(0, "RestNvimVariable",     { bold = true, fg = "#cba6f7" })
    hl(0, "RestNvimComment",      { italic = true, fg = "#9399b2" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green  then hl(0, "RestNvimMethodGET",    { bold = true, fg = p.green  }) end
      if p.blue   then hl(0, "RestNvimMethodPOST",   { bold = true, fg = p.blue   }) end
      if p.yellow then hl(0, "RestNvimMethodPUT",    { bold = true, fg = p.yellow }) end
      if p.red    then hl(0, "RestNvimMethodDELETE", { bold = true, fg = p.red    }) end
      if p.green  then hl(0, "RestNvimStatus2xx",    { bold = true, fg = p.green  }) end
      if p.red    then hl(0, "RestNvimStatus5xx",    { bold = true, fg = p.red    }) end
      if p.mauve  then hl(0, "RestNvimVariable",     { bold = true, fg = p.mauve  }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "rest-nvim/rest.nvim",
      ft           = { "http" },
      dependencies = { "nvim-lua/plenary.nvim" },
  
      keys = {
        { "<leader>rr",  "<cmd>Rest run<cr>",        ft = "http", desc = "🌐 REST: Run request"         },
        { "<leader>rR",  "<cmd>Rest run last<cr>",   ft = "http", desc = "🌐 REST: Run last request"    },
        { "<leader>rp",  "<cmd>Rest preview<cr>",    ft = "http", desc = "🌐 REST: Preview request"     },
        { "<leader>rl",  "<cmd>Rest logs<cr>",       ft = "http", desc = "🌐 REST: Logs"                },
        { "<leader>re",  "<cmd>Rest env<cr>",        ft = "http", desc = "🌐 REST: Env vars"            },
        { "<leader>rh",  "<cmd>Rest history<cr>",    ft = "http", desc = "🌐 REST: History"             },
        {
          "<leader>rc",
          function()
            -- Export current request as curl command
            local result = vim.fn.system("rest-nvim curl " .. vim.api.nvim_buf_get_name(0) .. " 2>/dev/null")
            if result ~= "" then
              vim.fn.setreg("+", result)
              vim.notify("🌐 cURL copied to clipboard", vim.log.levels.INFO,
                { title = "REST", timeout = 1500 })
            end
          end,
          ft   = "http",
          desc = "🌐 REST: Copy as cURL",
        },
        {
          "<leader>rn",
          function()
            -- Create new .http file
            local name = vim.fn.input("Request name: ")
            if name == "" then return end
            local file = vim.fn.getcwd() .. "/" .. name:gsub("%s+", "_") .. ".http"
            local template = table.concat({
              "# @name " .. name,
              "# @base-url http://localhost:3000",
              "",
              "### GET Request",
              "GET {{base-url}}/api/endpoint",
              "Content-Type: application/json",
              "Authorization: Bearer {{token}}",
              "",
              "###",
              "",
              "### POST Request",
              "POST {{base-url}}/api/endpoint",
              "Content-Type: application/json",
              "",
              "{",
              '  "key": "value"',
              "}",
            }, "\n")
            local f = io.open(file, "w")
            if f then
              f:write(template)
              f:close()
              vim.cmd("edit " .. file)
              vim.notify("🌐 Created: " .. file, vim.log.levels.INFO, { title = "REST" })
            end
          end,
          desc = "🌐 REST: New .http file",
        },
      },
  
      opts = {
        -- ── Request execution ──────────────────────────────────────────────────
        request = {
          skip_ssl_verification = false,
          hooks                 = {
            encode_url          = true,
            user_agent          = "rest.nvim/1.0 (Neovim ASH v5.0)",
            set_content_type    = true,
          },
        },
  
        -- ── Response ─────────────────────────────────────────────────────────
        response = {
          hooks = {
            decode_url          = true,
            format              = true,
          },
        },
  
        -- ── Client options ────────────────────────────────────────────────────
        clients = {
          curl = {
            statistics = {
              {
                id    = "time_total",
                title = "Time",
                style = "",
              },
              {
                id    = "size_download",
                title = "Size",
                style = "",
              },
              {
                id    = "response_code",
                title = "Status",
                style = "",
              },
            },
          },
        },
  
        -- ── Keymaps (plugin-native) ────────────────────────────────────────────
        keybinds = false,   -- we manage our own
  
        -- ── Logger ────────────────────────────────────────────────────────────
        logger = {
          level = vim.log.levels.WARN,
          save  = true,
        },
      },
  
      config = function(_, opts)
        require("rest-nvim").setup(opts)
  
        setup_highlights()
  
        -- Register .http filetype
        vim.filetype.add({
          extension = { http = "http", rest = "http" },
        })
  
        local aug = vim.api.nvim_create_augroup("AshRest", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "http",
          callback = function()
            vim.opt_local.expandtab    = true
            vim.opt_local.shiftwidth   = 2
            vim.opt_local.tabstop      = 2
            vim.opt_local.softtabstop  = 2
            vim.opt_local.commentstring= "# %s"
  
            -- Enable folding by method separator
            vim.opt_local.foldmethod = "expr"
            vim.opt_local.foldexpr   = "getline(v:lnum) =~ '^###' ? '<1' : '='"
            vim.opt_local.foldlevel  = 99
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🌐 REST highlights synced", vim.log.levels.INFO,
              { title = "ASH REST", timeout = 1200 })
          end,
        })
      end,
    },
  }