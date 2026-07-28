-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🏗️  TERRAFORM — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                        ║
-- ║   terraform-ls · tflint · tfsec · checkov · plan · apply · fmt                ║
-- ║   module docs · workspace · ASH theme-synced                                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "@lsp.type.type.terraform",        { bold = true,   fg = "#7aa2f7" })
    hl(0, "@lsp.type.property.terraform",    { fg = "#89b4fa"                })
    hl(0, "@lsp.type.variable.terraform",    { fg = "#cba6f7"                })
    hl(0, "@lsp.type.string.terraform",      { fg = "#a6e3a1"                })
    hl(0, "@lsp.type.number.terraform",      { fg = "#fab387"                })
    hl(0, "@lsp.type.boolean.terraform",     { bold = true,   fg = "#fab387" })
    hl(0, "@lsp.type.keyword.terraform",     { bold = true,   fg = "#f38ba8" })
    hl(0, "@lsp.type.function.terraform",    { fg = "#89b4fa"                })
    hl(0, "@lsp.type.namespace.terraform",   { italic = true, fg = "#94e2d5" })
    hl(0, "@lsp.type.operator.terraform",    { fg = "#89b4fa"                })
    hl(0, "@lsp.type.comment.terraform",     { italic = true, fg = "#9399b2" })
    hl(0, "@lsp.type.label.terraform",       { italic = true, fg = "#89b4fa" })
    hl(0, "@lsp.type.interface.terraform",   { italic = true, fg = "#94e2d5" })
  
    hl(0, "TerraformResourceBlock",    { bold = true,   fg = "#f9e2af" })
    hl(0, "TerraformDataBlock",        { bold = true,   fg = "#89dceb" })
    hl(0, "TerraformModuleBlock",      { bold = true,   fg = "#cba6f7" })
    hl(0, "TerraformVariableBlock",    { bold = true,   fg = "#9ece6a" })
    hl(0, "TerraformOutputBlock",      { bold = true,   fg = "#7dcfff" })
    hl(0, "TerraformLocalsBlock",      { bold = true,   fg = "#fab387" })
    hl(0, "TerraformProviderBlock",    { bold = true,   fg = "#7aa2f7" })
    hl(0, "TerraformBackendBlock",     { bold = true,   fg = "#f38ba8" })
    hl(0, "TerraformRequired",         { italic = true, fg = "#f38ba8" })
    hl(0, "TerraformInterpolation",    { fg = "#cba6f7"                })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "@lsp.type.type.terraform",     { bold = true, fg = p.blue })
        hl(0, "TerraformProviderBlock",       { bold = true, fg = p.blue })
      end
      if p.yellow then hl(0, "TerraformResourceBlock",  { bold = true, fg = p.yellow }) end
      if p.teal   then
        hl(0, "@lsp.type.namespace.terraform",{ italic = true, fg = p.teal })
        hl(0, "TerraformDataBlock",           { bold = true, fg = p.teal })
      end
      if p.mauve  then
        hl(0, "@lsp.type.variable.terraform", { fg = p.mauve })
        hl(0, "TerraformModuleBlock",         { bold = true, fg = p.mauve })
      end
      if p.green  then hl(0, "TerraformVariableBlock", { bold = true, fg = p.green }) end
      if p.red    then
        hl(0, "TerraformBackendBlock",        { bold = true, fg = p.red })
        hl(0, "TerraformRequired",            { italic = true, fg = p.red })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 TERRAFORM UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function run_tf(cmd, title)
    local ok_term, term = pcall(require, "toggleterm.terminal")
    if ok_term then
      term.Terminal:new({
        cmd          = "terraform " .. cmd,
        direction    = "float",
        display_name = "🏗️  tf " .. (title or cmd:match("^%S+")),
        float_opts   = { border = "rounded" },
        close_on_exit = false,
      }):toggle()
    else
      vim.cmd("split term://terraform " .. cmd)
    end
  end
  
  local function get_workspaces()
    local result = vim.fn.systemlist("terraform workspace list 2>/dev/null")
    local ws     = {}
    for _, line in ipairs(result) do
      local name = line:gsub("^%*?%s*", "")
      if name ~= "" then table.insert(ws, name) end
    end
    return ws
  end
  
  local function get_current_workspace()
    return vim.fn.trim(vim.fn.system("terraform workspace show 2>/dev/null"))
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        vim.list_extend(opts.ensure_installed, { "terraform", "hcl" })
      end,
    },
  
    {
      "neovim/nvim-lspconfig",
      ft   = { "terraform", "terraform-vars", "hcl" },
      opts = {
        servers = {
          terraformls = {
            on_attach = function(client, bufnr)
              if client.supports_method("textDocument/inlayHint") then
                vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
              end
              vim.api.nvim_create_autocmd("BufWritePre", {
                buffer   = bufnr,
                callback = function() vim.lsp.buf.format({ bufnr = bufnr, async = false }) end,
              })
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
            cmd      = { "terraform-ls", "serve" },
            filetypes= { "terraform", "terraform-vars" },
            settings = {
              ["terraform-ls"] = {
                experimentalFeatures = {
                  validateOnSave         = true,
                  prefillRequiredFields  = true,
                  completionSnippets     = true,
                },
                indexing = {
                  ignorePaths        = { ".terraform", ".terragrunt-cache" },
                  ignoreDirectoryNames = { ".git" },
                },
              },
            },
          },
          tflint = {
            on_attach = function(client, bufnr)
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
          },
        },
      },
    },
  
    {
      "nvim-lua/plenary.nvim",
      ft = { "terraform", "terraform-vars", "hcl" },
  
      keys = {
        { "<leader>tfi",  function() run_tf("init", "init")          end, ft = { "terraform", "hcl" }, desc = "🏗️  TF: Init"             },
        { "<leader>tfp",  function() run_tf("plan", "plan")          end, ft = { "terraform", "hcl" }, desc = "🏗️  TF: Plan"             },
        { "<leader>tfa",  function() run_tf("apply -auto-approve", "apply") end, ft = { "terraform", "hcl" }, desc = "🏗️  TF: Apply"      },
        { "<leader>tfd",  function() run_tf("destroy -auto-approve","destroy") end, ft = { "terraform", "hcl" }, desc = "🏗️  TF: Destroy"  },
        { "<leader>tff",  function() run_tf("fmt -recursive", "fmt") end, ft = { "terraform", "hcl" }, desc = "🏗️  TF: Format"           },
        { "<leader>tfv",  function() run_tf("validate", "validate")  end, ft = { "terraform", "hcl" }, desc = "🏗️  TF: Validate"         },
        { "<leader>tfo",  function() run_tf("output", "output")      end, ft = { "terraform", "hcl" }, desc = "🏗️  TF: Output"           },
        {
          "<leader>tfw",
          function()
            local ws = get_workspaces()
            if #ws == 0 then
              vim.notify("🏗️  No workspaces (run terraform init)", vim.log.levels.WARN,
                { title = "Terraform" })
              return
            end
            local cur = get_current_workspace()
            vim.ui.select(ws, {
              prompt = string.format("🏗️  Workspace (current: %s): ", cur),
            }, function(selected)
              if selected then run_tf("workspace select " .. selected, "workspace") end
            end)
          end,
          ft   = { "terraform", "hcl" },
          desc = "🏗️  TF: Select workspace",
        },
        {
          "<leader>tfs",
          function()
            if vim.fn.executable("tfsec") ~= 1 then
              vim.notify("🏗️  tfsec not found", vim.log.levels.WARN, { title = "Terraform" })
              return
            end
            run_tf("", "tfsec")
            vim.fn.jobstart({ "tfsec", vim.fn.getcwd(), "--format=default" }, {
              on_stdout = function(_, data)
                if data and #data > 0 then
                  vim.notify(table.concat(data, "\n"), vim.log.levels.WARN,
                    { title = "tfsec" })
                end
              end,
            })
          end,
          ft   = { "terraform", "hcl" },
          desc = "🏗️  TF: Security scan (tfsec)",
        },
        {
          "<leader>tfi",
          function()
            local ws   = get_current_workspace()
            local tf_v = vim.fn.trim(vim.fn.system("terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null"))
            vim.notify(
              table.concat({
                "🏗️  Terraform Environment",
                "──────────────────────────────────",
                string.format("  Version:    %s", tf_v ~= "" and tf_v or "unknown"),
                string.format("  Workspace:  %s", ws ~= "" and ws or "default"),
                string.format("  tflint:     %s", vim.fn.executable("tflint")  == 1 and "✅" or "⭕"),
                string.format("  tfsec:      %s", vim.fn.executable("tfsec")   == 1 and "✅" or "⭕"),
                string.format("  checkov:    %s", vim.fn.executable("checkov") == 1 and "✅" or "⭕"),
                string.format("  .terraform: %s", vim.fn.isdirectory(vim.fn.getcwd() .. "/.terraform") == 1 and "✅" or "⭕ (run init)"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Terraform Info" }
            )
          end,
          ft   = { "terraform", "hcl" },
          desc = "🏗️  TF: Environment info",
        },
      },
  
      config = function()
        setup_highlights()
  
        -- Filetype detection
        vim.filetype.add({
          extension = { tf = "terraform", tfvars = "terraform-vars" },
          filename  = {
            ["terraform.tfstate"]        = "json",
            ["terraform.tfstate.backup"] = "json",
          },
        })
  
        local aug = vim.api.nvim_create_augroup("AshTerraform", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "terraform", "terraform-vars", "hcl" },
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.commentstring = "# %s"
            vim.opt_local.foldmethod  = "expr"
            vim.opt_local.foldexpr    = "v:lua.vim.treesitter.foldexpr()"
            vim.opt_local.foldlevel   = 99
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🏗️  Terraform highlights synced", vim.log.levels.INFO,
              { title = "ASH Terraform", timeout = 1200 })
          end,
        })
      end,
    },
  }