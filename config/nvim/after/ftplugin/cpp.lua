-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ⚙️  C/C++ FTPLUGIN — ASH v5.0 OMEGA                                      ║
-- ║   CMake · Make · Ninja · header/source toggle · sanitizers · gdb/lldb          ║
-- ║   clang-format · cppcheck · compile_commands · conan/vcpkg                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local
local ft  = vim.bo[buf].filetype   -- c | cpp | cuda | objc | objcpp

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 4
opt.tabstop      = 4
opt.softtabstop  = 4
opt.textwidth    = 100
opt.colorcolumn  = "101"
opt.commentstring= "// %s"
opt.cinoptions   = "g0,N-s,E-s,(0,k2,l1"
opt.matchpairs:append("<:>")   -- match angle brackets

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
    desc    = "⚙️  C/C++: " .. desc,
  })
end

local function run_cmd(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "⚙️  " .. title,
      float_opts   = { border = "rounded" },
      close_on_exit = false,
    }):toggle()
  else
    vim.cmd("split term://" .. cmd)
  end
end

-- Detect build system
local function detect_build_system()
  local cwd = vim.fn.getcwd()
  local checks = {
    { "CMakeLists.txt",    "cmake"  },
    { "Makefile",          "make"   },
    { "makefile",          "make"   },
    { "build.ninja",       "ninja"  },
    { "meson.build",       "meson"  },
    { "BUILD",             "bazel"  },
    { "BUILD.bazel",       "bazel"  },
    { "xmake.lua",         "xmake"  },
  }
  for _, c in ipairs(checks) do
    if vim.fn.filereadable(cwd .. "/" .. c[1]) == 1 then
      return c[2]
    end
  end
  return nil
end

-- Find build directory
local function find_build_dir()
  local cwd  = vim.fn.getcwd()
  local dirs = { "build", "Build", "cmake-build-debug", ".build", "out" }
  for _, d in ipairs(dirs) do
    if vim.fn.isdirectory(cwd .. "/" .. d) == 1 then
      return cwd .. "/" .. d
    end
  end
  return cwd .. "/build"
end

-- Toggle between header and source
local function toggle_header_source()
  local file = vim.api.nvim_buf_get_name(buf)
  local ext  = file:match("%.([^%.]+)$")

  local companions = {
    h   = { "c", "cpp", "cc", "cxx" },
    hpp = { "cpp", "cc", "cxx" },
    hxx = { "cpp", "cc", "cxx" },
    hh  = { "cc", "cpp" },
    c   = { "h" },
    cpp = { "h", "hpp", "hxx" },
    cc  = { "h", "hh", "hpp" },
    cxx = { "h", "hpp", "hxx" },
  }

  local targets = companions[ext]
  if not targets then
    vim.notify("⚙️  No companion for ." .. ext, vim.log.levels.WARN, { title = "C/C++" })
    return
  end

  local stem = file:match("(.+)%.[^%.]+$")
  for _, t in ipairs(targets) do
    local candidate = stem .. "." .. t
    if vim.fn.filereadable(candidate) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(candidate))
      return
    end
  end

  vim.notify("⚙️  No companion file found for " .. vim.fn.fnamemodify(file, ":t"),
    vim.log.levels.WARN, { title = "C/C++" })
end

-- Smart build
local function smart_build()
  local bs  = detect_build_system()
  local bd  = find_build_dir()

  if bs == "cmake" then
    if vim.fn.isdirectory(bd) == 0 then
      -- Configure first
      run_cmd(
        "cmake -S . -B " .. vim.fn.shellescape(bd)
          .. " -DCMAKE_BUILD_TYPE=Debug"
          .. " -DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
        "CMake configure"
      )
    else
      run_cmd(
        "cmake --build " .. vim.fn.shellescape(bd) .. " --parallel $(nproc)",
        "CMake build"
      )
    end

  elseif bs == "make" then
    run_cmd("make -j$(nproc)", "make")

  elseif bs == "ninja" then
    run_cmd("ninja -C " .. vim.fn.shellescape(bd), "ninja")

  elseif bs == "meson" then
    run_cmd("meson compile -C " .. vim.fn.shellescape(bd), "meson build")

  elseif bs == "xmake" then
    run_cmd("xmake build", "xmake")

  else
    vim.ui.input({ prompt = "⚙️  Build command: " }, function(cmd)
      if cmd and cmd ~= "" then run_cmd(cmd, "custom build") end
    end)
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Header/Source toggle ─────────────────────────────────────────────────────
map("n", "<leader>ch", toggle_header_source, "Toggle header/source")

