-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ❄️  NIX FTPLUGIN — ASH v5.0 OMEGA                                        ║
-- ║   nil_ls · alejandra/nixfmt · statix · deadnix · flake · home-manager        ║
-- ║   nix eval · nix build · NixOS modules · derivation helpers                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 2
opt.tabstop      = 2
opt.softtabstop  = 2
opt.textwidth    = 100
opt.colorcolumn  = "101"
opt.commentstring= "# %s"

-- Treesitter folding
opt.foldmethod   = "expr"
opt.foldexpr     = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel    = 99
opt.foldenable   = true

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer  = buf,
    silent  = true,
    noremap = true,
    desc    = "❄️  Nix: " .. desc,
  })
end

local function run_cmd(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "❄️  " .. title,
      float_opts   = { border = "rounded" },
      close_on_exit = false,
    }):toggle()
  else
    vim.cmd("split term://" .. cmd)
  end
end

local function formatter()
  if vim.fn.executable("alejandra") == 1 then return "alejandra" end
  if vim.fn.executable("nixfmt")    == 1 then return "nixfmt"    end
  return nil
end

local function is_flake()
  return vim.fn.filereadable(vim.fn.getcwd() .. "/flake.nix") == 1
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>nf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
    return
  end

  local fmt = formatter()
  if not fmt then
    vim.notify("❄️  No formatter found (install alejandra or nixfmt)",
      vim.log.levels.WARN, { title = "Nix" })
    return
  end

  local file = vim.api.nvim_buf_get_name(buf)
  local view = vim.fn.winsaveview()
  vim.fn.system(fmt .. " " .. vim.fn.shellescape(file) .. " 2>&1")
  vim.cmd("checktime")
  vim.fn.winrestview(view)
  vim.notify("❄️  Formatted with " .. fmt, vim.log.levels.INFO,
    { title = "Nix", timeout = 1000 })
end, "Format")

-- ── Lint ─────────────────────────────────────────────────────────────────────
map("n", "<leader>nl", function()
  local file   = vim.api.nvim_buf_get_name(buf)
  local qflist = {}

  -- statix
  if vim.fn.executable("statix") == 1 then
    local result = vim.fn.system(
      "statix check " .. vim.fn.shellescape(file) .. " 2>&1"
    )
    for line in result:gmatch("[^\n]+") do
      local lnum, msg = line:match("(%d+):.*: (.+)")
      if lnum then
        table.insert(qflist, {
          filename = file,
          lnum     = tonumber(lnum),
          type     = "W",
          text     = "[statix] " .. msg,
        })
      end
    end
  end

  -- deadnix
  if vim.fn.executable("deadnix") == 1 then
    local result = vim.fn.system(
      "deadnix " .. vim.fn.shellescape(file) .. " 2>&1"
    )
    for line in result:gmatch("[^\n]+") do
      local lnum, msg = line:match("(%d+):%d+: (.+)")
      if lnum then
        table.insert(qflist, {
          filename = file,
          lnum     = tonumber(lnum),
          type     = "W",
          text     = "[deadnix] " .. msg,
        })
      end
    end
  end

  if not vim.fn.executable("statix") == 1 and
     not vim.fn.executable("deadnix") == 1 then
    vim.notify("❄️  Install statix and/or deadnix for linting",
      vim.log.levels.WARN, { title = "Nix" })
    return
  end

  if #qflist > 0 then
    vim.fn.setqflist(qflist)
    vim.cmd("copen")
    vim.notify(string.format("❄️  %d issue(s)", #qflist), vim.log.levels.WARN,
      { title = "Nix Lint" })
  else
    vim.notify("❄️  ✅ No issues found", vim.log.levels.INFO,
      { title = "Nix Lint", timeout = 1500 })
  end
end, "Lint (statix + deadnix)")

map("n", "<leader>nL", function()
  -- deadnix: auto-remove dead code
  if vim.fn.executable("deadnix") ~= 1 then
    vim.notify("❄️  deadnix not found", vim.log.levels.WARN, { title = "Nix" })
    return
  end
  local file = vim.api.nvim_buf_get_name(buf)
  vim.fn.system("deadnix --edit " .. vim.fn.shellescape(file) .. " 2>&1")
  vim.cmd("checktime")
  vim.notify("❄️  deadnix: dead code removed", vim.log.levels.INFO,
    { title = "Nix", timeout = 1500 })
end, "deadnix auto-fix")

-- ── Evaluate ──────────────────────────────────────────────────────────────────
map("n", "<leader>ne", function()
  vim.ui.input({ prompt = "❄️  nix eval expression: " }, function(expr)
    if not expr or expr == "" then return end
    local result = vim.fn.system(
      "nix eval " .. vim.fn.shellescape(expr) .. " 2>&1"
    )
    vim.notify(
      vim.v.shell_error == 0 and "❄️  = " .. vim.fn.trim(result)
        or "❄️  Error:\n" .. result,
      vim.v.shell_error == 0 and vim.log.levels.INFO or vim.log.levels.ERROR,
      { title = "nix eval" }
    )
  end)
end, "nix eval")

map("n", "<leader>nE", function()
  -- Eval the expression under cursor
  local word = vim.fn.expand("<cWORD>")
  if word == "" then return end

  local result = vim.fn.system(
    "nix eval --expr " .. vim.fn.shellescape(word) .. " 2>&1"
  )
  vim.notify(
    vim.v.shell_error == 0 and "❄️  " .. vim.fn.trim(result)
      or "❄️  " .. result,
    vim.log.levels.INFO,
    { title = "nix eval" }
  )
end, "nix eval word")

-- ── Flake commands ────────────────────────────────────────────────────────────
map("n", "<leader>nb", function()
  run_cmd("nix build", "build")
end, "nix build")

map("n", "<leader>nr", function()
  run_cmd("nix run .#", "run")
end, "nix run")

map("n", "<leader>nd", function()
  run_cmd("nix develop", "develop")
end, "nix develop")

map("n", "<leader>nc", function()
  run_cmd("nix flake check", "flake check")
end, "nix flake check")

map("n", "<leader>nu", function()
  run_cmd("nix flake update", "flake update")
end, "nix flake update")

map("n", "<leader>ns", function()
  run_cmd("nix flake show", "flake show")
end, "nix flake show")

map("n", "<leader>nm", function()
  run_cmd("nix flake metadata", "flake metadata")
end, "nix flake metadata")

-- ── NixOS rebuild ─────────────────────────────────────────────────────────────
map("n", "<leader>nRs", function()
  run_cmd("sudo nixos-rebuild switch --flake .#", "nixos-rebuild switch")
end, "nixos-rebuild switch")

map("n", "<leader>nRb", function()
  run_cmd("sudo nixos-rebuild boot --flake .#", "nixos-rebuild boot")
end, "nixos-rebuild boot")

map("n", "<leader>nRt", function()
  run_cmd("sudo nixos-rebuild test --flake .#", "nixos-rebuild test")
end, "nixos-rebuild test")

-- ── Home-manager ──────────────────────────────────────────────────────────────
map("n", "<leader>nhs", function()
  run_cmd("home-manager switch --flake .#", "home-manager switch")
end, "home-manager switch")

map("n", "<leader>nhb", function()
  run_cmd("home-manager build --flake .#", "home-manager build")
end, "home-manager build")

-- ── Insert helpers ────────────────────────────────────────────────────────────
map("n", "<leader>nip", function()
  -- Insert pkgs.* package reference
  vim.ui.input({ prompt = "❄️  Package name: " }, function(pkg)
    if not pkg or pkg == "" then return end
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
    local indent = line:match("^(%s*)") or ""
    vim.api.nvim_buf_set_lines(buf, row, row, false,
      { indent .. "pkgs." .. pkg })
  end)
end, "Insert pkgs.* reference")

map("n", "<leader>nid", function()
  -- Insert stdenv.mkDerivation skeleton
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false, {
    "{ stdenv, fetchurl, lib }:",
    "",
    "stdenv.mkDerivation rec {",
    '  pname   = "";',
    '  version = "0.0.1";',
    "",
    "  src = fetchurl {",
    '    url    = "";',
    '    sha256 = lib.fakeSha256;',
    "  };",
    "",
    "  meta = with lib; {",
    '    description = "";',
    '    homepage    = "";',
    "    license     = licenses.mit;",
    "    maintainers = [ ];",
    "  };",
    "}",
  })
end, "Insert mkDerivation skeleton")

