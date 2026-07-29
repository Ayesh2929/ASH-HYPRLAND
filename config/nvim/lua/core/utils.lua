-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/core/utils.lua — Global Utility Library                                 ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Exposed as:  Ash.util.*   (merged into global at bottom)                   ║
-- ║  Also usable: local U = require("core.utils")                               ║
-- ║                                                                              ║
-- ║  Namespaces:                                                                 ║
-- ║    U.fn      — function / callable helpers                                   ║
-- ║    U.tbl     — table helpers                                                 ║
-- ║    U.str     — string helpers                                                ║
-- ║    U.path    — path / filesystem helpers                                     ║
-- ║    U.buf     — buffer helpers                                                ║
-- ║    U.win     — window helpers                                                ║
-- ║    U.lsp     — LSP helpers                                                   ║
-- ║    U.color   — colour manipulation                                           ║
-- ║    U.notify  — structured notifications                                      ║
-- ║    U.keymap  — keymap helpers                                                ║
-- ║    U.async   — lightweight async (vim.schedule wrappers)                    ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

local api  = vim.api
local fn   = vim.fn
local uv   = vim.uv

---@class AshUtils
local U = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 01  FUNCTION HELPERS  (U.fn)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

U.fn = {}

---Execute `f` at most once and cache the result.
---@generic T
---@param f fun(): T
---@return fun(): T
function U.fn.once(f)
  local done, result = false, nil
  return function()
    if not done then
      result = f()
      done   = true
    end
    return result
  end
end

---Return a debounced version of `f` that delays execution by `ms` milliseconds.
---Resets the timer on every call within the window.
---@param f   fun(...)
---@param ms  integer  Delay in milliseconds
---@return fun(...)
function U.fn.debounce(f, ms)
  local timer = uv.new_timer()
  return function(...)
    local args = { ... }
    timer:stop()
    timer:start(ms, 0, vim.schedule_wrap(function()
      f(unpack(args))
    end))
  end
end

---Return a throttled version of `f` that runs at most once per `ms` ms.
---@param f   fun(...)
---@param ms  integer
---@return fun(...)
function U.fn.throttle(f, ms)
  local last  = 0
  local timer = uv.new_timer()
  return function(...)
    local now  = uv.hrtime() / 1e6
    local args = { ... }
    if now - last >= ms then
      last = now
      f(unpack(args))
    else
      timer:stop()
      timer:start(ms - (now - last), 0, vim.schedule_wrap(function()
        last = uv.hrtime() / 1e6
        f(unpack(args))
      end))
    end
  end
end

---Safely call `f` with `...`, returning `ok, result`.
---@param f   fun(...): any
---@return boolean ok
---@return any     result_or_err
function U.fn.try(f, ...)
  return pcall(f, ...)
end

---Return `val` if truthy, otherwise `default`.
---@generic T
---@param val     T?
---@param default T
---@return T
function U.fn.default(val, default)
  if val == nil or val == false then return default end
  return val
end

---Memoize a pure function. Cache is keyed by first argument (string/number).
---@generic T
---@param f  fun(key: string|number): T
---@return   fun(key: string|number): T
function U.fn.memoize(f)
  local cache = {}
  return function(key)
    if cache[key] == nil then
      cache[key] = f(key)
    end
    return cache[key]
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 02  TABLE HELPERS  (U.tbl)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

U.tbl = {}

---Deep-merge any number of tables left-to-right. Later tables win.
---@param ...table
---@return table
function U.tbl.merge(...)
  local result = {}
  for _, t in ipairs({ ... }) do
    result = vim.tbl_deep_extend("force", result, t)
  end
  return result
end

---Return a shallow copy of `t` with only the keys in `keys`.
---@param t    table
---@param keys string[]
---@return     table
function U.tbl.pick(t, keys)
  local out = {}
  for _, k in ipairs(keys) do
    out[k] = t[k]
  end
  return out
end

---Return a shallow copy of `t` without the keys in `keys`.
---@param t    table
---@param keys string[]
---@return     table
function U.tbl.omit(t, keys)
  local exclude = {}
  for _, k in ipairs(keys) do exclude[k] = true end
  local out = {}
  for k, v in pairs(t) do
    if not exclude[k] then out[k] = v end
  end
  return out