-- ── Build ─────────────────────────────────────────────────────────────────────
map("n", "<leader>cb", smart_build,           "Smart build")

map("n", "<leader>cB", function()
  -- CMake: rebuild clean
  local bd = find_build_dir()
  run_cmd("cmake --build " .. vim.fn.shellescape(bd) .. " --clean-first --parallel $(nproc)",
    "CMake clean-build")
end, "Clean build")

map("n", "<leader>cg", function()
  -- CMake generate
  local bd = find_build_dir()
  run_cmd(
    "cmake -S . -B " .. vim.fn.shellescape(bd)
      .. " -DCMAKE_BUILD_TYPE=Debug"
      .. " -DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
    "CMake configure"
  )
end, "CMake configure")

map("n", "<leader>cG", function()
  -- CMake: select preset
  local presets_file = vim.fn.getcwd() .. "/CMakePresets.json"
  if vim.fn.filereadable(presets_file) == 0 then
    vim.notify("⚙️  No CMakePresets.json", vim.log.levels.WARN, { title = "C/C++" })
    return
  end
  local f = io.open(presets_file, "r")
  if not f then return end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok then return end

  local presets = vim.tbl_map(function(p) return p.name end,
    data.configurePresets or {})

  vim.ui.select(presets, { prompt = "⚙️  CMake preset: " }, function(preset)
    if preset then
      run_cmd("cmake --preset=" .. preset, "CMake preset: " .. preset)
    end
  end)
end, "CMake preset")

map("n", "<leader>cr", function()
  local bd = find_build_dir()
  -- Find and run the first executable in build dir
  local exes = vim.fn.glob(bd .. "/*", false, true)
  exes = vim.tbl_filter(function(f)
    return vim.fn.getfperm(f):sub(3,3) == "x"
      and vim.fn.isdirectory(f) == 0
  end, exes)

  if #exes == 0 then
    vim.notify("⚙️  No executable in " .. bd, vim.log.levels.WARN, { title = "C/C++" })
    return
  end

  if #exes == 1 then
    run_cmd(exes[1], vim.fn.fnamemodify(exes[1], ":t"))
  else
    local names = vim.tbl_map(function(e) return vim.fn.fnamemodify(e, ":t") end, exes)
    vim.ui.select(names, { prompt = "⚙️  Run: " }, function(_, idx)
      if idx then run_cmd(exes[idx], names[idx]) end
    end)
  end
end, "Run executable")

map("n", "<leader>cc", function()
  -- CMake: clean
  local bd = find_build_dir()
  run_cmd("cmake --build " .. vim.fn.shellescape(bd) .. " --target clean", "CMake clean")
end, "CMake clean")

map("n", "<leader>ct", function()
  -- CTest
  local bd = find_build_dir()
  run_cmd("ctest --test-dir " .. vim.fn.shellescape(bd) .. " --output-on-failure -j$(nproc)",
    "CTest")
end, "Run CTest")

-- ── Analysis ──────────────────────────────────────────────────────────────────
map("n", "<leader>cv", function()
  local file = vim.api.nvim_buf_get_name(buf)
  if vim.fn.executable("cppcheck") == 1 then
    run_cmd(
      "cppcheck --enable=all --suppress=missingIncludeSystem "
        .. "--language=" .. (ft == "c" and "c" or "c++")
        .. " " .. vim.fn.shellescape(file),
      "cppcheck"
    )
  else
    vim.notify("⚙️  cppcheck not found", vim.log.levels.WARN, { title = "C/C++" })
  end
end, "cppcheck")

