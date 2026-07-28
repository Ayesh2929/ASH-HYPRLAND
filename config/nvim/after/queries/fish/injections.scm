; ╔══════════════════════════════════════════════════════════════════════════════════╗
; ║       🐠 FISH SHELL — TREESITTER INJECTIONS v5.0 OMEGA                         ║
; ║   Shell command injection · regex · heredoc · eval content · string templates  ║
; ║   eval · source · command substitution · math expressions · printf format      ║
; ╚══════════════════════════════════════════════════════════════════════════════════╝

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📝 COMMENT INJECTION — special markers inside comments
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; TODO / FIXME / NOTE comments
((comment) @injection.content
  (#set! injection.language "comment"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; ⚡ COMMAND SUBSTITUTION INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Command substitution $(...) — inject as fish
(command_substitution) @injection.content
  (#set! injection.language "fish")

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔄 EVAL INJECTION — eval "fish code"
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; eval with double-quoted string argument
(command
  name: (word) @_eval
  (#eq? @_eval "eval")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "fish"))

; eval with single-quoted string argument
(command
  name: (word) @_eval_sq
  (#eq? @_eval_sq "eval")
  argument: (single_quote_string) @injection.content
  (#set! injection.language "fish"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📂 SOURCE INJECTION — source file.fish
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; source command argument (file path) — treated as bash path
(command
  name: (word) @_source
  (#eq? @_source "source")
  argument: (_) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🧮 MATH INJECTION — math "expression"
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; math command double-quoted expression
(command
  name: (word) @_math
  (#eq? @_math "math")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "bash"))

; math command single-quoted expression
(command
  name: (word) @_math_sq
  (#eq? @_math_sq "math")
  argument: (single_quote_string) @injection.content
  (#set! injection.language "bash"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔤 STRING REGEX INJECTION — string match/replace -r patterns
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; string match -r "regex"
(command
  name: (word) @_string_match
  (#eq? @_string_match "string")
  argument: (word) @_match_sub
  (#any-of? @_match_sub "match" "replace")
  argument: (word) @_regex_flag
  (#any-of? @_regex_flag "-r" "--regex")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "regex"))

; string match -r 'regex' (single-quoted)
(command
  name: (word) @_string_match_sq
  (#eq? @_string_match_sq "string")
  argument: (word) @_match_sub_sq
  (#any-of? @_match_sub_sq "match" "replace")
  argument: (word) @_regex_flag_sq
  (#any-of? @_regex_flag_sq "-r" "--regex")
  argument: (single_quote_string) @injection.content
  (#set! injection.language "regex"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📊 PRINTF FORMAT INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; printf format string — first argument
(command
  name: (word) @_printf
  (#eq? @_printf "printf")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "bash"))

; printf format string — single-quoted
(command
  name: (word) @_printf_sq
  (#eq? @_printf_sq "printf")
  argument: (single_quote_string) @injection.content
  (#set! injection.language "bash"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🐍 PYTHON INJECTION — python -c "..."
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; python -c "code"
(command
  name: (word) @_python
  (#any-of? @_python "python" "python3" "python2")
  argument: (word) @_c_flag
  (#eq? @_c_flag "-c")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "python"))

; python -c 'code' (single-quoted)
(command
  name: (word) @_python_sq
  (#any-of? @_python_sq "python" "python3" "python2")
  argument: (word) @_c_flag_sq
  (#eq? @_c_flag_sq "-c")
  argument: (single_quote_string) @injection.content
  (#set! injection.language "python"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🌙 LUA INJECTION — lua -e "..."
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; lua -e "code"
(command
  name: (word) @_lua
  (#any-of? @_lua "lua" "luajit" "lua5.1" "lua5.2" "lua5.3" "lua5.4")
  argument: (word) @_e_flag
  (#eq? @_e_flag "-e")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "lua"))

; lua -e 'code' (single-quoted)
(command
  name: (word) @_lua_sq
  (#any-of? @_lua_sq "lua" "luajit" "lua5.1" "lua5.2" "lua5.3" "lua5.4")
  argument: (word) @_e_flag_sq
  (#eq? @_e_flag_sq "-e")
  argument: (single_quote_string) @injection.content
  (#set! injection.language "lua"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🐚 BASH INJECTION — bash -c "..."
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; bash -c "shell code"
(command
  name: (word) @_bash
  (#any-of? @_bash "bash" "sh" "zsh" "dash")
  argument: (word) @_c_flag_bash
  (#eq? @_c_flag_bash "-c")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "bash"))

; bash -c 'shell code' (single-quoted)
(command
  name: (word) @_bash_sq
  (#any-of? @_bash_sq "bash" "sh" "zsh" "dash")
  argument: (word) @_c_flag_bash_sq
  (#eq? @_c_flag_bash_sq "-c")
  argument: (single_quote_string) @injection.content
  (#set! injection.language "bash"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📋 JQ INJECTION — jq filter expressions
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; jq 'filter'
(command
  name: (word) @_jq
  (#eq? @_jq "jq")
  argument: (single_quote_string) @injection.content
  (#set! injection.language "jq"))

; jq "filter"
(command
  name: (word) @_jq_dq
  (#eq? @_jq_dq "jq")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "jq"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔍 SED INJECTION — sed patterns
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; sed 's/pattern/replace/'
(command
  name: (word) @_sed
  (#any-of? @_sed "sed" "gsed")
  argument: (single_quote_string) @injection.content
  (#set! injection.language "regex"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔎 AWK INJECTION — awk programs
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; awk '{program}'
(command
  name: (word) @_awk
  (#any-of? @_awk "awk" "gawk" "mawk" "nawk")
  argument: (single_quote_string) @injection.content
  (#set! injection.language "awk"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🐘 PSQL / SQL INJECTION — database CLI commands
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; psql -c "SQL query"
(command
  name: (word) @_psql
  (#any-of? @_psql "psql" "mysql" "sqlite3")
  argument: (word) @_c_flag_sql
  (#eq? @_c_flag_sql "-c")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "sql"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🌐 CURL / HTTP INJECTION — JSON data arguments
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; curl -d '{"json": "data"}'
(command
  name: (word) @_curl
  (#any-of? @_curl "curl" "wget" "http" "httpie")
  argument: (word) @_d_flag
  (#any-of? @_d_flag "-d" "--data" "--data-raw" "--data-binary")
  argument: (single_quote_string) @injection.content
  (#match? @injection.content "^\\{")
  (#set! injection.language "json"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📌 COMPLETE CONDITIONS — -n "--condition" argument
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; complete -n "condition" — inject as fish
(command
  name: (word) @_complete_n
  (#eq? @_complete_n "complete")
  argument: (word) @_n_flag
  (#any-of? @_n_flag "-n" "--condition")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "fish"))

; complete -n 'condition' — single-quoted
(command
  name: (word) @_complete_n_sq
  (#eq? @_complete_n_sq "complete")
  argument: (word) @_n_flag_sq
  (#any-of? @_n_flag_sq "-n" "--condition")
  argument: (single_quote_string) @injection.content
  (#set! injection.language "fish"))

; complete -a "completions" — arguments list (fish code)
(command
  name: (word) @_complete_a
  (#eq? @_complete_a "complete")
  argument: (word) @_a_flag
  (#any-of? @_a_flag "-a" "--arguments")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "fish"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔔 ABBR FUNCTION INJECTION — abbr --function name
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; abbr --function "fish_function"
(command
  name: (word) @_abbr_fn
  (#eq? @_abbr_fn "abbr")
  argument: (word) @_fn_flag
  (#any-of? @_fn_flag "--function")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "fish"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎨 ASH CLI INJECTION — ash command arguments
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; ash theme apply "theme-name" — theme names as strings
(command
  name: (word) @_ash
  (#eq? @_ash "ash")
  argument: (word) @_theme_sub
  (#eq? @_theme_sub "theme")
  argument: (word) @_apply_sub
  (#eq? @_apply_sub "apply")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "bash"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔧 HYPRCTL DISPATCH INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; hyprctl dispatch exec "shell command"
(command
  name: (word) @_hyprctl
  (#eq? @_hyprctl "hyprctl")
  argument: (word) @_dispatch
  (#eq? @_dispatch "dispatch")
  argument: (word) @_exec_dispatch
  (#eq? @_exec_dispatch "exec")
  argument: (double_quote_string) @injection.content
  (#set! injection.language "bash"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔄 GENERAL VARIABLE EXPANSION IN DOUBLE QUOTES
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Variable expansion inside double-quoted strings — inject as fish fragment
(double_quote_string
  (variable_expansion) @injection.content
  (#set! injection.language "fish")
  (#set! injection.include-unnamed true))

; Command substitution inside double-quoted strings
(double_quote_string
  (command_substitution) @injection.content
  (#set! injection.language "fish"))