map("n", "<leader>nif", function()
  -- Insert flake.nix skeleton
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
  local insert_at = (first == "" or first == nil) and 0 or row

  vim.api.nvim_buf_set_lines(buf, insert_at, insert_at, false, {
    "{",
    '  description = "❄️  ASH Nix flake";',
    "",
    "  inputs = {",
    '    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";',
    '    flake-utils.url  = "github:numtide/flake-utils";',
    "  };",
    "",
    "  outputs = { self, nixpkgs, flake-utils }:",
    "    flake-utils.lib.eachDefaultSystem (system:",
    "    let",
    "      pkgs = nixpkgs.legacyPackages.${system};",
    "    in {",
    "      packages.default = pkgs.hello;",
    "",
    "      devShells.default = pkgs.mkShell {",
    "        buildInputs = with pkgs; [",
    "          git",
    "        ];",
    "      };",
    "    });",
    "}",
  })
end, "Insert flake.nix skeleton")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>ni", function()
  local nix_ver = vim.fn.trim(vim.fn.system("nix --version 2>/dev/null"))
  local fmt     = formatter() or "⭕ none"

  vim.notify(
    table.concat({
      "❄️  Nix Environment",
      "──────────────────────────────────",
      string.format("  nix:        %s", nix_ver),
      string.format("  Formatter:  %s", fmt),
      string.format("  statix:     %s", vim.fn.executable("statix")   == 1 and "✅" or "⭕"),
      string.format("  deadnix:    %s", vim.fn.executable("deadnix")  == 1 and "✅" or "⭕"),
      string.format("  nil_ls:     %s", vim.fn.executable("nil")       == 1 and "✅" or "⭕"),
      string.format("  flake.nix:  %s", is_flake() and "✅ found" or "⭕"),
      string.format("  home-mgr:   %s",
        vim.fn.executable("home-manager") == 1 and "✅" or "⭕"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Nix" }
  )
end, "Environment info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtNix_" .. buf, { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group  = aug,
  buffer = buf,
  callback = function()
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
      return
    end
    local fmt = formatter()
    if fmt then
      local file = vim.api.nvim_buf_get_name(buf)
      local view = vim.fn.winsaveview()
      vim.fn.system(fmt .. " " .. vim.fn.shellescape(file) .. " 2>&1")
      vim.cmd("checktime")
      vim.fn.winrestview(view)
    end
  end,
})