map("n", "<leader>ca", function()
  local file = vim.api.nvim_buf_get_name(buf)
  if vim.fn.executable("clang-tidy") == 1 then
    run_cmd("clang-tidy " .. vim.fn.shellescape(file) .. " -- ", "clang-tidy")
  else
    vim.notify("⚙️  clang-tidy not found", vim.log.levels.WARN, { title = "C/C++" })
  end
end, "clang-tidy")

-- ── Sanitizers ────────────────────────────────────────────────────────────────
map("n", "<leader>csa", function()
  vim.ui.select(
    { "AddressSanitizer", "UndefinedBehaviorSanitizer", "ThreadSanitizer", "MemorySanitizer" },
    { prompt = "⚙️  Sanitizer: " },
    function(san)
      if not san then return end
      local flag_map = {
        AddressSanitizer          = "-fsanitize=address",
        UndefinedBehaviorSanitizer= "-fsanitize=undefined",
        ThreadSanitizer           = "-fsanitize=thread",
        MemorySanitizer           = "-fsanitize=memory",
      }
      local bd = find_build_dir()
      run_cmd(
        "cmake -S . -B " .. vim.fn.shellescape(bd)
          .. " -DCMAKE_CXX_FLAGS='" .. flag_map[san] .. "'"
          .. " -DCMAKE_BUILD_TYPE=Debug && cmake --build "
          .. vim.fn.shellescape(bd),
        san
      )
    end
  )
end, "Build with sanitizer")

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>cf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
  end
end, "Format (clang-format)")

-- ── compile_commands.json ─────────────────────────────────────────────────────
map("n", "<leader>cco", function()
  local cwd  = vim.fn.getcwd()
  local bd   = find_build_dir()
  local src  = bd .. "/compile_commands.json"
  local link = cwd .. "/compile_commands.json"

  if vim.fn.filereadable(src) == 1 then
    if vim.fn.filereadable(link) == 0 then
      vim.fn.system("ln -sf " .. vim.fn.shellescape(src) .. " " .. vim.fn.shellescape(link))
      vim.notify("⚙️  Linked compile_commands.json", vim.log.levels.INFO, { title = "C/C++" })
    else
      vim.cmd("edit " .. link)
    end
  else
    vim.notify("⚙️  No compile_commands.json in " .. bd, vim.log.levels.WARN,
      { title = "C/C++" })
  end
end, "Link compile_commands.json")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>ci", function()
  local bs   = detect_build_system() or "unknown"
  local bd   = find_build_dir()
  local cc   = vim.fn.trim(vim.fn.system("cc --version 2>/dev/null | head -1"))
  local cxx  = vim.fn.trim(vim.fn.system("c++ --version 2>/dev/null | head -1"))
  local cmake= vim.fn.trim(vim.fn.system("cmake --version 2>/dev/null | head -1"))

  vim.notify(
    table.concat({
      "⚙️  C/C++ Environment",
      "──────────────────────────────────",
      string.format("  Filetype:  %s", ft),
      string.format("  Build sys: %s", bs),
      string.format("  Build dir: %s", vim.fn.fnamemodify(bd, ":~")),
      string.format("  CC:        %s", cc),
      string.format("  CXX:       %s", cxx),
      string.format("  cmake:     %s", cmake),
      string.format("  clangd:    %s", vim.fn.executable("clangd") == 1 and "✅" or "⭕"),
      string.format("  cppcheck:  %s", vim.fn.executable("cppcheck") == 1 and "✅" or "⭕"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "C/C++" }
  )
end, "Environment info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtCpp_" .. buf, { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group  = aug,
  buffer = buf,
  callback = function()
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
    end
  end,
})

-- Auto-symlink compile_commands on first open
vim.api.nvim_create_autocmd("BufWinEnter", {
  group  = aug,
  buffer = buf,
  once   = true,
  callback = function()
    local cwd  = vim.fn.getcwd()
    local bd   = find_build_dir()
    local src  = bd .. "/compile_commands.json"
    local link = cwd .. "/compile_commands.json"
    if vim.fn.filereadable(src) == 1 and vim.fn.filereadable(link) == 0 then
      vim.fn.system("ln -sf " .. vim.fn.shellescape(src) .. " " .. vim.fn.shellescape(link))
    end
  end,
})