end

---Flatten a nested list up to `depth` levels (default 1).
---@param t     any[]
---@param depth integer?
---@return      any[]
function U.tbl.flatten(t, depth)
  depth = depth or 1
  local out = {}
  local function _flat(arr, d)
    for _, v in ipairs(arr) do
      if type(v) == "table" and d > 0 then
        _flat(v, d - 1)
      else
        out[#out + 1] = v
      end
    end
  end
  _flat(t, depth)
  return out
end

---Map `f` over list `t`, returning a new list.
---@generic T, R
---@param t  T[]
---@param f  fun(v: T, i: integer): R
---@return   R[]
function U.tbl.map(t, f)
  local out = {}
  for i, v in ipairs(t) do
    out[i] = f(v, i)
  end
  return out
end

---Filter list `t` by predicate `f`.
---@generic T
---@param t  T[]
---@param f  fun(v: T, i: integer): boolean
---@return   T[]
function U.tbl.filter(t, f)
  local out = {}
  for i, v in ipairs(t) do
    if f(v, i) then out[#out + 1] = v end
  end
  return out
end

---Reduce list `t` with accumulator starting at `init`.
---@generic T, R
---@param t    T[]
---@param f    fun(acc: R, v: T, i: integer): R
---@param init R
---@return     R
function U.tbl.reduce(t, f, init)
  local acc = init
  for i, v in ipairs(t) do
    acc = f(acc, v, i)
  end
  return acc
end

---Return true if `val` is in list `t`.
---@param t   any[]
---@param val any
---@return    boolean
function U.tbl.contains(t, val)
  for _, v in ipairs(t) do
    if v == val then return true end
  end
  return false
end

---Return unique values from list `t` (order preserved).
---@generic T
---@param t T[]
---@return  T[]
function U.tbl.unique(t)
  local seen, out = {}, {}
  for _, v in ipairs(t) do
    local key = tostring(v)
    if not seen[key] then
      seen[key] = true
      out[#out + 1] = v
    end
  end
  return out
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 03  STRING HELPERS  (U.str)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

U.str = {}

---Trim leading and trailing whitespace.
---@param s string
---@return  string
function U.str.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---Split `s` by delimiter `sep` (plain, not pattern).
---@param s   string
---@param sep string
---@return    string[]
function U.str.split(s, sep)
  local out, i = {}, 1
  local plain = true
  while true do
    local j, k = s:find(sep, i, plain)
    if not j then
      out[#out + 1] = s:sub(i)
      break
    end
    out[#out + 1] = s:sub(i, j - 1)
    i = k + 1
  end
  return out
end

---Pad `s` to `width` characters, aligning left (default) or right.
---@param s      string
---@param width  integer
---@param align  "left"|"right"|"center"?
---@param char   string?  Fill character (default " ")
---@return       string
function U.str.pad(s, width, align, char)
  char  = char or " "
  align = align or "left"
  local len  = #s
  local pad  = math.max(0, width - len)
  if align == "right" then
    return char:rep(pad) .. s
  elseif align == "center" then
    local lpad = math.floor(pad / 2)
    local rpad = pad - lpad
    return char:rep(lpad) .. s .. char:rep(rpad)
  else
    return s .. char:rep(pad)
  end
end

---Truncate `s` to `max` characters with optional `ellipsis` suffix.
---@param s        string
---@param max      integer
---@param ellipsis string?
---@return         string
function U.str.truncate(s, max, ellipsis)
  ellipsis = ellipsis or "…"
  if #s <= max then return s end
  return s:sub(1, max - #ellipsis) .. ellipsis
end

---Convert snake_case / kebab-case to Title Case.
---@param s string
---@return  string
function U.str.title(s)
  return (s:gsub("[%-%_]", " "):gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end))
end

---Return true when `s` starts with `prefix`.
---@param s      string
---@param prefix string
---@return       boolean
function U.str.starts_with(s, prefix)
  return s:sub(1, #prefix) == prefix
end

---Return true when `s` ends with `suffix`.
---@param s      string
---@param suffix string
---@return       boolean
function U.str.ends_with(s, suffix)
  return suffix == "" or s:sub(-#suffix) == suffix
end

---Escape a string for use as a Vim pattern.
---@param s string
---@return  string
function U.str.escape_pattern(s)
  return (s:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1"))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 04  PATH / FILESYSTEM HELPERS  (U.path)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

U.path = {}

---Return true when `path` exists on disk.
---@param path string
---@return     boolean
function U.path.exists(path)
  return uv.fs_stat(path) ~= nil
end

---Return true when `path` is a directory.
---@param path string
---@return     boolean
function U.path.is_dir(path)
  local stat = uv.fs_stat(path)
  return stat ~= nil and stat.type == "directory"
end

---Return true when `path` is a regular file.
---@param path string
---@return     boolean
function U.path.is_file(path)
  local stat = uv.fs_stat(path)
  return stat ~= nil and stat.type == "file"
end

---Join path segments with the OS separator.
---@param ...string
---@return string
function U.path.join(...)
  return table.concat({ ... }, "/"):gsub("//+", "/")
end

---Return the directory component of a path.
---@param path string
---@return     string
function U.path.dirname(path)
  return fn.fnamemodify(path, ":h")
end

---Return the basename (filename) of a path.
---@param path    string
---@param ext     boolean?  Strip extension when true
---@return        string
function U.path.basename(path, ext)
  if ext then
    return fn.fnamemodify(path, ":t:r")
  end
  return fn.fnamemodify(path, ":t")
end

---Return path relative to `base`, or the path itself if not under base.
---@param path string
---@param base string?
---@return     string
function U.path.relative(path, base)
  base = base or fn.getcwd()
  local rel = fn.fnamemodify(path, ":~:.")
  return rel
end

---Read the entire content of `path`, or nil on error.
---@param path string
---@return     string?
function U.path.read(path)
  local fd, err = uv.fs_open(path, "r", 438)
  if not fd then return nil end
  local stat = uv.fs_fstat(fd)
  if not stat then uv.fs_close(fd); return nil end
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return data
end

---Write `content` to `path`, creating parent dirs as needed.
---@param path    string
---@param content string
---@return        boolean  ok
function U.path.write(path, content)
  local dir = U.path.dirname(path)
  if not U.path.exists(dir) then
    fn.mkdir(dir, "p")
  end
  local fd = uv.fs_open(path, "w", 438)
  if not fd then return false end
  uv.fs_write(fd, content, 0)
  uv.fs_close(fd)
  return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 05  BUFFER HELPERS  (U.buf)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

U.buf = {}

---Return true when buffer `b` is valid and loaded.
---@param b integer
---@return  boolean
function U.buf.valid(b)
  return b ~= nil and api.nvim_buf_is_valid(b) and api.nvim_buf_is_loaded(b)
end

---Return the full path of buffer `b` (or current buffer).
---@param b integer?
---@return  string
function U.buf.path(b)
  return api.nvim_buf_get_name(b or 0)
end

---Return filetype of buffer `b` (or current buffer).
---@param b integer?
---@return  string
function U.buf.ft(b)
  return vim.bo[b or 0].filetype
end

---Return true when buffer `b` is a "real" editable buffer.
---@param b integer?
---@return  boolean
function U.buf.is_real(b)
  b = b or 0
  return api.nvim_buf_is_valid(b)
    and vim.bo[b].buflisted
    and vim.bo[b].buftype == ""
end

---Return all listed, real buffer handles.
---@return integer[]
function U.buf.list()
  return vim.tbl_filter(function(b)
    return U.buf.is_real(b)
  end, api.nvim_list_bufs())
end

---Get all lines of buffer `b` as a string.
---@param b integer?
---@return  string
function U.buf.content(b)
  local lines = api.nvim_buf_get_lines(b or 0, 0, -1, false)
  return table.concat(lines, "\n")
end

---Return true when buffer is too large for heavy features.
---@param b integer?
---@return  boolean
function U.buf.is_large(b)
  return vim.b[b or 0].large_file == true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 06  WINDOW HELPERS  (U.win)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

U.win = {}

---Return true when window `w` is a floating window.
---@param w integer?
---@return  boolean
function U.win.is_floating(w)
  local cfg = api.nvim_win_get_config(w or 0)
  return cfg.relative ~= ""
end

---Close all floating windows in the current tabpage.
function U.win.close_floats()
  for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
    if U.win.is_floating(w) then
      pcall(api.nvim_win_close, w, false)
    end
  end
end

---Return the dimensions of the editor viewport.
---@return { width: integer, height: integer }
function U.win.viewport()
  return {
    width  = vim.o.columns,
    height = vim.o.lines - vim.o.cmdheight - 1,
  }
end

---Centre a floating window's position given its width/height.
---@param w integer
---@param h integer
---@return  { row: integer, col: integer }
function U.win.center_pos(w, h)
  local vp = U.win.viewport()
  return {
    row = math.floor((vp.height - h) / 2),
    col = math.floor((vp.width  - w) / 2),
  }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 07  LSP HELPERS  (U.lsp)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

U.lsp = {}

---Return all active LSP clients for buffer `b`.
---@param b integer?
---@return  vim.lsp.Client[]
function U.lsp.clients(b)
  return vim.lsp.get_clients({ bufnr = b or 0 })
end

---Return true when at least one LSP client is attached to buffer `b`.
---@param b integer?
---@return  boolean
function U.lsp.active(b)
  return #U.lsp.clients(b) > 0
end

---Return a comma-separated string of active LSP client names.
---@param b integer?
---@return  string
function U.lsp.names(b)
  local names = vim.tbl_map(function(c) return c.name end, U.lsp.clients(b))
  return table.concat(names, ", ")
end

---Return true when client named `name` supports `method`.
---@param client vim.lsp.Client
---@param method string
---@return       boolean
function U.lsp.supports(client, method)
  return client.supports_method(method)
end

---Execute a code action, optionally filtering by context kind.
---@param opts table?
function U.lsp.code_action(opts)
  vim.lsp.buf.code_action(opts)
end

---Format the current buffer using the best available formatter.
---Prefer conform.nvim when available, fall back to vim.lsp.buf.format.
---@param opts table?
function U.lsp.format(opts)
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format(U.tbl.merge({
      timeout_ms = 3000,
      async      = false,
      quiet      = true,
    }, opts or {}))
  else
    vim.lsp.buf.format(opts)
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 08  COLOUR HELPERS  (U.color)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

U.color = {}

---Parse a `#RRGGBB` hex string into { r, g, b } (0–255).
---@param hex string
---@return    { r: integer, g: integer, b: integer }?
function U.color.hex_to_rgb(hex)
  hex = hex:gsub("^#", "")
  if #hex ~= 6 then return nil end
  return {
    r = tonumber(hex:sub(1, 2), 16),
    g = tonumber(hex:sub(3, 4), 16),
    b = tonumber(hex:sub(5, 6), 16),
  }
end

---Convert { r, g, b } (0–255) to `#RRGGBB`.
---@param r integer
---@param g integer
---@param b integer
---@return  string
function U.color.rgb_to_hex(r, g, b)
  return string.format("#%02x%02x%02x", r, g, b)
end

---Blend two hex colours by `alpha` (0 = full `a`, 1 = full `b`).
---@param a     string   Hex colour A
---@param b     string   Hex colour B
---@param alpha number   0.0 – 1.0
---@return      string   Blended hex colour
function U.color.blend(a, b, alpha)
  local ca = U.color.hex_to_rgb(a)
  local cb = U.color.hex_to_rgb(b)
  if not ca or not cb then return a end
  local function lerp(x, y) return math.floor(x + (y - x) * alpha) end
  return U.color.rgb_to_hex(
    lerp(ca.r, cb.r),
    lerp(ca.g, cb.g),
    lerp(ca.b, cb.b)
  )
end

---Lighten a hex colour by `pct` percent (0–100).
---@param hex string
---@param pct number
---@return    string
function U.color.lighten(hex, pct)
  return U.color.blend(hex, "#ffffff", pct / 100)
end

---Darken a hex colour by `pct` percent (0–100).
---@param hex string
---@param pct number
---@return    string
function U.color.darken(hex, pct)
  return U.color.blend(hex, "#000000", pct / 100)
end

---Return the perceived luminance of a hex colour (0 = black, 1 = white).
---@param hex string
---@return    number
function U.color.luminance(hex)
  local c = U.color.hex_to_rgb(hex)
  if not c then return 0 end
  local function lin(v)
    v = v / 255
    return v <= 0.04045 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
  end
  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
end

---Return `"dark"` or `"light"` based on perceived luminance.
---@param hex string
---@return    "dark"|"light"
function U.color.tone(hex)
  return U.color.luminance(hex) < 0.5 and "dark" or "light"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 09  NOTIFICATION HELPERS  (U.notify)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

U.notify = {}

local _levels = {
  trace = vim.log.levels.TRACE,
  debug = vim.log.levels.DEBUG,
  info  = vim.log.levels.INFO,
  warn  = vim.log.levels.WARN,
  error = vim.log.levels.ERROR,
}

for name, level in pairs(_levels) do
  ---@param msg     string
  ---@param opts    table?
  U.notify[name] = function(msg, opts)
    vim.notify(
      msg,
      level,
      vim.tbl_extend("keep", opts or {}, { title = "ASH NeoVim" })
    )
  end
end

---Show a one-line progress notification that auto-dismisses.
---@param msg     string
---@param timeout integer?  ms (default 2000)
function U.notify.progress(msg, timeout)
  vim.notify(msg, vim.log.levels.INFO, {
    title   = "ASH NeoVim",
    timeout = timeout or 2000,
    icon    = Ash and Ash.icons.misc.spinner_dots[1] or "⏳",
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 10  KEYMAP HELPERS  (U.keymap)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

U.keymap = {}

---Set a keymap with sensible defaults. Wraps vim.keymap.set.
---@param mode  string|string[]
---@param lhs   string
---@param rhs   string|function
---@param opts  table?
function U.keymap.set(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", {
    silent  = true,
    noremap = true,
  }, opts or {}))
end

---Delete a keymap, suppressing errors if it doesn't exist.
---@param mode string|string[]
---@param lhs  string
---@param opts table?
function U.keymap.del(mode, lhs, opts)
  pcall(vim.keymap.del, mode, lhs, opts)
end

---Return true when `lhs` has a mapping in `mode` for buffer `b`.
---@param mode string
---@param lhs  string
---@param b    integer?
---@return     boolean
function U.keymap.has(mode, lhs, b)
  local maps = b
    and api.nvim_buf_get_keymap(b, mode)
    or  api.nvim_get_keymap(mode)
  for _, m in ipairs(maps) do
    if m.lhs == lhs then return true end
  end
  return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 11  ASYNC HELPERS  (U.async)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

U.async = {}

---Schedule `f` to run on the next event-loop tick.
---@param f fun()
function U.async.defer(f)
  vim.schedule(f)
end

---Run `f` after `ms` milliseconds (single-shot timer).
---@param f  fun()
---@param ms integer
function U.async.later(f, ms)
  vim.defer_fn(f, ms)
end

---Run `f` every `ms` milliseconds. Returns the timer handle (call :stop() to cancel).
---@param f  fun()
---@param ms integer
---@return   uv_timer_t
function U.async.interval(f, ms)
  local timer = uv.new_timer()
  timer:start(ms, ms, vim.schedule_wrap(f))
  return timer
end

---Run an async job, calling `on_done(ok, output)` when finished.
---@param cmd     string[]
---@param on_done fun(ok: boolean, output: string)
function U.async.job(cmd, on_done)
  local output = {}
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then output[#output + 1] = line end
      end
    end,
    on_exit = function(_, code)
      on_done(code == 0, table.concat(output, "\n"))
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 12  MERGE INTO GLOBAL ASH NAMESPACE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if Ash then
  Ash.util = U
end

return U